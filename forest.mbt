///| Intermediate nodes encode one prefix of a production, not an AST node.
pub(all) enum NodeKind {
  TokenLeaf(Int)
  SymbolNode(String)
  Intermediate(Int, Int)
} derive(Eq, Debug)

///|
pub extend NodeKind with Eq::{equal, not_equal}

///|
pub extend NodeKind with @moonbitlang/core/debug.Debug::{to_repr}

///| A family is an AND-edge; a node's families are OR-alternatives.
pub(all) struct Family {
  rule : Int
  children : Array[Int]
} derive(Eq, Debug)

///|
pub extend Family with Eq::{equal, not_equal}

///|
pub extend Family with @moonbitlang/core/debug.Debug::{to_repr}

///| Read-only snapshot view. Mutating its arrays cannot mutate the forest.
pub(all) struct NodeInfo {
  kind : NodeKind
  start : Int
  end : Int
  alternatives : Array[Family]
} derive(Eq, Debug)

///|
pub extend NodeInfo with Eq::{equal, not_equal}

///|
pub extend NodeInfo with @moonbitlang/core/debug.Debug::{to_repr}

///|
struct Node {
  kind : NodeKind
  start : Int
  end : Int
  families : Array[Family]
}

///| Forest IDs are local to this snapshot; spans here are token-index intervals.
pub struct Forest {
  nodes : Array[Node]
  tokens : Array[Token]
  rules : Array[Rule]
  root : Int?
}

///|
fn copy_family(f : Family) -> Family {
  { rule: f.rule, children: f.children.copy() }
}

///|
fn copy_rule(r : Rule) -> Rule {
  { lhs: r.lhs, rhs: r.rhs.copy(), label: r.label }
}

///|
pub fn Forest::root(self : Forest) -> Int? {
  self.root
}

///|
pub fn Forest::node_count(self : Forest) -> Int {
  self.nodes.length()
}

///|
pub fn Forest::node(self : Forest, id : Int) -> Result[NodeInfo, Problem] {
  if id < 0 || id >= self.nodes.length() {
    return Err(InvalidNode(id))
  }
  let n = self.nodes[id]
  Ok({ kind: n.kind, start: n.start, end: n.end,
    alternatives: n.families.map(copy_family) })
}

///|
pub fn Forest::token_at(self : Forest, id : Int) -> Result[Token, Problem] {
  if id < 0 || id >= self.tokens.length() {
    Err(InvalidToken(id, "index outside forest token snapshot"))
  } else {
    Ok(self.tokens[id])
  }
}

///|
pub fn Forest::rule_at(self : Forest, id : Int) -> Result[Rule, Problem] {
  if id < 0 || id >= self.rules.length() {
    Err(InvalidGrammar("rule index outside forest snapshot"))
  } else {
    Ok(copy_rule(self.rules[id]))
  }
}
