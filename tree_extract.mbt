///|
/// Extraction budgets are independent of the parser's chart budgets.
/// Depth counts AST rules/tokens, never Intermediate prefix nodes.
pub(all) struct TreeLimits {
  max_trees : Int32
  max_depth : Int32
  work_budget : Int32
} derive(Eq, Debug)

///|
pub extend TreeLimits with Eq::{equal, not_equal}

///|
pub extend TreeLimits with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn default_tree_limits() -> TreeLimits {
  { max_trees: 64, max_depth: 128, work_budget: 100000, }
}

///|
/// A hard depth ceiling remains useful even though extraction itself is iterative.
pub fn TreeLimits::validate(self : TreeLimits) -> Result[Unit, Problem] {
  if self.max_trees < 1 || self.max_trees > 100000 {
    return Err(InvalidLimit("max_trees"))
  }
  if self.max_depth < 1 || self.max_depth > 256 {
    return Err(InvalidLimit("max_depth"))
  }
  if self.work_budget < 1 || self.work_budget > 10000000 {
    return Err(InvalidLimit("work_budget"))
  }
  Ok(())
}

///|
/// Flags are independent: a cyclic forest can still yield finite trees.
/// A tree-limit flag means an additional complete tree was actually discovered.
/// Cycle/depth flags mean branches were skipped, not that they lack derivations.
pub(all) struct TreeExtractionStatus {
  tree_limit : Bool
  depth_limit : Bool
  work_limit : Bool
  cycle_truncated : Bool
} derive(Eq, Debug)

///|
pub extend TreeExtractionStatus with Eq::{equal, not_equal}

///|
pub extend TreeExtractionStatus with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn TreeExtractionStatus::truncated(self : TreeExtractionStatus) -> Bool {
  self.tree_limit || self.depth_limit || self.work_limit || self.cycle_truncated
}

///|
/// Owned results. Getters copy all mutable tree arrays, including shared children.
pub struct TreeExtraction {
  trees : Array[Tree]
  status : TreeExtractionStatus
  work : Int32
}

///|
pub fn TreeExtraction::trees(self : TreeExtraction) -> Array[Tree] {
  self.trees.map(fn(tree) { tree.copy() })
}

///|
pub fn TreeExtraction::tree_count(self : TreeExtraction) -> Int32 {
  self.trees.length()
}

///|
pub fn TreeExtraction::status(self : TreeExtraction) -> TreeExtractionStatus {
  self.status
}

///|
pub fn TreeExtraction::truncated(self : TreeExtraction) -> Bool {
  self.status.truncated()
}

///|
/// Charged task steps, path comparisons, branch copies, child scheduling/merging.
pub fn TreeExtraction::work(self : TreeExtraction) -> Int32 {
  self.work
}

///|
/// Persistent paths are branch-local; siblings do not poison each other's checks.
priv enum TreeExtractPath {
  Empty
  Link(Int32, TreeExtractPath)
}

///|
priv enum TreeExtractTask {
  Visit(Int32, Int32, TreeExtractPath)
  Choose(Int32, Int32, Int32, TreeExtractPath)
  Finish(Int32, TreeSpan, Int32, Bool)
}

///|
priv struct TreeExtractState {
  tasks : Array[TreeExtractTask]
  values : Array[Array[Tree]]
}

///|
priv suberror TreeExtractHalt {
  Budget
  Invalid(Problem)
}

///|
priv struct TreeExtractor {
  forest : Forest
  limits : TreeLimits
  trees : Array[Tree]
  mut status : TreeExtractionStatus
  mut work : Int32
}

///|
fn TreeExtractor::tick(self : TreeExtractor) -> Unit raise TreeExtractHalt {
  if self.work >= self.limits.work_budget {
    raise Budget
  }
  self.work = self.work + 1
}

///|
/// Compare IDs without recursion or a global visited set (shared DAGs are legal).
fn TreeExtractor::on_path(
  self : TreeExtractor,
  path : TreeExtractPath,
  id : Int32,
) -> Bool raise TreeExtractHalt {
  let mut cursor = path
  while true {
    match cursor {
      Empty => break
      Link(ancestor, parent) => {
        self.tick()
        if ancestor == id {
          return true
        }
        cursor = parent
      }
    }
  }
  false
}

///|
/// Copy only frontier arrays; tasks and completed partial sequences are immutable.
/// Every copied entry is charged, bounding Cartesian-frontier allocation too.
fn TreeExtractor::branch(
  self : TreeExtractor,
  state : TreeExtractState,
) -> TreeExtractState raise TreeExtractHalt {
  let tasks : Array[TreeExtractTask] = []
  let values : Array[Array[Tree]] = []
  for task in state.tasks {
    self.tick()
    tasks.push(task)
  }
  for value in state.values {
    self.tick()
    values.push(value)
  }
  { tasks, values, }
}

///|
/// Schedule an AND-family left to right. Intermediate nodes consume no AST depth.
fn TreeExtractor::family(
  self : TreeExtractor,
  state : TreeExtractState,
  node : Node,
  family : Family,
  depth : Int32,
  path : TreeExtractPath,
) -> Unit raise TreeExtractHalt {
  let symbol = node.kind is SymbolNode(_)
  if symbol {
    if family.rule < 0 || family.rule >= self.forest.rules.length() {
      raise Invalid(InvalidGrammar("tree family rule outside forest snapshot"))
    }
    match node.kind {
      SymbolNode(name) =>
        if self.forest.rules[family.rule].lhs != name {
          raise Invalid(
            InvalidGrammar("tree family rule does not define symbol"),
          )
        }
      _ => ()
    }
  }
  self.tick()
  state.tasks.push(
    Finish(
      family.rule,
      { start: node.start, end: node.end, },
      family.children.length(),
      symbol,
    ),
  )
  let child_depth = if symbol { depth + 1 } else { depth }
  let mut i = family.children.length()
  while i > 0 {
    self.tick()
    i = i - 1
    state.tasks.push(Visit(family.children[i], child_depth, path))
  }
}

