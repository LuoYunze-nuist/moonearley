///|
/// Advisory findings never change grammar validity or parser acceptance.
pub(all) enum GrammarLintKind {
  UnreachableRule
  NonproductiveRule
  DuplicateExpansion
  NullableCycle
  LeftRecursion
} derive(Eq, Debug)

///|
pub extend GrammarLintKind with Eq::{equal, not_equal}

///|
pub extend GrammarLintKind with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Indices refer to the original grammar order. For a cyclic component,
/// related_rules lists every production contributing an internal graph edge;
/// rule_index/label identify its earliest production. Names are lexical.
/// For a duplicate, related_rules contains the first matching expansion.
pub(all) struct GrammarDiagnostic {
  kind : GrammarLintKind
  rule_index : Int32
  rule_label : String
  related_rules : Array[Int32]
  nonterminals : Array[String]
  message : String
} derive(Eq, Debug)

///|
pub extend GrammarDiagnostic with Eq::{equal, not_equal}

///|
pub extend GrammarDiagnostic with @moonbitlang/core/debug.Debug::{to_repr}

///|
fn grammar_lint_rank(kind : GrammarLintKind) -> Int32 {
  match kind {
    UnreachableRule => 0
    NonproductiveRule => 1
    DuplicateExpansion => 2
    NullableCycle => 3
    LeftRecursion => 4
  }
}

///|
/// Left corners can occur after nullable nonterminals, but never after a
/// terminal or a nonnullable symbol. Epsilon dependencies require the ENTIRE
/// expansion to vanish; this distinguishes nullable cycles from mere recursion.
fn grammar_rule_dependencies(
  rule : Rule,
  nullable : Map[String, Bool],
  epsilon_only : Bool,
) -> Array[String] {
  let names : Map[String, Bool] = Map([])
  if epsilon_only && !grammar_sequence_nullable(rule.rhs, nullable) {
    return []
  }
  for symbol in rule.rhs {
    match symbol {
      Terminal(_) => break
      Nonterminal(name) => {
        names[name] = true
        if !epsilon_only && !nullable.contains(name) {
          break
        }
      }
    }
  }
  grammar_sorted_names(names)
}

///|
/// Build one finite directed graph; deduplicate parallel production edges.
fn grammar_dependency_graph(
  grammar : Grammar,
  nullable : Map[String, Bool],
  epsilon_only : Bool,
) -> Map[String, Array[String]] {
  let sets = grammar_empty_table(grammar.nonterminals())
  for rule in grammar.rules {
    let target = sets[rule.lhs]
    for name in grammar_rule_dependencies(rule, nullable, epsilon_only) {
      target[name] = true
    }
  }
  let graph : Map[String, Array[String]] = Map([])
  for name, successors in sets {
    graph[name] = grammar_sorted_names(successors)
  }
  graph
}

///|
fn grammar_reverse_graph(
  names : Array[String],
  graph : Map[String, Array[String]],
) -> Map[String, Array[String]] {
  let reverse : Map[String, Array[String]] = Map([])
  for name in names {
    reverse[name] = []
  }
  for name in names {
    for successor in graph[name] {
      reverse[successor].push(name)
    }
  }
  reverse
}

///|
/// An explicit queue avoids recursion depth limits for long dependency chains.
fn grammar_graph_closure(
  graph : Map[String, Array[String]],
  start : String,
) -> Map[String, Bool] {
  let seen : Map[String, Bool] = Map([])
  seen[start] = true
  let queue = [start]
  let mut cursor = 0
  while cursor < queue.length() {
    let name = queue[cursor]
    cursor = cursor + 1
    for successor in graph[name] {
      if grammar_add_name(seen, successor) {
        queue.push(successor)
      }
    }
  }
  seen
}

///|
/// A strongly connected component is forward(seed) intersect reverse(seed).
/// Process lexical seeds, mark the entire component, and omit acyclic singletons.
/// This nonrecursive diagnostic pass trades O(V*(V+E)) time for simple bounded
/// storage and does not enumerate the potentially exponential individual cycles.
fn grammar_cyclic_components(
  names : Array[String],
  graph : Map[String, Array[String]],
) -> Array[Array[String]] {
  let reverse = grammar_reverse_graph(names, graph)
  let assigned : Map[String, Bool] = Map([])
  let components : Array[Array[String]] = []
  for seed in names {
    if !assigned.contains(seed) {
      let forward = grammar_graph_closure(graph, seed)
      let backward = grammar_graph_closure(reverse, seed)
      let component : Array[String] = []
      for name in names {
        if forward.contains(name) && backward.contains(name) {
          assigned[name] = true
          component.push(name)
        }
      }
      if component.length() > 1 || graph[seed].contains(seed) {
        components.push(component)
      }
    }
  }
  components
}

