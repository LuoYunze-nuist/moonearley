///|
fn grammar_test_findings(
  grammar : Grammar,
  kind : GrammarLintKind,
) -> Array[GrammarDiagnostic] {
  grammar.lint().filter(fn(diagnostic) { diagnostic.kind == kind })
}

///|
test "lint a clean epsilon token grammar has no warnings" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("A"), Terminal("end")], "s"),
    grammar_test_rule("A", [], "empty"),
    grammar_test_rule("A", [Terminal("a")], "a"),
  ]).unwrap()
  assert_eq(g.lint(), [])
}

///|
test "lint unreachable and nonproductive rules are independent expansion facts" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Terminal("ok")], "good"),
    grammar_test_rule("S", [Nonterminal("Dead")], "bad"),
    grammar_test_rule("Dead", [Nonterminal("Dead")], "dead"),
    grammar_test_rule("Unused", [Terminal("u")], "unused"),
    grammar_test_rule("Orphan", [Nonterminal("Orphan")], "orphan"),
  ]).unwrap()
  let disconnected = grammar_test_findings(g, UnreachableRule)
  assert_eq(disconnected.map(fn(d) { d.rule_index }), [3, 4])
  assert_eq(disconnected[0].rule_label, "unused")
  assert_eq(disconnected[0].nonterminals, ["Unused"])
  assert_eq(disconnected[0].related_rules, [])
  assert_eq(disconnected[0].message, "rule unused is unreachable from S")
  let nonproductive = grammar_test_findings(g, NonproductiveRule)
  assert_eq(nonproductive.map(fn(d) { d.rule_index }), [1, 2, 4])
  assert_eq(
    nonproductive[0].message,
    "rule bad has no finite terminal derivation",
  )
  assert_true(g.productive().contains("S"))
  assert_eq(grammar_test_findings(g, LeftRecursion).length(), 2)
  assert_eq(grammar_test_findings(g, NullableCycle), [])
}

///|
test "lint duplicate expansions compare symbols not labels or names alone" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [], "e1"),
    grammar_test_rule("S", [], "e2"),
    grammar_test_rule("S", [], "e3"),
    grammar_test_rule("S", [Terminal("A")], "terminal"),
    grammar_test_rule("S", [Nonterminal("A")], "nonterminal"),
    grammar_test_rule("S", [Terminal("A")], "terminal2"),
    grammar_test_rule("A", [], "a"),
  ]).unwrap()
  let duplicate = grammar_test_findings(g, DuplicateExpansion)
  assert_eq(duplicate.map(fn(d) { d.rule_index }), [1, 2, 5])
  assert_eq(duplicate[0].related_rules, [0])
  assert_eq(duplicate[1].related_rules, [0])
  assert_eq(duplicate[2].related_rules, [3])
  assert_eq(
    duplicate[2].message,
    "rule terminal2 duplicates expansion of terminal",
  )
  assert_eq(duplicate[2].nonterminals, ["S"])
  assert_eq(grammar_test_findings(g, NullableCycle), [])
  assert_eq(grammar_test_findings(g, LeftRecursion), [])
}

///|
test "lint productive direct left recursion is not a nullable cycle" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("S"), Terminal("+")], "left"),
    grammar_test_rule("S", [Terminal("id")], "base"),
  ]).unwrap()
  let left = grammar_test_findings(g, LeftRecursion)
  assert_eq(left.length(), 1)
  assert_eq(left[0].rule_index, 0)
  assert_eq(left[0].rule_label, "left")
  assert_eq(left[0].related_rules, [0])
  assert_eq(left[0].nonterminals, ["S"])
  assert_eq(left[0].message, "left-recursive derivation component containing S")
  assert_eq(grammar_test_findings(g, NullableCycle), [])
  assert_eq(grammar_test_findings(g, NonproductiveRule), [])
  assert_eq(g.rule_count(), 2)
}

///|
test "lint indirect left recursion skips nullable prefixes but not terminals" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("Empty"), Nonterminal("A")], "s"),
    grammar_test_rule("A", [Nonterminal("S"), Terminal("x")], "a"),
    grammar_test_rule("A", [Terminal("base")], "base"),
    grammar_test_rule("Empty", [], "empty"),
    grammar_test_rule(
      "Right",
      [Terminal("prefix"), Nonterminal("Right")],
      "right",
    ),
    grammar_test_rule("Right", [], "right_base"),
  ]).unwrap()
  let left = grammar_test_findings(g, LeftRecursion)
  assert_eq(left.length(), 1)
  assert_eq(left[0].related_rules, [0, 1])
  assert_eq(left[0].nonterminals, ["A", "S"])
  assert_eq(grammar_test_findings(g, NullableCycle), [])
}