///|
/// Prefix sequences flatten into real children; there is no synthetic AST node.
fn TreeExtractor::finish(
  self : TreeExtractor,
  state : TreeExtractState,
  rule : Int32,
  span : TreeSpan,
  count : Int32,
  symbol : Bool,
) -> Unit raise TreeExtractHalt {
  if count > state.values.length() {
    raise Invalid(InvalidGrammar("incomplete tree extraction stack"))
  }
  let begin = state.values.length() - count
  let children : Array[Tree] = []
  for i = begin; i < state.values.length(); i = i + 1 {
    self.tick()
    for tree in state.values[i] {
      self.tick()
      children.push(tree)
    }
  }
  for i = 0; i < count; i = i + 1 {
    ignore(state.values.pop())
  }
  if symbol {
    let label = self.forest.rules[rule].label
    state.values.push([RuleNode({ label, rule, span, children, })])
  } else {
    state.values.push(children)
  }
}

///|
/// Lazy DFS choices enumerate the full sibling Cartesian product in family order.
/// Each deferred choice stores a clean frontier before this family's children.
fn TreeExtractor::run(
  self : TreeExtractor,
  root : Int32,
) -> Unit raise TreeExtractHalt {
  let agenda : Array[TreeExtractState] = [
    { tasks: [Visit(root, 1, Empty)], values: [], },
  ]
  while !agenda.is_empty() {
    let state = agenda.pop().unwrap()
    let mut dead = false
    while !state.tasks.is_empty() {
      self.tick()
      match state.tasks.pop().unwrap() {
        Visit(id, depth, path) => {
          if id < 0 || id >= self.forest.nodes.length() {
            raise Invalid(InvalidNode(id))
          }
          if self.on_path(path, id) {
            self.status = { ..self.status, cycle_truncated: true, }
            dead = true
            break
          }
          let node = self.forest.nodes[id]
          if !(node.kind is Intermediate(_, _)) && depth > self.limits.max_depth {
            self.status = { ..self.status, depth_limit: true, }
            dead = true
            break
          }
          match node.kind {
            TokenLeaf(index) => {
              if index < 0 || index >= self.forest.tokens.length() {
                raise Invalid(
                  InvalidToken(index, "tree token outside forest snapshot"),
                )
              }
              let token = self.forest.tokens[index]
              state.values.push([
                TokenNode({
                  token,
                  span: { start: node.start, end: node.end, },
                }),
              ])
            }
            SymbolNode(_) | Intermediate(_, _) => {
              if node.families.is_empty() {
                dead = true
                break
              }
              state.tasks.push(Choose(id, 0, depth, Link(id, path)))
            }
          }
        }
        Choose(id, choice, depth, path) => {
          let node = self.forest.nodes[id]
          if choice + 1 < node.families.length() {
            let deferred = self.branch(state)
            self.tick()
            deferred.tasks.push(Choose(id, choice + 1, depth, path))
            agenda.push(deferred)
          }
          self.family(state, node, node.families[choice], depth, path)
        }
        Finish(rule, span, count, symbol) =>
          self.finish(state, rule, span, count, symbol)
      }
    }
    if dead {
      continue
    }
    if state.values.length() != 1 || state.values[0].length() != 1 {
      raise Invalid(InvalidGrammar("forest root must yield one AST node"))
    }
    if self.trees.length() == self.limits.max_trees {
      self.status = { ..self.status, tree_limit: true, }
      return
    }
    self.trees.push(state.values[0][0])
  }
}

///|
/// Extract finite cycle-free derivations, not a promise to enumerate cyclic trees.
/// Repeated IDs on one path skip only that branch and set cycle_truncated; other
/// finite alternatives remain eligible, including productive unit/epsilon cycles.
/// max_trees is inclusive: after filling it, search for one extra finite tree to
/// determine truncation. Work/depth exhaustion is explicit even with zero trees.
/// A rejected forest (no root) has an empty, complete result. Invalid limits or
/// inconsistent internal forest references are Err; ordinary truncation is Ok.
pub fn extract_trees(
  forest : Forest,
  limits~ : TreeLimits = default_tree_limits(),
) -> Result[TreeExtraction, Problem] {
  match limits.validate() {
    Err(problem) => return Err(problem)
    Ok(_) => ()
  }
  let extractor : TreeExtractor = {
    forest,
    limits,
    trees: [],
    work: 0,
    status: {
      tree_limit: false,
      depth_limit: false,
      work_limit: false,
      cycle_truncated: false,
    },
  }
  match forest.root {
    None => ()
    Some(root) =>
      extractor.run(root) catch {
        Budget => extractor.status = { ..extractor.status, work_limit: true, }
        Invalid(problem) => return Err(problem)
      }
  }
  Ok({ trees: extractor.trees, status: extractor.status, work: extractor.work, })
}

///|
pub fn Forest::extract_trees(
  self : Forest,
  limits~ : TreeLimits = default_tree_limits(),
) -> Result[TreeExtraction, Problem] {
  extract_trees(self, limits~)
}
