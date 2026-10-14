///|
test "analysis distinguishes nullable productive and syntactically reachable" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("A"), Nonterminal("B")], "s"),
    grammar_test_rule("A", [], "a"),
    grammar_test_rule("B", [Terminal("b")], "b"),
    grammar_test_rule("Dead", [Nonterminal("Dead")], "dead"),
    grammar_test_rule("Unused", [], "unused"),
  ]).unwrap()
  let a = g.analyze()
  assert_eq(g.nullable(), ["A", "Unused"])
  assert_eq(g.productive(), ["A", "B", "S", "Unused"])
  assert_eq(g.reachable(), ["A", "B", "S"])
  assert_eq(a.nullable(), g.nullable())
  assert_eq(a.productive(), g.productive())
  assert_eq(a.reachable(), g.reachable())
  assert_true(a.is_nullable("A"))
  assert_true(!a.is_nullable("S"))
  assert_true(a.is_productive("S"))
  assert_true(!a.is_productive("Dead"))
  assert_true(a.is_reachable("B"))
  assert_true(!a.is_reachable("Unused"))
  for name in ["missing", "", "b"] {
    assert_true(!a.is_nullable(name))
    assert_true(!a.is_productive(name))
    assert_true(!a.is_reachable(name))
  }
  assert_eq(a.rule_is_nullable(0), Some(false))
  assert_eq(a.rule_is_nullable(1), Some(true))
  assert_eq(a.rule_is_productive(3), Some(false))
  assert_eq(a.rule_is_productive(4), Some(true))
  assert_eq(a.rule_is_reachable(4), Some(false))
  assert_eq(a.rule_is_reachable(0), Some(true))
  for index in [-1, 5, 1000000] {
    assert_eq(a.rule_is_nullable(index), None)
    assert_eq(a.rule_is_productive(index), None)
    assert_eq(a.rule_is_reachable(index), None)
  }
}

///|
test "analysis cycles require a finite base case and reachability ignores productivity" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("Loop")], "s"),
    grammar_test_rule("Loop", [Nonterminal("Loop"), Terminal("x")], "loop"),
    grammar_test_rule("A", [Nonterminal("B")], "a"),
    grammar_test_rule("B", [Nonterminal("A")], "b"),
    grammar_test_rule("B", [], "base"),
  ]).unwrap()
  assert_eq(g.nullable(), ["A", "B"])
  assert_eq(g.productive(), ["A", "B"])
  assert_eq(g.reachable(), ["Loop", "S"])
  let a = g.analyze()
  assert_eq(a.rule_is_reachable(1), Some(true))
  assert_eq(a.rule_is_productive(0), Some(false))
  assert_eq(a.rule_is_nullable(1), Some(false))
}

///|
test "analysis repeated nullable symbols conjunctions and terminal namespace" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("A"), Nonterminal("A")], "both"),
    grammar_test_rule("S", [Nonterminal("A"), Terminal("A")], "terminal"),
    grammar_test_rule("A", [], "empty"),
  ]).unwrap()
  let a = g.analyze()
  assert_eq(g.nullable(), ["A", "S"])
  assert_eq(g.productive(), ["A", "S"])
  assert_eq(a.rule_is_nullable(0), Some(true))
  assert_eq(a.rule_is_nullable(1), Some(false))
  assert_eq(a.rule_is_productive(1), Some(true))
}

///|
test "analysis long reverse dependency chain converges independently of rule order" {
  let rules : Array[Rule] = []
  for i in 0..<80 {
    rules.push(grammar_test_rule("N\{i}", [Nonterminal("N\{i + 1}")], "r\{i}"))
  }
  rules.push(grammar_test_rule("N80", [], "base"))
  let g = Grammar::new("N0", rules).unwrap()
  assert_eq(g.nullable().length(), 81)
  assert_eq(g.productive().length(), 81)
  assert_eq(g.reachable().length(), 81)
  let reversed_rules = rules.mapi(fn(i, _) { rules[rules.length() - i - 1] })
  let reversed = Grammar::new("N0", reversed_rules).unwrap()
  assert_eq(g.nullable(), reversed.nullable())
  assert_eq(g.productive(), reversed.productive())
  assert_eq(g.reachable(), reversed.reachable())
}

///|
test "analysis results are owned and independent across calls" {
  let g = Grammar::new("S", [grammar_test_rule("S", [], "epsilon")]).unwrap()
  let a = g.analyze()
  let nullable = a.nullable()
  let productive = a.productive()
  let reachable = a.reachable()
  nullable.clear()
  productive[0] = "Other"
  reachable.push("Other")
  assert_eq(a.nullable(), ["S"])
  assert_eq(a.productive(), ["S"])
  assert_eq(a.reachable(), ["S"])
  assert_eq(g.nullable(), ["S"])
  assert_eq(a.rule_is_nullable(0), Some(true))
  assert_eq(a.rule_is_productive(0), Some(true))
  assert_eq(a.rule_is_reachable(0), Some(true))
}

