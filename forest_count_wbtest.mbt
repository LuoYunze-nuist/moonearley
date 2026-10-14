///|
fn forest_count_test_node(name : String, families : Array[Family]) -> Node {
  { kind: SymbolNode(name), start: 0, end: 0, families, }
}

///|
fn forest_count_test_forest(nodes : Array[Node], root : Int?) -> Forest {
  { nodes, tokens: [], rules: [], root, }
}

///|
fn forest_count_test_parse(
  rules : Array[Rule],
  kinds : Array[String],
) -> Forest {
  let grammar = Grammar::new("S", rules).unwrap()
  let tokens = kinds.mapi(fn(i, kind) { token(kind, kind, i, i + 1) })
  parse(grammar, tokens).unwrap().forest()
}

///|
test "count token epsilon missing root and no-family nodes" {
  let leaf = forest_count_test_forest(
    [{ kind: TokenLeaf(0), start: 0, end: 1, families: [], }],
    Some(0),
  )
  assert_eq(leaf.count(), Ok(Finite(1)))
  let empty = forest_count_test_forest(
    [forest_count_test_node("S", [{ rule: 0, children: [], }])],
    Some(0),
  )
  assert_eq(empty.count(), Ok(Finite(1)))
  assert_eq(forest_count_test_forest([], None).count(), Ok(Finite(0)))
  let dead = forest_count_test_forest(
    [forest_count_test_node("Dead", [])],
    Some(0),
  )
  assert_eq(dead.count(), Ok(Finite(0)))
}

///|
test "count real Catalan forests exact cap and saturated cap" {
  let rules = [
    { lhs: "S", rhs: [Nonterminal("S"), Nonterminal("S")], label: "pair", },
    { lhs: "S", rhs: [Terminal("x")], label: "x", },
  ]
  for n, expected in [1, 1, 2, 5, 14, 42, 132] {
    let forest = forest_count_test_parse(rules, Array::make(n + 1, "x"))
    assert_eq(forest.count(), Ok(Finite(expected)))
    assert_eq(forest.count(cap=expected), Ok(Finite(expected)))
    if expected > 1 {
      assert_eq(forest.count(cap=expected - 1), Ok(AtLeast(expected - 1)))
    }
  }
  let rejected = forest_count_test_parse(rules, [])
  assert_eq(rejected.count(), Ok(Finite(0)))
}

///|
test "count independently labeled duplicate terminal and epsilon expansions" {
  let terminal = forest_count_test_parse(
    [
      { lhs: "S", rhs: [Terminal("x")], label: "one", },
      { lhs: "S", rhs: [Terminal("x")], label: "two", },
      { lhs: "S", rhs: [Terminal("x")], label: "three", },
    ],
    ["x"],
  )
  assert_eq(terminal.count(), Ok(Finite(3)))
  assert_eq(terminal.count(cap=3), Ok(Finite(3)))
  assert_eq(terminal.count(cap=2), Ok(AtLeast(2)))
  let epsilon = forest_count_test_parse(
    [{ lhs: "S", rhs: [], label: "one", }, { lhs: "S", rhs: [], label: "two", }],
    [],
  )
  assert_eq(epsilon.count(), Ok(Finite(2)))
  assert_eq(epsilon.count(cap=1), Ok(AtLeast(1)))
}

///|
test "count actual productive epsilon and unit cycles are infinite" {
  let epsilon = forest_count_test_parse(
    [
      { lhs: "S", rhs: [Nonterminal("S")], label: "cycle", },
      { lhs: "S", rhs: [], label: "exit", },
    ],
    [],
  )
  assert_eq(epsilon.count(), Ok(Infinite))
  assert_eq(epsilon.count(cap=1), Ok(Infinite))
  let unit = forest_count_test_parse(
    [
      { lhs: "S", rhs: [Nonterminal("A")], label: "s", },
      { lhs: "A", rhs: [Nonterminal("S")], label: "back", },
      { lhs: "A", rhs: [Terminal("x")], label: "exit", },
    ],
    ["x"],
  )
  assert_eq(unit.count(), Ok(Infinite))
  let branch = forest_count_test_parse(
    [
      { lhs: "S", rhs: [Nonterminal("S"), Nonterminal("S")], label: "branch", },
      { lhs: "S", rhs: [], label: "exit", },
    ],
    [],
  )
  assert_eq(branch.count(), Ok(Infinite))
}

///|
test "count dead cycle and unproductive AND alternative never imply infinity" {
  let dead_cycle = forest_count_test_forest(
    [
      forest_count_test_node("A", [{ rule: 0, children: [1], }]),
      forest_count_test_node("B", [{ rule: 1, children: [0], }]),
    ],
    Some(0),
  )
  assert_eq(dead_cycle.count(), Ok(Finite(0)))
  let blocked = forest_count_test_forest(
    [
      forest_count_test_node("S", [
        { rule: 0, children: [], },
        { rule: 1, children: [0, 1], },
      ]),
      forest_count_test_node("Dead", [{ rule: 2, children: [1], }]),
    ],
    Some(0),
  )
  assert_eq(blocked.count(), Ok(Finite(1)))
  let productive_cycle_with_blocked_parent = forest_count_test_forest(
    [
      forest_count_test_node("S", [
        { rule: 0, children: [], },
        { rule: 1, children: [1, 2], },
      ]),
      forest_count_test_node("Loop", [
        { rule: 2, children: [], },
        { rule: 3, children: [1], },
      ]),
      forest_count_test_node("Dead", []),
    ],
    Some(0),
  )
  assert_eq(productive_cycle_with_blocked_parent.count(), Ok(Finite(1)))
}

