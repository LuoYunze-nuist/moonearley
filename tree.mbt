///|
/// Half-open token-index interval, not the caller's Token.start/end units.
pub(all) struct TreeSpan {
  start : Int32
  end : Int32
} derive(Eq, Debug)

///|
pub extend TreeSpan with Eq::{equal, not_equal}

///|
pub extend TreeSpan with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// A real grammar production. Intermediate forest prefixes never become this node.
pub(all) struct RuleTree {
  label : String
  rule : Int32
  span : TreeSpan
  children : Array[Tree]
} derive(Eq, Debug)

///|
pub extend RuleTree with Eq::{equal, not_equal}

///|
pub extend RuleTree with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// The original immutable token plus its interval in the parser token sequence.
pub(all) struct TokenTree {
  token : Token
  span : TreeSpan
} derive(Eq, Debug)

///|
pub extend TokenTree with Eq::{equal, not_equal}

///|
pub extend TokenTree with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// A finite AST. Caller-constructed trees must be acyclic for traversal tools.
/// Arrays are caller-owned; extraction reports expose independently copied trees.
pub(all) enum Tree {
  RuleNode(RuleTree)
  TokenNode(TokenTree)
} derive(Eq, Debug)

///|
pub extend Tree with Eq::{equal, not_equal}

///|
pub extend Tree with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub(all) struct TreeMetrics {
  size : Int32
  depth : Int32
  tokens : Int32
} derive(Eq, Debug)

///|
pub extend TreeMetrics with Eq::{equal, not_equal}

///|
pub extend TreeMetrics with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn Tree::span(self : Tree) -> TreeSpan {
  match self {
    RuleNode(node) => node.span
    TokenNode(node) => node.span
  }
}

///|
/// Reverse pushing produces left-to-right preorder without native recursion.
fn tree_push_children(pending : Array[Tree], node : RuleTree) -> Unit {
  let mut i = node.children.length()
  while i > 0 {
    i = i - 1
    pending.push(node.children[i])
  }
}

///|
/// Leaves retain text, kind and caller source offsets; no retokenization occurs.
pub fn Tree::tokens(self : Tree) -> Array[Token] {
  let pending = [self]
  let result : Array[Token] = []
  while !pending.is_empty() {
    match pending.pop().unwrap() {
      TokenNode(node) => result.push(node.token)
      RuleNode(node) => tree_push_children(pending, node)
    }
  }
  result
}

///|
/// Production labels in left-to-right preorder, including repeated labels.
pub fn Tree::rule_labels(self : Tree) -> Array[String] {
  let pending = [self]
  let result : Array[String] = []
  while !pending.is_empty() {
    match pending.pop().unwrap() {
      TokenNode(_) => ()
      RuleNode(node) => {
        result.push(node.label)
        tree_push_children(pending, node)
      }
    }
  }
  result
}

///|
/// Size counts rules AND tokens; epsilon has size/depth one. Root depth is one.
/// Explicit traversal stacks also support deep caller-created finite trees.
pub fn Tree::metrics(self : Tree) -> TreeMetrics {
  let pending = [(self, 1)]
  let mut size = 0
  let mut depth = 0
  let mut tokens = 0
  while !pending.is_empty() {
    let (tree, level) = pending.pop().unwrap()
    size = size + 1
    if level > depth {
      depth = level
    }
    match tree {
      TokenNode(_) => tokens = tokens + 1
      RuleNode(node) =>
        for child in node.children {
          pending.push((child, level + 1))
        }
    }
  }
  { size, depth, tokens, }
}

///|
pub fn Tree::size(self : Tree) -> Int32 {
  self.metrics().size
}

///|
pub fn Tree::depth(self : Tree) -> Int32 {
  self.metrics().depth
}

///|
priv enum TreeCopyTask {
  Visit(Tree)
  Build(RuleTree)
}

///|
/// Deep-copy every child array, including arrays shared by separate branches.
/// The iterative rebuild never borrows caller arrays in the returned tree.
pub fn Tree::copy(self : Tree) -> Tree {
  let tasks = [TreeCopyTask::Visit(self)]
  let values : Array[Tree] = []
  while !tasks.is_empty() {
    match tasks.pop().unwrap() {
      Visit(TokenNode(node)) => values.push(TokenNode(node))
      Visit(RuleNode(node)) => {
        tasks.push(Build(node))
        let mut i = node.children.length()
        while i > 0 {
          i = i - 1
          tasks.push(Visit(node.children[i]))
        }
      }
      Build(node) => {
        let count = node.children.length()
        let begin = values.length() - count
        let children : Array[Tree] = []
        for i = begin; i < values.length(); i = i + 1 {
          children.push(values[i])
        }
        for i = 0; i < count; i = i + 1 {
          ignore(values.pop())
        }
        values.push(RuleNode({ ..node, children, }))
      }
    }
  }
  values[0]
}
