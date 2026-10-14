///|
fn forest_query_test_fixture() -> Forest {
  {
    nodes: [
      {
        kind: SymbolNode("S"),
        start: 0,
        end: 2,
        families: [{ rule: 0, children: [1, 2], }],
      },
      { kind: TokenLeaf(0), start: 0, end: 1, families: [], },
      {
        kind: SymbolNode("A"),
        start: 1,
        end: 2,
        families: [{ rule: 1, children: [3], }, { rule: 2, children: [3], }],
      },
      { kind: TokenLeaf(1), start: 1, end: 2, families: [], },
      {
        kind: SymbolNode("A"),
        start: 2,
        end: 2,
        families: [{ rule: 3, children: [], }],
      },
      {
        kind: Intermediate(0, 1),
        start: 0,
        end: 1,
        families: [{ rule: 0, children: [1], }],
      },
      {
        kind: SymbolNode("Dead"),
        start: 0,
        end: 0,
        families: [{ rule: 4, children: [6], }],
      },
    ],
    tokens: [token("x", "a", 10, 20), token("y", "b", 25, 40)],
    rules: [
      { lhs: "S", rhs: [Terminal("x"), Nonterminal("A")], label: "pair", },
      { lhs: "A", rhs: [Terminal("y")], label: "one", },
      { lhs: "A", rhs: [Terminal("y")], label: "two", },
      { lhs: "A", rhs: [], label: "empty", },
      { lhs: "Dead", rhs: [Nonterminal("Dead")], label: "loop", },
    ],
    root: Some(0),
  }
}

///|
test "query kind symbol and exact token spans including epsilon endpoint" {
  let f = forest_query_test_fixture()
  assert_eq(f.symbol_nodes("A"), [2, 4])
  assert_eq(f.symbol_nodes("missing"), [])
  assert_eq(f.symbol_nodes(""), [])
  assert_eq(f.nodes_of_kind(TokenLeaf(0)), [1])
  assert_eq(f.nodes_of_kind(Intermediate(0, 1)), [5])
  assert_eq(f.nodes_of_kind(Intermediate(0, 2)), [])
  assert_eq(f.nodes_at_span(0, 1), Ok([1, 5]))
  assert_eq(f.nodes_at_span(1, 2), Ok([2, 3]))
  assert_eq(f.nodes_at_span(2, 2), Ok([4]))
  assert_eq(f.nodes_at_span(1, 1), Ok([]))
  assert_eq(f.symbol_nodes_at("A", 1, 2), Ok([2]))
  assert_eq(f.symbol_nodes_at("A", 2, 2), Ok([4]))
  assert_eq(f.symbol_nodes_at("S", 1, 2), Ok([]))
  for span in [(-1, 0), (2, 1), (0, 3), (3, 3)] {
    let (start, end) = span
    assert_true(f.nodes_at_span(start, end) is Err(Syntax(_, _)))
    assert_true(f.symbol_nodes_at("A", start, end) is Err(Syntax(_, _)))
  }
  assert_true(f.nodes_at_span(10, 20) is Err(Syntax(_, _)))
}

///|
test "query returned ID arrays are independent across calls" {
  let f = forest_query_test_fixture()
  let ids = f.symbol_nodes("A")
  ids.clear()
  let spans = f.nodes_at_span(1, 2).unwrap()
  spans[0] = 999
  let reachable = f.reachable_nodes().unwrap()
  reachable.clear()
  let productive = f.productive_nodes().unwrap()
  productive.clear()
  let ambiguous = f.ambiguity_nodes().unwrap()
  ambiguous.clear()
  assert_eq(f.symbol_nodes("A"), [2, 4])
  assert_eq(f.nodes_at_span(1, 2), Ok([2, 3]))
  assert_eq(f.reachable_nodes(), Ok([0, 1, 2, 3]))
  assert_eq(f.productive_nodes(), Ok([0, 1, 2, 3, 4, 5]))
  assert_eq(f.ambiguity_nodes(), Ok([2]))
}

///|
test "query reachable queue deduplicates shared nodes and terminates on cycles" {
  let f = forest_query_test_fixture()
  assert_eq(f.reachable_nodes(), Ok([0, 1, 2, 3]))
  assert_eq(f.reachable_from(5), Ok([1, 5]))
  assert_eq(f.reachable_from(6), Ok([6]))
  assert_eq(f.reachable_from(-1), Err(InvalidNode(-1)))
  assert_eq(f.reachable_from(7), Err(InvalidNode(7)))
  let rejected : Forest = { ..f, root: None, }
  assert_eq(rejected.reachable_nodes(), Ok([]))
  assert_eq(rejected.ambiguity_nodes(), Ok([]))
  assert_eq(rejected.ambiguity_nodes(reachable_only=false), Ok([2]))
  assert_eq(rejected.reachable_from(0), f.reachable_nodes())
}