///|
test "count unreachable productive cycles do not contaminate root" {
  let forest = forest_count_test_forest(
    [
      forest_count_test_node("S", [{ rule: 0, children: [], }]),
      forest_count_test_node("Unused", [
        { rule: 1, children: [], },
        { rule: 2, children: [1], },
      ]),
    ],
    Some(0),
  )
  assert_eq(forest.count(), Ok(Finite(1)))
  assert_eq(forest_count_test_forest(forest.nodes, None).count(), Ok(Finite(0)))
}

///|
test "count repeated children multiply independent derivations and shared DAGs do not cycle" {
  let forest = forest_count_test_forest(
    [
      forest_count_test_node("S", [{ rule: 0, children: [1, 1, 2], }]),
      forest_count_test_node("A", [
        { rule: 1, children: [], },
        { rule: 2, children: [], },
      ]),
      {
        kind: Intermediate(0, 1),
        start: 0,
        end: 0,
        families: [{ rule: 0, children: [1], }],
      },
    ],
    Some(0),
  )
  assert_eq(forest.count(), Ok(Finite(8)))
  assert_eq(forest.count(cap=8), Ok(Finite(8)))
  assert_eq(forest.count(cap=7), Ok(AtLeast(7)))
}

///|
test "count saturated addition and multiplication do not overflow maximal Int" {
  let nodes : Array[Node] = [
    forest_count_test_node("Base", [
      { rule: 0, children: [], },
      { rule: 1, children: [], },
    ]),
  ]
  for i in 1..<8 {
    nodes.push(
      forest_count_test_node("N\{i}", [{ rule: i, children: [i - 1, i - 1], }]),
    )
  }
  let huge = forest_count_test_forest(nodes, Some(7))
  assert_eq(huge.count(cap=2147483647), Ok(AtLeast(2147483647)))
  assert_eq(huge.count(cap=1000), Ok(AtLeast(1000)))
  let exact = forest_count_test_forest(
    [forest_count_test_node("S", [{ rule: 0, children: [], }])],
    Some(0),
  )
  assert_eq(exact.count(cap=2147483647), Ok(Finite(1)))
  let max : ForestCappedCount = { value: 2147483647, clipped: false, }
  let one : ForestCappedCount = { value: 1, clipped: false, }
  let zero : ForestCappedCount = { value: 0, clipped: false, }
  assert_eq(forest_count_add(max, zero, 2147483647).value, 2147483647)
  assert_true(!forest_count_add(max, zero, 2147483647).clipped)
  assert_true(forest_count_add(max, one, 2147483647).clipped)
  assert_true(!forest_count_multiply(max, one, 2147483647).clipped)
  assert_eq(
    forest_count_multiply({ ..max, clipped: true, }, zero, 2147483647).value,
    0,
  )
  assert_true(
    !forest_count_multiply({ ..max, clipped: true, }, zero, 2147483647).clipped,
  )
}

///|
test "count validates limits before rejection and propagates work exhaustion" {
  let absent = forest_count_test_forest([], None)
  for limit in [0, -1, -2147483647] {
    assert_eq(absent.count(cap=limit), Err(InvalidLimit("cap")))
    assert_eq(absent.count(work_limit=limit), Err(InvalidLimit("work_limit")))
  }
  let forest = forest_count_test_forest(
    [forest_count_test_node("S", [{ rule: 0, children: [], }])],
    Some(0),
  )
  assert_eq(forest.count(work_limit=1), Err(Limit("count_work", 1)))
  let mut minimum = 1
  while forest.count(work_limit=minimum) is Err(Limit(_, _)) {
    minimum += 1
  }
  assert_eq(forest.count(work_limit=minimum), Ok(Finite(1)))
  assert_eq(
    forest.count(work_limit=minimum - 1),
    Err(Limit("count_work", minimum - 1)),
  )
  assert_eq(forest.count(), Ok(Finite(1)))
}

///|
test "count rejects dangling reachable references rather than indexing out of bounds" {
  assert_eq(forest_count_test_forest([], Some(0)).count(), Err(InvalidNode(0)))
  assert_eq(
    forest_count_test_forest([], Some(-1)).count(),
    Err(InvalidNode(-1)),
  )
  let forest = forest_count_test_forest(
    [forest_count_test_node("S", [{ rule: 0, children: [99], }])],
    Some(0),
  )
  assert_eq(forest.count(), Err(InvalidNode(99)))
}

///|
test "count long reverse chain reaches fixed point without recursion" {
  let nodes : Array[Node] = []
  for i in 0..<90 {
    nodes.push(
      forest_count_test_node("N\{i}", [{ rule: i, children: [i + 1], }]),
    )
  }
  nodes.push(forest_count_test_node("Exit", [{ rule: 90, children: [], }]))
  let forest = forest_count_test_forest(nodes, Some(0))
  assert_eq(forest.count(work_limit=100000), Ok(Finite(1)))
  assert_eq(forest.count(work_limit=50), Err(Limit("count_work", 50)))
}
