///|
test "public entrypoints reject malformed tokens and limits without manufacturing reports" {
  let g = @moonearley.parse_grammar("S -> 'x';").unwrap()
  let invalid = { ..@moonearley.default_limits(), nodes: 0, }
  assert_true(
    @moonearley.parse(g, [], limits=invalid) is Err(InvalidLimit("nodes")),
  )
  assert_true(
    @moonearley.Session::new(g, limits=invalid) is Err(InvalidLimit("nodes")),
  )
  assert_true(
    @moonearley.parse(g, [@moonearley.token("", "x", 0, 1)])
    is Err(InvalidToken(0, _)),
  )
  let s = @moonearley.Session::new(g).unwrap()
  let initial = s.report().statistics()
  assert_true(
    s.push(@moonearley.token("x", "x", -1, 0)) is Err(InvalidToken(0, _)),
  )
  assert_true(
    s.push(@moonearley.token("x", "x", 2, 1)) is Err(InvalidToken(0, _)),
  )
  assert_true(
    s.push(@moonearley.token("", "x", 0, 1)) is Err(InvalidToken(0, _)),
  )
  assert_eq(s.report().statistics(), initial)
}

///|
test "external callers compose forest and tree API without private representation access" {
  let g = @moonearley.parse_grammar("S -> ['left'] 'x' | ['right'] 'x';").unwrap()
  let f = @moonearley.parse(g, [@moonearley.token("x", "payload", 7, 14)])
    .unwrap()
    .forest()
  assert_eq(f.count().unwrap(), @moonearley.Finite(2))
  let view = f.node(f.root().unwrap()).unwrap()
  view.alternatives.clear()
  assert_eq(f.count().unwrap(), @moonearley.Finite(2))
  let result = f.extract_trees().unwrap()
  assert_eq(result.tree_count(), 2)
  assert_true(!result.truncated())
  for tree in result.trees() {
    assert_eq(tree.tokens(), [@moonearley.token("x", "payload", 7, 14)])
    assert_eq(tree.span(), @moonearley.TreeSpan::{ start: 0, end: 1, })
    assert_eq(tree.metrics().tokens, 1)
  }
}