///|
test "query local ambiguity ignores unproductive alternatives and blocked paths" {
  let f = forest_count_test_forest(
    [
      forest_count_test_node("S", [
        { rule: 0, children: [1], },
        { rule: 1, children: [2, 3], },
      ]),
      forest_count_test_node("A", [{ rule: 2, children: [], }]),
      forest_count_test_node("Hidden", [
        { rule: 3, children: [], },
        { rule: 4, children: [], },
      ]),
      forest_count_test_node("Dead", [{ rule: 5, children: [3], }]),
    ],
    Some(0),
  )
  assert_eq(f.reachable_nodes(), Ok([0, 1, 2, 3]))
  assert_eq(f.productive_nodes(), Ok([0, 1, 2]))
  assert_eq(f.ambiguity_nodes(), Ok([]))
  assert_eq(f.ambiguity_nodes(reachable_only=false), Ok([2]))
  assert_eq(f.count(), Ok(Finite(1)))
}

///|
test "query productive cycles have viable local ambiguity but pure cycles do not" {
  let f = forest_count_test_forest(
    [
      forest_count_test_node("S", [{ rule: 0, children: [1], }]),
      forest_count_test_node("A", [
        { rule: 1, children: [0], },
        { rule: 2, children: [], },
      ]),
      forest_count_test_node("Dead", [
        { rule: 3, children: [2], },
        { rule: 4, children: [2], },
      ]),
    ],
    Some(0),
  )
  assert_eq(f.productive_nodes(), Ok([0, 1]))
  assert_eq(f.ambiguity_nodes(), Ok([1]))
  assert_eq(f.ambiguity_nodes(reachable_only=false), Ok([1]))
  assert_eq(f.count(), Ok(Infinite))
}

///|
test "query DOT exact small forest shows empty family and marks accepted root" {
  let f : Forest = {
    nodes: [
      {
        kind: SymbolNode("S"),
        start: 0,
        end: 0,
        families: [{ rule: 0, children: [], }],
      },
    ],
    rules: [{ lhs: "S", rhs: [], label: "empty", }],
    tokens: [],
    root: Some(0),
  }
  assert_eq(
    f.to_dot(),
    Ok(
      "digraph Forest {\n  rankdir=LR;\n  n0 [shape=ellipse, peripheries=2, label=\"S [0,0)\"];\n  f0_0 [shape=box, label=\"#0: empty\"];\n  n0 -> f0_0;\n}\n",
    ),
  )
  assert_eq(
    ({ ..f, root: None, } : Forest).to_dot(),
    Ok("digraph Forest {\n  rankdir=LR;\n}\n"),
  )
  assert_true(
    ({ ..f, root: None, } : Forest)
    .to_dot(reachable_only=false)
    .unwrap()
    .contains("n0 ["),
  )
}

///|
test "query DOT preserves packed AND OR structure child positions and intermediate tags" {
  let f = forest_query_test_fixture()
  let dot = f.to_dot().unwrap()
  assert_true(dot.contains("f0_0 -> n1 [label=\"0\"]"))
  assert_true(dot.contains("f0_0 -> n2 [label=\"1\"]"))
  assert_true(dot.contains("f2_0 [shape=box, label=\"#1: one\"]"))
  assert_true(dot.contains("f2_1 [shape=box, label=\"#2: two\"]"))
  assert_true(dot.contains("token #0 x: a [0,1)"))
  assert_true(!dot.contains("n4 ["))
  assert_true(!dot.contains("n6 ["))
  let all = f.to_dot(reachable_only=false).unwrap()
  assert_true(all.contains("prefix #0 pair ·1 [0,1)"))
  assert_true(all.contains("f6_0 -> n6 [label=\"0\"]"))
  assert_eq(f.to_dot(), Ok(dot))
  let repeated : Forest = {
    ..f,
    nodes: [
      {
        kind: SymbolNode("S"),
        start: 0,
        end: 1,
        families: [{ rule: 0, children: [1, 1], }],
      },
      f.nodes[1],
    ],
  }
  let repeats = repeated.to_dot().unwrap()
  assert_true(repeats.contains("f0_0 -> n1 [label=\"0\"]"))
  assert_true(repeats.contains("f0_0 -> n1 [label=\"1\"]"))
}

