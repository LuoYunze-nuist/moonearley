///|
fn frontend_test_limits(
  chars : Int32,
  rules : Int32,
  symbols : Int32,
) -> FrontendLimits {
  { max_chars: chars, max_rules: rules, max_symbols: symbols, }
}

///|
test "frontend lexer preserves token offsets and skips comments" {
  let actual = frontend_lex("# hi\r\nA -> 'id' | ;").unwrap()
  assert_eq(actual.map(fn(t) { t.offset }), [6, 8, 11, 16, 18, 19])
  assert_true(actual[0].kind is Name("A"))
  assert_true(actual[1].kind is Arrow)
  assert_true(actual[2].kind is Quoted("id"))
  assert_true(actual[3].kind is Bar)
  assert_true(actual[4].kind is Semi)
  assert_true(actual[5].kind is End)
  let eof = frontend_lex(" \t\r\n# eof").unwrap()
  assert_eq(eof.length(), 1)
  assert_true(eof[0].kind is End)
  assert_eq(eof[0].offset, 9)
}

///|
test "frontend lexical errors have precise UTF16 positions" {
  for
    pair in [
      ("A - 'x';", 2),
      ("A -> 'x", 5),
      ("A -> 'x\\", 7),
      ("A -> '\\q';", 6),
      ("A -> 'x\ny';", 7),
      ("A -> '\\u12g4';", 10),
      ("A -> '\\u12", 10),
      ("A -> '\\uDC00';", 8),
      ("A -> '\\uD800';", 12),
      ("A -> '\\uD800\\u0041';", 14),
      ("A -> '😀' ?;", 10),
      ("@nope A;", 0),
      ("@starter A;", 6),
      ("A -> .;", 5),
      ("A -> '\u{007f}';", 6),
    ] {
    let (source, expected) = pair
    match frontend_lex(source) {
      Err(Syntax(offset, _)) => assert_eq(offset, expected)
      _ => fail("expected lexical error for \{source}")
    }
  }
}

///|
test "frontend quoted escapes Unicode and punctuation are literal" {
  let source = "A -> '汉😀#|;[]' '\\n\\r\\t\\\\\\'\\\"' '\\u0041\\uD83D\\uDE00';"
  let parsed = parse_grammar(source).unwrap()
  assert_eq(parsed.start(), "A")
  assert_eq(parsed.rules()[0].rhs, [
    Terminal("汉😀#|;[]"),
    Terminal("\n\r\t\\'\""),
    Terminal("A😀"),
  ])
}

///|
test "frontend alternatives epsilon forward references and labels" {
  let g = parse_grammar(
    "# heading\n@start B; A -> ['a'] 'x' B | | ; B -> A | ;",
  ).unwrap()
  assert_eq(g.start(), "B")
  let rules = g.rules()
  assert_eq(rules.length(), 5)
  assert_eq(rules[0], {
    lhs: "A",
    rhs: [Terminal("x"), Nonterminal("B")],
    label: "a",
  })
  assert_eq(rules[1].rhs, [])
  assert_eq(rules[2].rhs, [])
  assert_eq(rules[4].rhs, [])
  assert_eq(rules.map(fn(r) { r.label }), [
    "a", "rule:1", "rule:2", "rule:3", "rule:4",
  ])
  assert_eq(parse_grammar("A -> ;").unwrap().rules()[0].label, "rule:0")
  assert_eq(parse_grammar("A -> |;").unwrap().rules().length(), 2)
}

///|
test "frontend automatic labels reserve explicit labels even in later rules" {
  let g = parse_grammar("A -> | ['rule:0'] | ['rule:1'];").unwrap()
  assert_eq(g.rules().map(fn(r) { r.label }), ["rule:2", "rule:0", "rule:1"])
  assert_eq(
    parse_grammar("A -> | ['rule:0'] | ['rule:1'];").unwrap().rules(),
    g.rules(),
  )
}

