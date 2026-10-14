///|
fn forest_query_budget(
  work_limit : Int,
) -> Result[ForestAnalysisBudget, Problem] {
  if work_limit <= 0 {
    Err(InvalidLimit("work_limit"))
  } else {
    Ok({ name: "query_work", limit: work_limit, used: 0, })
  }
}

///|
/// One queue implementation supports both structural and viable reachability.
/// Token leaves are terminal even if a malformed internal fixture adds families.
fn forest_query_walk(
  forest : Forest,
  root : Int?,
  productive : Array[Bool]?,
  budget : ForestAnalysisBudget,
) -> Array[Int] raise ForestAnalysisHalt {
  let root = match root {
    None => return []
    Some(id) => id
  }
  forest_analysis_check_id(forest, root)
  match productive {
    Some(flags) => if !flags[root] { return [] }
    None => ()
  }
  let seen = Array::make(forest.nodes.length(), false)
  let queue = [root]
  seen[root] = true
  let mut cursor = 0
  while cursor < queue.length() {
    budget.tick()
    let id = queue[cursor]
    cursor += 1
    match forest.nodes[id].kind {
      TokenLeaf(_) => ()
      _ =>
        for family in forest.nodes[id].families {
          let viable = match productive {
            None => {
              budget.tick()
              true
            }
            Some(flags) =>
              forest_analysis_family_productive(forest, family, flags, budget)
          }
          if viable {
            for child in family.children {
              budget.tick()
              forest_analysis_check_id(forest, child)
              if !seen[child] {
                seen[child] = true
                queue.push(child)
              }
            }
          }
        }
    }
  }
  queue.sort()
  queue
}

///|
/// All matching IDs in allocation order; namespaces remain distinct.
pub fn Forest::nodes_of_kind(self : Forest, kind : NodeKind) -> Array[Int] {
  let ids : Array[Int] = []
  for id, node in self.nodes {
    if node.kind == kind {
      ids.push(id)
    }
  }
  ids
}

///|
/// Search every stored symbol node, including disconnected chart material.
pub fn Forest::symbol_nodes(self : Forest, name : String) -> Array[Int] {
  self.nodes_of_kind(SymbolNode(name))
}

///|
fn forest_query_span(
  forest : Forest,
  start : Int,
  end : Int,
) -> Result[Unit, Problem] {
  if start < 0 || end < start || end > forest.tokens.length() {
    Err(Syntax(start, "invalid token-index span"))
  } else {
    Ok(())
  }
}

///|
/// Exact half-open token interval, not the tokens' caller-defined source offsets.
/// Zero-width intervals are valid, including at the end of input.
pub fn Forest::nodes_at_span(
  self : Forest,
  start : Int,
  end : Int,
) -> Result[Array[Int], Problem] {
  match forest_query_span(self, start, end) {
    Err(problem) => return Err(problem)
    Ok(_) => ()
  }
  let ids : Array[Int] = []
  for id, node in self.nodes {
    if node.start == start && node.end == end {
      ids.push(id)
    }
  }
  Ok(ids)
}

///|
pub fn Forest::symbol_nodes_at(
  self : Forest,
  name : String,
  start : Int,
  end : Int,
) -> Result[Array[Int], Problem] {
  match self.nodes_at_span(start, end) {
    Err(problem) => Err(problem)
    Ok(ids) =>
      Ok(ids.filter(fn(id) { self.nodes[id].kind == SymbolNode(name) }))
  }
}

///|
/// Follow all stored families from the accepted root, cycle-safely.
/// A rejected forest has no root and therefore no root-reachable IDs.
pub fn Forest::reachable_nodes(
  self : Forest,
  work_limit? : Int = 1000000,
) -> Result[Array[Int], Problem] {
  self.query_reachable(self.root, work_limit)
}

///|
/// Useful for chart fragments and rejected reports that have no accepted root.
pub fn Forest::reachable_from(
  self : Forest,
  id : Int,
  work_limit? : Int = 1000000,
) -> Result[Array[Int], Problem] {
  self.query_reachable(Some(id), work_limit)
}

///|
fn Forest::query_reachable(
  self : Forest,
  root : Int?,
  work_limit : Int,
) -> Result[Array[Int], Problem] {
  let budget = match forest_query_budget(work_limit) {
    Err(problem) => return Err(problem)
    Ok(budget) => budget
  }
  Ok(forest_query_walk(self, root, None, budget)) catch {
    ForestAnalysisHalt(problem) => Err(problem)
  }
}

///|
/// Finite-proof productivity over every node, independent of root reachability.
pub fn Forest::productive_nodes(
  self : Forest,
  work_limit? : Int = 1000000,
) -> Result[Array[Int], Problem] {
  let budget = match forest_query_budget(work_limit) {
    Err(problem) => return Err(problem)
    Ok(budget) => budget
  }
  try {
    let productive = forest_analysis_productive(self, budget)
    let ids : Array[Int] = []
    for id, flag in productive {
      budget.tick()
      if flag {
        ids.push(id)
      }
    }
    Ok(ids)
  } catch {
    ForestAnalysisHalt(problem) => Err(problem)
  }
}

