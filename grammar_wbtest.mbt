///|
fn grammar_test_rule(lhs : String, rhs : Array[Symbol], label : String) -> Rule {
  { lhs, rhs, label }
}

///|
test "grammar validates mandatory names and rule labels" {
  let epsilon = grammar_test_rule("S", [], "empty")
  assert_true(Grammar::new("", [epsilon]) is Err(InvalidGrammar(_)))
  assert_true(Grammar::new("S", []) is Err(InvalidGrammar(_)))
  assert_true(Grammar::new("X", [epsilon]) is Err(InvalidGrammar(_)))
  assert_true(
    Grammar::new("S", [grammar_test_rule("", [], "r")]) is Err(InvalidGrammar(_)),
  )
  assert_true(
    Grammar::new("S", [grammar_test_rule("S", [], "")]) is Err(InvalidGrammar(_)),
  )
  assert_true(
    Grammar::new("S", [epsilon, epsilon]) is Err(InvalidGrammar(_)),
  )
  assert_true(
    Grammar::new("S", [epsilon, grammar_test_rule("A", [], "empty")]) is Err(InvalidGrammar(_)),
  )
}

///|
test "grammar validates every reference and terminal including unused rules" {
  for symbol in [Terminal(""), Nonterminal(""), Nonterminal("missing")] {
    assert_true(
      Grammar::new("S", [grammar_test_rule("S", [symbol], "bad")]) is Err(InvalidGrammar(_)),
    )
    assert_true(
      Grammar::new("S", [
        grammar_test_rule("S", [], "start"),
        grammar_test_rule("Unused", [symbol], "bad"),
      ]) is Err(InvalidGrammar(_)),
    )
  }
}

///|
test "grammar allows epsilon forward references cycles and labeled duplicates" {
  let rules = [
    grammar_test_rule("S", [Nonterminal("A")], "forward"),
    grammar_test_rule("A", [Nonterminal("S")], "cycle"),
    grammar_test_rule("A", [], "empty1"),
    grammar_test_rule("A", [], "empty2"),
  ]
  let g = Grammar::new("S", rules).unwrap()
  assert_eq(g.start(), "S")
  assert_eq(g.rule_count(), 4)
  assert_eq(g.rules(), rules)
  assert_eq(g.nonterminals(), ["A", "S"])
  assert_eq(g.terminals(), [])
}

///|
test "grammar accessors sort deduplicate and preserve distinct symbol namespaces" {
  let g = Grammar::new("Z", [
    grammar_test_rule("Z", [Terminal("A"), Terminal("z"), Nonterminal("A"), Terminal("A")], "z"),
    grammar_test_rule("A", [Terminal("a")], "a"),
    grammar_test_rule("Disconnected", [Terminal("unused")], "d"),
  ]).unwrap()
  assert_eq(g.nonterminals(), ["A", "Disconnected", "Z"])
  assert_eq(g.terminals(), ["A", "a", "unused", "z"])
  assert_eq(g.rules()[0].label, "z")
  assert_eq(g.rule_count(), 3)
  let names = g.nonterminals()
  names[0] = "mutated"
  let kinds = g.terminals()
  kinds.clear()
  assert_eq(g.nonterminals(), ["A", "Disconnected", "Z"])
  assert_eq(g.terminals(), ["A", "a", "unused", "z"])
}

///|
test "grammar owns nested input and output arrays with no aliasing" {
  let expansion = [Terminal("id")]
  let input = [grammar_test_rule("S", expansion, "original")]
  let g = Grammar::new("S", input).unwrap()
  expansion[0] = Terminal("changed")
  input[0] = grammar_test_rule("Other", [], "replacement")
  input.clear()
  assert_eq(g.start(), "S")
  assert_eq(g.rules(), [grammar_test_rule("S", [Terminal("id")], "original")])
  let output1 = g.rules()
  let output2 = g.rules()
  output1[0].rhs.push(Terminal("extra"))
  output1[0] = grammar_test_rule("Other", [], "replacement")
  output1.clear()
  assert_eq(output2[0].rhs, [Terminal("id")])
  output2[0].rhs.clear()
  assert_eq(g.rules()[0].rhs, [Terminal("id")])
  assert_eq(g.terminals(), ["id"])
  assert_eq(g.rule_count(), 1)
}

///|
test "grammar treats unicode and whitespace as exact names" {
  let g = Grammar::new(" 起点 ", [
    grammar_test_rule(" 起点 ", [Nonterminal("项"), Terminal(" ")], " 标签 "),
    grammar_test_rule("项", [], "ε"),
  ]).unwrap()
  assert_eq(g.start(), " 起点 ")
  assert_eq(g.nonterminals(), [" 起点 ", "项"])
  assert_eq(g.terminals(), [" "])
}