///|
test "lint nullable mutual cycles report components once and exclude base rules" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("A")], "s"),
    grammar_test_rule("A", [Nonterminal("B"), Nonterminal("B")], "a"),
    grammar_test_rule("B", [Nonterminal("A")], "b"),
    grammar_test_rule("B", [], "base"),
  ]).unwrap()
  let nullable = grammar_test_findings(g, NullableCycle)
  let left = grammar_test_findings(g, LeftRecursion)
  assert_eq(nullable.length(), 1)
  assert_eq(left.length(), 1)
  assert_eq(nullable[0].nonterminals, ["A", "B"])
  assert_eq(nullable[0].related_rules, [1, 2])
  assert_eq(nullable[0].rule_index, 1)
  assert_eq(nullable[0].rule_label, "a")
  assert_eq(nullable[0].message, "nullable derivation cycle containing A")
  assert_eq(left[0].related_rules, [1, 2])
  assert_eq(grammar_test_findings(g, NonproductiveRule), [])
  assert_eq(g.nullable(), ["A", "B", "S"])
}

///|
test "lint a nonnullable prefix blocks later left recursion" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("Guard"), Nonterminal("S")], "right"),
    grammar_test_rule("S", [], "empty"),
    grammar_test_rule("Guard", [Terminal("g")], "guard"),
  ]).unwrap()
  assert_eq(g.lint(), [])
}

///|
test "lint nullable cycles require nullable entire expansions" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("S"), Nonterminal("Dead")], "blocked"),
    grammar_test_rule("S", [], "empty"),
    grammar_test_rule("Dead", [Nonterminal("Dead")], "dead"),
  ]).unwrap()
  assert_true(g.nullable().contains("S"))
  assert_eq(grammar_test_findings(g, NullableCycle), [])
  assert_eq(grammar_test_findings(g, LeftRecursion).length(), 2)
  assert_eq(
    grammar_test_findings(g, NonproductiveRule).map(fn(d) { d.rule_index }),
    [0, 2],
  )
}

///|
test "lint separate components nullable singleton and deterministic warning ordering" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [], "s"),
    grammar_test_rule("Z", [Nonterminal("Z")], "z"),
    grammar_test_rule("Z", [], "ze"),
    grammar_test_rule("A", [Nonterminal("B")], "a"),
    grammar_test_rule("B", [Nonterminal("A")], "b"),
  ]).unwrap()
  let nullable = grammar_test_findings(g, NullableCycle)
  assert_eq(nullable.length(), 1)
  assert_eq(nullable[0].nonterminals, ["Z"])
  assert_eq(nullable[0].related_rules, [1])
  let left = grammar_test_findings(g, LeftRecursion)
  assert_eq(left.map(fn(d) { d.nonterminals }), [["Z"], ["A", "B"]])
  let all = g.lint()
  assert_eq(all, g.lint())
  assert_eq(all.map(fn(d) { (d.rule_index, d.kind) }), [
    (1, UnreachableRule),
    (1, NullableCycle),
    (1, LeftRecursion),
    (2, UnreachableRule),
    (3, UnreachableRule),
    (3, NonproductiveRule),
    (3, LeftRecursion),
    (4, UnreachableRule),
    (4, NonproductiveRule),
  ])
}

///|
test "lint independent result arrays do not alias grammar or later diagnostics" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("S")], "cycle"),
    grammar_test_rule("S", [], "empty"),
    grammar_test_rule("S", [], "duplicate"),
  ]).unwrap()
  let first = g.lint()
  let saved = g.lint()
  first[0].related_rules.clear()
  first[0].nonterminals.clear()
  first.clear()
  assert_eq(g.lint(), saved)
  assert_eq(g.rules()[0].rhs, [Nonterminal("S")])
  assert_eq(g.nullable(), ["S"])
}

///|
test "lint long mutual cycle uses queues and reports one component not all paths" {
  let rules : Array[Rule] = []
  for i in 0..<70 {
    let next = (i + 1) % 70
    rules.push(grammar_test_rule("N\{i}", [Nonterminal("N\{next}")], "r\{i}"))
  }
  rules.push(grammar_test_rule("N69", [], "base"))
  let g = Grammar::new("N0", rules).unwrap()
  let diagnostics = g.lint()
  assert_eq(diagnostics.length(), 2)
  assert_eq(diagnostics[0].kind, NullableCycle)
  assert_eq(diagnostics[1].kind, LeftRecursion)
  assert_eq(diagnostics[0].nonterminals.length(), 70)
  assert_eq(diagnostics[0].related_rules.length(), 70)
  assert_eq(diagnostics[0].rule_index, 0)
  assert_eq(diagnostics[0].related_rules[69], 69)
}