///|
/// Return precisely the rules with at least one edge inside a component.
/// A rule headed in the component can still be a nonrecursive base alternative.
fn grammar_component_rules(
  grammar : Grammar,
  component : Array[String],
  nullable : Map[String, Bool],
  epsilon_only : Bool,
) -> Array[Int32] {
  let members : Map[String, Bool] = Map([])
  for name in component {
    members[name] = true
  }
  let indices : Array[Int32] = []
  for index, rule in grammar.rules {
    if members.contains(rule.lhs) {
      for name in grammar_rule_dependencies(rule, nullable, epsilon_only) {
        if members.contains(name) {
          indices.push(index)
          break
        }
      }
    }
  }
  indices
}

///|
fn grammar_cycle_diagnostics(
  grammar : Grammar,
  nullable : Map[String, Bool],
  epsilon_only : Bool,
) -> Array[GrammarDiagnostic] {
  let graph = grammar_dependency_graph(grammar, nullable, epsilon_only)
  let components = grammar_cyclic_components(grammar.nonterminals(), graph)
  let diagnostics : Array[GrammarDiagnostic] = []
  for component in components {
    let indices = grammar_component_rules(
      grammar, component, nullable, epsilon_only,
    )
    // Every retained cyclic component necessarily has an internal edge.
    if !indices.is_empty() {
      let index = indices[0]
      let kind = if epsilon_only { NullableCycle } else { LeftRecursion }
      let description = if epsilon_only {
        "nullable derivation cycle"
      } else {
        "left-recursive derivation component"
      }
      diagnostics.push({
        kind,
        rule_index: index,
        rule_label: grammar.rules[index].label,
        related_rules: indices,
        nonterminals: component,
        message: "\{description} containing \{component[0]}",
      })
    }
  }
  diagnostics
}

///|
/// Detect structural duplicate expansions, ignoring labels but respecting
/// Terminal/Nonterminal identity. Each later duplicate points at the earliest.
fn grammar_first_duplicate(grammar : Grammar, index : Int32) -> Int32? {
  let rule = grammar.rules[index]
  for previous in 0..<index {
    let candidate = grammar.rules[previous]
    if candidate.lhs == rule.lhs && candidate.rhs == rule.rhs {
      return Some(previous)
    }
  }
  None
}

///|
/// Return warnings sorted by original rule index, then declared kind order.
/// Reachability is syntactic; productivity is checked per RHS, not per LHS.
/// Cycles are reported once per component per kind, including disconnected
/// components. Earley parsing supports these grammars: nothing is rejected.
pub fn Grammar::lint(self : Grammar) -> Array[GrammarDiagnostic] {
  let analysis = self.analyze()
  let diagnostics : Array[GrammarDiagnostic] = []
  for index, rule in self.rules {
    if !analysis.reachable_names.contains(rule.lhs) {
      diagnostics.push({
        kind: UnreachableRule,
        rule_index: index,
        rule_label: rule.label,
        related_rules: [],
        nonterminals: [rule.lhs],
        message: "rule \{rule.label} is unreachable from \{self.start}",
      })
    }
    if !analysis.productive_rules[index] {
      diagnostics.push({
        kind: NonproductiveRule,
        rule_index: index,
        rule_label: rule.label,
        related_rules: [],
        nonterminals: [rule.lhs],
        message: "rule \{rule.label} has no finite terminal derivation",
      })
    }
    match grammar_first_duplicate(self, index) {
      None => ()
      Some(previous) =>
        diagnostics.push({
          kind: DuplicateExpansion,
          rule_index: index,
          rule_label: rule.label,
          related_rules: [previous],
          nonterminals: [rule.lhs],
          message: "rule \{rule.label} duplicates expansion of \{self.rules[previous].label}",
        })
    }
  }
  for
    diagnostic in grammar_cycle_diagnostics(self, analysis.nullable_names, true) {
    diagnostics.push(diagnostic)
  }
  for
    diagnostic in grammar_cycle_diagnostics(
      self,
      analysis.nullable_names,
      false,
    ) {
    diagnostics.push(diagnostic)
  }
  diagnostics.sort_by(fn(a, b) {
    let order = a.rule_index.compare(b.rule_index)
    if order != 0 {
      order
    } else {
      grammar_lint_rank(a.kind).compare(grammar_lint_rank(b.kind))
    }
  })
  diagnostics
}