///|
/// Local ambiguity means at least two productive packed families at a node.
/// Parents with only one family are not listed merely because a child is
/// ambiguous. By default consider only viable root-reachable nodes; false
/// includes disconnected productive nodes. Token leaves are never ambiguous.
pub fn Forest::ambiguity_nodes(
  self : Forest,
  reachable_only? : Bool = true,
  work_limit? : Int = 1000000,
) -> Result[Array[Int], Problem] {
  let budget = match forest_query_budget(work_limit) {
    Err(problem) => return Err(problem)
    Ok(budget) => budget
  }
  try {
    let productive = forest_analysis_productive(self, budget)
    let candidates = if reachable_only {
      forest_query_walk(self, self.root, Some(productive), budget)
    } else {
      Array::makei(self.nodes.length(), fn(id) { id })
    }
    let ids : Array[Int] = []
    for id in candidates {
      budget.tick()
      match self.nodes[id].kind {
        TokenLeaf(_) => ()
        _ => {
          let mut alternatives = 0
          for family in self.nodes[id].families {
            if forest_analysis_family_productive(
                self, family, productive, budget,
              ) {
              alternatives += 1
              if alternatives == 2 {
                ids.push(id)
                break
              }
            }
          }
        }
      }
    }
    Ok(ids)
  } catch {
    ForestAnalysisHalt(problem) => Err(problem)
  }
}

///|
/// Quote all user strings for a DOT quoted label, never an HTML label or ID.
/// Also escape backslashes so Graphviz substitutions like \N cannot activate.
/// Rare C0/DEL controls become visible text instead of raw control bytes.
fn forest_query_dot_escape(
  value : String,
  budget : ForestAnalysisBudget,
) -> String raise ForestAnalysisHalt {
  let out = StringBuilder()
  for c in value.iter() {
    budget.tick()
    match c {
      '\\' => out.write_string("\\\\")
      '"' => out.write_string("\\\"")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ => {
        let code = c.to_int()
        if code < 32 || code == 127 {
          out.write_string("\\\\control(\{code})")
        } else {
          out.write_char(c)
        }
      }
    }
  }
  out.to_string()
}

///|
fn forest_query_rule_tag(
  forest : Forest,
  rule : Int,
) -> String raise ForestAnalysisHalt {
  if rule < 0 || rule >= forest.rules.length() {
    raise ForestAnalysisHalt(
      InvalidGrammar("rule index outside forest snapshot"),
    )
  }
  forest.rules[rule].label
}

///|
fn forest_query_node_label(
  forest : Forest,
  id : Int,
) -> String raise ForestAnalysisHalt {
  let node = forest.nodes[id]
  let span = "[\{node.start},\{node.end})"
  match node.kind {
    SymbolNode(name) => "\{name} \{span}"
    Intermediate(rule, dot) => {
      let tag = forest_query_rule_tag(forest, rule)
      "prefix #\{rule} \{tag} ·\{dot} \{span}"
    }
    TokenLeaf(index) => {
      if index < 0 || index >= forest.tokens.length() {
        raise ForestAnalysisHalt(
          InvalidToken(index, "index outside forest token snapshot"),
        )
      }
      let token = forest.tokens[index]
      "token #\{index} \{token.kind}: \{token.text} \{span}"
    }
  }
}

///|
/// Deterministic DOT encodes AND/OR structure with a separate box per family.
/// Ordered child edges keep their positions, including repeated child IDs.
/// Empty families remain visible. Cycles are exported without tree expansion.
/// Default output covers all structural root-reachable families; false includes
/// the entire chart snapshot. Work also charges every escaped label character.
pub fn Forest::to_dot(
  self : Forest,
  reachable_only? : Bool = true,
  work_limit? : Int = 1000000,
) -> Result[String, Problem] {
  let budget = match forest_query_budget(work_limit) {
    Err(problem) => return Err(problem)
    Ok(budget) => budget
  }
  try {
    let ids = if reachable_only {
      forest_query_walk(self, self.root, None, budget)
    } else {
      Array::makei(self.nodes.length(), fn(id) { id })
    }
    let out = StringBuilder()
    out.write_string("digraph Forest {\n  rankdir=LR;\n")
    for id in ids {
      budget.tick()
      let node = self.nodes[id]
      let label = forest_query_dot_escape(
        forest_query_node_label(self, id),
        budget,
      )
      let shape = match node.kind {
        TokenLeaf(_) => "box"
        _ => "ellipse"
      }
      let root_style = if self.root == Some(id) {
        ", peripheries=2"
      } else {
        ""
      }
      out.write_string(
        "  n\{id} [shape=\{shape}\{root_style}, label=\"\{label}\"];\n",
      )
      match node.kind {
        TokenLeaf(_) => ()
        _ =>
          for index, family in node.families {
            budget.tick()
            let tag = forest_query_rule_tag(self, family.rule)
            let label = forest_query_dot_escape(
              "#\{family.rule}: \{tag}",
              budget,
            )
            out.write_string(
              "  f\{id}_\{index} [shape=box, label=\"\{label}\"];\n",
            )
            out.write_string("  n\{id} -> f\{id}_\{index};\n")
            for position, child in family.children {
              budget.tick()
              forest_analysis_check_id(self, child)
              out.write_string(
                "  f\{id}_\{index} -> n\{child} [label=\"\{position}\"];\n",
              )
            }
          }
      }
    }
    out.write_string("}\n")
    Ok(out.to_string())
  } catch {
    ForestAnalysisHalt(problem) => Err(problem)
  }
}
