///|
fn grammar_for_test(start : String, rules : Array[Rule]) -> Grammar {
  Grammar::new(start, rules).unwrap()
}

///|
test "scanner recognizes kinds rather than text and reports next expected token" {
  let g = grammar_for_test("s", [
    { lhs: "s", rhs: [Terminal("id"), Terminal("end")], label: "pair", },
  ])
  let a = parse(g, [token("id", "anything", 0, 8)]).unwrap()
  assert_true(!a.accepted())
  assert_eq(a.expected(), ["end"])
  assert_eq(a.furthest(), 1)
  let b = parse(g, [token("id", "anything", 0, 8), token("end", "!", 8, 9)]).unwrap()
  assert_true(b.accepted())
  assert_true(b.forest().root() is Some(_))
  let c = parse(g, [token("bad", "id", 0, 2)]).unwrap()
  assert_true(!c.accepted())
  assert_eq(c.furthest(), 0)
  assert_eq(c.expected(), ["id"])
}

///|
test "left recursion and an epsilon cycle terminate without losing acceptance" {
  let g = grammar_for_test("s", [
    { lhs: "s", rhs: [Nonterminal("s"), Terminal("x")], label: "more", },
    { lhs: "s", rhs: [], label: "empty", },
    { lhs: "s", rhs: [Nonterminal("s")], label: "cycle", },
  ])
  assert_true(parse(g, []).unwrap().accepted())
  assert_true(
    parse(g, [token("x", "x", 0, 1), token("x", "x", 1, 2)]).unwrap().accepted(),
  )
  assert_true(!parse(g, [token("y", "y", 0, 1)]).unwrap().accepted())
}

///|
test "nullable completion pairs both waiter orders" {
  let g = grammar_for_test("s", [
    { lhs: "s", rhs: [Nonterminal("a"), Nonterminal("b")], label: "s", },
    { lhs: "a", rhs: [], label: "a", },
    { lhs: "b", rhs: [Nonterminal("a")], label: "b", },
  ])
  assert_true(parse(g, []).unwrap().accepted())
}

///|
test "every chart budget reports a failure rather than a negative parse" {
  let g = grammar_for_test("s", [
    { lhs: "s", rhs: [Terminal("x")], label: "x", },
  ])
  let d = default_limits()
  assert_true(
    parse(g, [token("x", "x", 0, 1)], limits={ ..d, tokens: 0, })
    is Err(Limit("tokens", 0)),
  )
  assert_true(
    parse(g, [token("x", "x", 0, 1)], limits={ ..d, work: 1, })
    is Err(Limit("work", 1)),
  )
  assert_true(
    parse(g, [token("x", "x", 0, 1)], limits={ ..d, nodes: 1, })
    is Err(Limit("nodes", 1)),
  )
  assert_true(
    parse(g, [token("x", "x", 0, 1)], limits={ ..d, items: 1, })
    is Err(Limit("items", 1)),
  )
  assert_true(
    parse(g, [token("x", "x", 0, 1)], limits={ ..d, families: 1, })
    is Err(Limit("families", 1)),
  )
}