///|
test "frontend double quoted names and default first start" {
  let g = parse_grammar(
    "\"入口 名😀\" -> \"n#\\\"\\n\"; \"n#\\\"\\n\" -> ;",
  ).unwrap()
  assert_eq(g.start(), "入口 名😀")
  assert_eq(g.rules()[0].rhs, [Nonterminal("n#\"\n")])
  assert_eq(parse_grammar("_A1 -> _A1 |;").unwrap().start(), "_A1")
}

///|
test "frontend parser malformed offsets include EOF" {
  for
    pair in [
      ("A 'x';", 2),
      ("A -> 'x'", 8),
      ("A ->", 4),
      ("A -> ['x' 'y';", 10),
      ("A -> [name];", 6),
      ("A -> [''];", 6),
      ("A -> 'x' ['l'];", 9),
      ("A -> ;;", 6),
      ("@start ; A -> ;", 7),
      ("@start A A -> ;", 9),
      ("A -> ; @start A;", 7),
      ("A -> ; B", 8),
      ("'A' -> ;", 0),
      ("A -> ];", 5),
      ("@start", 6),
      ("A -> [", 6),
      ("A -> ['l'", 9),
    ] {
    let (source, expected) = pair
    match parse_grammar(source) {
      Err(Syntax(offset, _)) => assert_eq(offset, expected)
      _ => fail("expected syntax error for \{source}")
    }
  }
}

///|
test "frontend semantics are validated by grammar constructor" {
  for
    source in [
      "", "# comment", "@start A;", "A -> B;", "A -> '';", "\"\" -> ;", "@start B; A -> ;",
      "A -> ['same'] | ['same'];", "A -> \"\";",
    ] {
    assert_true(parse_grammar(source) is Err(InvalidGrammar(_)))
  }
}

///|
test "frontend explicit budgets inclusive boundaries and independent counters" {
  let source = "A -> 'x';"
  assert_true(
    parse_grammar(source, limits=frontend_test_limits(9, 1, 1)) is Ok(_),
  )
  assert_true(
    parse_grammar(source, limits=frontend_test_limits(8, 1, 1))
    is Err(Limit("grammar_chars", 8)),
  )
  assert_true(
    parse_grammar("A -> |;", limits=frontend_test_limits(20, 1, 1))
    is Err(Limit("grammar_rules", 1)),
  )
  assert_true(
    parse_grammar("A -> 'x' 'y';", limits=frontend_test_limits(30, 1, 1))
    is Err(Limit("grammar_symbols", 1)),
  )
  assert_true(
    parse_grammar("A -> 'x' | 'y';", limits=frontend_test_limits(30, 2, 1))
    is Err(Limit("grammar_symbols", 1)),
  )
  assert_true(
    parse_grammar("A -> |;", limits=frontend_test_limits(7, 2, 1)) is Ok(_),
  )
  assert_true(
    parse_grammar("A -> '😀';", limits=frontend_test_limits(10, 1, 1))
    is Ok(_),
  )
  assert_true(
    parse_grammar("A -> '😀';", limits=frontend_test_limits(9, 1, 1))
    is Err(Limit("grammar_chars", 9)),
  )
  assert_true(
    parse_grammar("# oversized comment", limits=frontend_test_limits(1, 1, 1))
    is Err(Limit("grammar_chars", 1)),
  )
}

///|
test "frontend limit configurations fail before source processing" {
  for n in [-1, 0, 10000001] {
    assert_true(
      parse_grammar("?", limits=frontend_test_limits(n, 1, 1))
      is Err(InvalidLimit("max_chars")),
    )
    assert_true(
      parse_grammar("?", limits=frontend_test_limits(1, n, 1))
      is Err(InvalidLimit("max_rules")),
    )
    assert_true(
      parse_grammar("?", limits=frontend_test_limits(1, 1, n))
      is Err(InvalidLimit("max_symbols")),
    )
  }
  assert_eq(
    frontend_test_limits(10000000, 10000000, 10000000).validate(),
    Ok(()),
  )
  assert_eq(default_frontend_limits(), {
    max_chars: 65536,
    max_rules: 4096,
    max_symbols: 16384,
  })
}