///|
test "query DOT escapes quotes slashes controls and injection in every user label" {
  let hostile = "\"\\N\n\r\t<>;&汉😀\u{001b}"
  let f : Forest = {
    nodes: [
      {
        kind: SymbolNode(hostile),
        start: 0,
        end: 1,
        families: [{ rule: 0, children: [1], }],
      },
      { kind: TokenLeaf(0), start: 0, end: 1, families: [], },
    ],
    rules: [{ lhs: hostile, rhs: [Terminal(hostile)], label: hostile, }],
    tokens: [token(hostile, hostile, 0, 1)],
    root: Some(0),
  }
  let dot = f.to_dot().unwrap()
  let escaped = "\\\"\\\\N\\n\\r\\t<>;&汉😀\\\\control(27)"
  assert_true(dot.contains("label=\"\{escaped} [0,1)\""))
  assert_true(dot.contains("label=\"#0: \{escaped}\""))
  assert_true(dot.contains("token #0 \{escaped}: \{escaped} [0,1)"))
  assert_true(!dot.contains("\u{001b}"))
  assert_true(!dot.contains("\r"))
  assert_true(!dot.contains("\t"))
  let injection = "\"]; evil -> root; //"
  let injected : Forest = {
    ..f,
    rules: [{ lhs: "S", rhs: [], label: injection, }],
  }
  assert_true(
    injected.to_dot().unwrap().contains("#0: \\\"]; evil -> root; //"),
  )
}

///|
test "query budgets validate all traversal exports and exhaust cumulatively" {
  let f = forest_query_test_fixture()
  for limit in [0, -1] {
    assert_eq(
      f.reachable_nodes(work_limit=limit),
      Err(InvalidLimit("work_limit")),
    )
    assert_eq(
      f.reachable_from(0, work_limit=limit),
      Err(InvalidLimit("work_limit")),
    )
    assert_eq(
      f.productive_nodes(work_limit=limit),
      Err(InvalidLimit("work_limit")),
    )
    assert_eq(
      f.ambiguity_nodes(work_limit=limit),
      Err(InvalidLimit("work_limit")),
    )
    assert_eq(f.to_dot(work_limit=limit), Err(InvalidLimit("work_limit")))
  }
  assert_eq(f.reachable_nodes(work_limit=1), Err(Limit("query_work", 1)))
  assert_eq(f.productive_nodes(work_limit=1), Err(Limit("query_work", 1)))
  assert_eq(f.ambiguity_nodes(work_limit=1), Err(Limit("query_work", 1)))
  assert_eq(f.to_dot(work_limit=1), Err(Limit("query_work", 1)))
  let mut minimum = 1
  while f.to_dot(work_limit=minimum) is Err(Limit(_, _)) {
    minimum += 1
  }
  assert_eq(f.to_dot(work_limit=minimum), f.to_dot())
  assert_eq(
    f.to_dot(work_limit=minimum - 1),
    Err(Limit("query_work", minimum - 1)),
  )
}

///|
test "query invalid roots children tokens and rule tags are diagnosed" {
  let f = forest_query_test_fixture()
  assert_eq(
    ({ ..f, root: Some(99), } : Forest).reachable_nodes(),
    Err(InvalidNode(99)),
  )
  let broken : Forest = {
    ..f,
    nodes: [
      {
        kind: SymbolNode("S"),
        start: 0,
        end: 1,
        families: [{ rule: 0, children: [99], }],
      },
    ],
  }
  assert_eq(broken.reachable_nodes(), Err(InvalidNode(99)))
  assert_eq(broken.to_dot(reachable_only=false), Err(InvalidNode(99)))
  let bad_rule : Forest = { ..f, rules: [], }
  assert_true(bad_rule.to_dot() is Err(InvalidGrammar(_)))
  let bad_token : Forest = { ..f, tokens: [], }
  assert_true(bad_token.to_dot() is Err(InvalidToken(0, _)))
  let bad_prefix : Forest = {
    ..f,
    nodes: [{ kind: Intermediate(-1, 0), start: 0, end: 0, families: [], }],
  }
  assert_true(bad_prefix.to_dot() is Err(InvalidGrammar(_)))
}

///|
test "query actual parser forests expose symbols ambiguity and DOT without unfolding" {
  let f = forest_count_test_parse(
    [
      { lhs: "S", rhs: [Nonterminal("S"), Nonterminal("S")], label: "pair", },
      { lhs: "S", rhs: [Terminal("x")], label: "leaf", },
    ],
    ["x", "x", "x"],
  )
  let roots = f.symbol_nodes_at("S", 0, 3).unwrap()
  assert_eq(roots, [f.root().unwrap()])
  let ambiguous = f.ambiguity_nodes().unwrap()
  assert_true(!ambiguous.is_empty())
  for id in ambiguous {
    assert_true(f.node(id).unwrap().alternatives.length() >= 2)
  }
  assert_eq(f.count(), Ok(Finite(2)))
  assert_true(f.to_dot().unwrap().contains("#0: pair"))
  assert_true(f.reachable_nodes().unwrap().contains(f.root().unwrap()))
}
