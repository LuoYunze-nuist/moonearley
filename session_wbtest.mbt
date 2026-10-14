///|
test "session appends retain sealed charts and report snapshots" {
  let g = grammar_for_test("s", [
    { lhs: "s", rhs: [Terminal("x"), Terminal("y")], label: "pair", },
  ])
  let session = Session::new(g).unwrap()
  let initial = session.report()
  assert_eq(initial.expected(), ["x"])
  let first = session.push(token("x", "a", 0, 1)).unwrap()
  assert_eq(first.expected(), ["y"])
  let second = session.push(token("y", "b", 1, 2)).unwrap()
  assert_true(second.accepted())
  assert_true(!first.accepted())
  assert_eq(first.statistics().tokens, 1)
  assert_eq(
    second.statistics(),
    parse(g, [token("x", "a", 0, 1), token("y", "b", 1, 2)])
    .unwrap()
    .statistics(),
  )
}

///|
test "failed single and batch pushes are transactional" {
  let g = grammar_for_test("s", [
    { lhs: "s", rhs: [Terminal("x")], label: "one", },
  ])
  let session = Session::new(g, limits={ ..default_limits(), tokens: 1, }).unwrap()
  let before = session.report().statistics()
  assert_true(
    session.push_all([token("x", "x", 0, 1), token("x", "x", 1, 2)])
    is Err(Limit("tokens", 1)),
  )
  assert_eq(session.report().statistics(), before)
  ignore(session.push(token("x", "x", 2, 3)).unwrap())
  let after = session.report().statistics()
  assert_true(session.push(token("x", "x", 1, 2)) is Err(InvalidToken(1, _)))
  assert_true(session.push(token("x", "x", 3, 4)) is Err(Limit("tokens", 1)))
  assert_eq(session.report().statistics(), after)
}

///|
test "forks diverge independently without changing the source" {
  let g = grammar_for_test("s", [
    { lhs: "s", rhs: [Terminal("x")], label: "x", },
    { lhs: "s", rhs: [Terminal("y")], label: "y", },
  ])
  let session = Session::new(g).unwrap()
  let fork = session.fork()
  assert_true(session.push(token("x", "", 0, 0)).unwrap().accepted())
  assert_true(fork.push(token("y", "", 0, 0)).unwrap().accepted())
  assert_eq(session.report().forest().token_at(0).unwrap().kind, "x")
  assert_eq(fork.report().forest().token_at(0).unwrap().kind, "y")
}
