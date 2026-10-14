///|
test "forest views do not leak mutable family or rule arrays" {
  let f : Forest = {
    nodes: [
      {
        kind: SymbolNode("s"),
        start: 0,
        end: 0,
        families: [{ rule: 0, children: [], }],
      },
    ],
    tokens: [],
    rules: [{ lhs: "s", rhs: [], label: "empty", }],
    root: Some(0),
  }
  let view = f.node(0).unwrap()
  view.alternatives[0].children.push(42)
  view.alternatives.clear()
  assert_eq(f.node(0).unwrap().alternatives.length(), 1)
  assert_eq(f.node(0).unwrap().alternatives[0].children.length(), 0)
  f.rule_at(0).unwrap().rhs.push(Terminal("bad"))
  assert_eq(f.rule_at(0).unwrap().rhs.length(), 0)
  assert_eq(f.root(), Some(0))
  assert_eq(f.node_count(), 1)
  assert_eq(f.node(-1), Err(InvalidNode(-1)))
  assert_true(f.token_at(0) is Err(_))
}
