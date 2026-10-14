///|
fn tree_test_leaf(kind : String, text : String, index : Int32) -> Tree {
  TokenNode({
    token: token(kind, text, index * 3, index * 3 + 2),
    span: { start: index, end: index + 1, },
  })
}

///|
fn tree_test_rule(label : String, children : Array[Tree]) -> Tree {
  RuleNode({ label, rule: 0, span: { start: 0, end: 2, }, children, })
}

///|
test "tree metrics labels and tokens are iterative ordered traversals" {
  let tree = tree_test_rule("root", [
    tree_test_rule("left", [tree_test_leaf("id", "甲", 0)]),
    tree_test_rule("empty", []),
    tree_test_leaf("end", "!", 1),
  ])
  assert_eq(tree.span(), { start: 0, end: 2, })
  assert_eq(tree.metrics(), { size: 5, depth: 3, tokens: 2, })
  assert_eq(tree.size(), 5)
  assert_eq(tree.depth(), 3)
  assert_eq(tree.rule_labels(), ["root", "left", "empty"])
  assert_eq(tree.tokens(), [token("id", "甲", 0, 2), token("end", "!", 3, 5)])
  assert_eq(tree_test_rule("epsilon", []).metrics(), {
    size: 1,
    depth: 1,
    tokens: 0,
  })
  assert_eq(tree_test_leaf("x", "x", 0).rule_labels(), [])
}

///|
test "tree copies isolate nested arrays and shared subtrees" {
  let children = [tree_test_leaf("x", "x", 0)]
  let shared = tree_test_rule("shared", children)
  let original = tree_test_rule("root", [shared, shared])
  let copied = original.copy()
  assert_eq(copied, original)
  match copied {
    RuleNode(root) => {
      match root.children[0] {
        RuleNode(first) => first.children.clear()
        _ => fail("expected rule")
      }
      assert_eq(root.children[1].tokens().length(), 1)
      root.children.clear()
    }
    _ => fail("expected root rule")
  }
  assert_eq(original.tokens().length(), 2)
  children.clear()
  assert_eq(original.tokens().length(), 0)
}

///|
test "tree utilities safely handle deep caller-created finite trees" {
  let mut tree = tree_test_leaf("x", "x", 0)
  for i = 0; i < 1200; i = i + 1 {
    tree = tree_test_rule("wrap", [tree])
  }
  assert_eq(tree.metrics(), { size: 1201, depth: 1201, tokens: 1, })
  assert_eq(tree.copy().metrics(), tree.metrics())
  assert_eq(tree.rule_labels().length(), 1200)
  assert_eq(tree.tokens().length(), 1)
}
