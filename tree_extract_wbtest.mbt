///|
fn tree_extract_test_forest(source : String, count : Int32) -> Forest {
  let grammar = parse_grammar(source).unwrap()
  let tokens : Array[Token] = []
  for i = 0; i < count; i = i + 1 {
    tokens.push(token("x", "x\{i}", i * 3, i * 3 + 2))
  }
  parse(grammar, tokens).unwrap().forest()
}

///|
fn tree_extract_test_limits(
  trees : Int32,
  depth : Int32,
  work : Int32,
) -> TreeLimits {
  { max_trees: trees, max_depth: depth, work_budget: work, }
}

///|
fn tree_extract_test_chain(count : Int32) -> Forest {
  let nodes : Array[Node] = []
  let rules : Array[Rule] = []
  for i = 0; i < count; i = i + 1 {
    let rhs = if i + 1 == count {
      [Terminal("x")]
    } else {
      [Nonterminal("N\{i + 1}")]
    }
    rules.push({ lhs: "N\{i}", rhs, label: "chain:\{i}", })
    nodes.push({
      kind: SymbolNode("N\{i}"),
      start: 0,
      end: 1,
      families: [{ rule: i, children: [i + 1], }],
    })
  }
  nodes.push({ kind: TokenLeaf(0), start: 0, end: 1, families: [], })
  { nodes, rules, tokens: [token("x", "x", 12, 14)], root: Some(0), }
}

///|
test "tree extraction epsilon is a real rule node with no artificial prefixes" {
  let f = tree_extract_test_forest("S -> ['epsilon'];", 0)
  let result = f.extract_trees().unwrap()
  assert_eq(result.tree_count(), 1)
  assert_true(!result.truncated())
  assert_eq(result.trees(), [
    RuleNode({
      label: "epsilon",
      rule: 0,
      span: { start: 0, end: 0, },
      children: [],
    }),
  ])
  assert_eq(result.trees()[0].metrics(), { size: 1, depth: 1, tokens: 0, })
  let two = tree_extract_test_forest("S -> ['e1'] | ['e2'];", 0)
    .extract_trees()
    .unwrap()
  assert_eq(two.trees().map(fn(t) { t.rule_labels() }), [["e1"], ["e2"]])
}

///|
test "tree extraction flattens intermediates and retains multi-token leaves" {
  let tokens = [
    token("id", "中文😀", 4, 9),
    token("plus", "+", 12, 13),
    token("id", "尾", 20, 21),
  ]
  let grammar = parse_grammar("S -> ['sum'] 'id' 'plus' 'id';").unwrap()
  let forest = parse(grammar, tokens).unwrap().forest()
  let result = extract_trees(forest).unwrap()
  assert_true(!result.truncated())
  let tree = result.trees()[0]
  assert_eq(tree.tokens(), tokens)
  assert_eq(tree.metrics(), { size: 4, depth: 2, tokens: 3, })
  assert_eq(tree.rule_labels(), ["sum"])
  assert_eq(tree.span(), { start: 0, end: 3, })
  match tree {
    RuleNode(node) => {
      assert_eq(node.children.length(), 3)
      assert_eq(node.children.map(fn(t) { t.span() }), [
        { start: 0, end: 1, },
        { start: 1, end: 2, },
        { start: 2, end: 3, },
      ])
    }
    _ => fail("expected a rule root")
  }
}

///|
test "tree extraction enumerates Catalan ambiguity deterministically" {
  for pair in [(1, 1), (2, 1), (3, 2), (4, 5), (5, 14), (6, 42)] {
    let (count, expected) = pair
    let forest = tree_extract_test_forest(
      "S -> ['split'] S S | ['leaf'] 'x';", count,
    )
    let limits = tree_extract_test_limits(100, 128, 1000000)
    let first = extract_trees(forest, limits~).unwrap()
    let second = extract_trees(forest, limits~).unwrap()
    assert_eq(first.tree_count(), expected)
    assert_true(!first.truncated())
    assert_eq(first.trees(), second.trees())
    assert_eq(first.work(), second.work())
    for tree in first.trees() {
      assert_eq(tree.tokens().length(), count)
      assert_eq(tree.size(), 3 * count - 1)
      assert_eq(tree.span(), { start: 0, end: count, })
    }
  }
}

///|
test "tree extraction sibling ambiguity forms the full ordered Cartesian product" {
  let f = tree_extract_test_forest(
    "S -> ['pair'] A A; A -> ['one'] 'x' | ['two'] 'x';", 2,
  )
  let result = f.extract_trees().unwrap()
  assert_eq(result.tree_count(), 4)
  assert_true(!result.truncated())
  assert_eq(result.trees().map(fn(t) { t.rule_labels() }), [
    ["pair", "one", "one"],
    ["pair", "one", "two"],
    ["pair", "two", "one"],
    ["pair", "two", "two"],
  ])
  for tree in result.trees() {
    assert_eq(tree.tokens().length(), 2)
  }
}

///|
test "tree extraction detects productive unit epsilon and indirect cycles on path" {
  for
    source in [
      "S -> ['cycle'] S | ['finite'] 'x';", "S -> ['to-a'] A; A -> ['back'] S | ['finite'] 'x';",
    ] {
    let result = tree_extract_test_forest(source, 1).extract_trees().unwrap()
    assert_eq(result.tree_count(), 1)
    assert_true(result.status().cycle_truncated)
    assert_true(result.truncated())
    assert_true(!result.status().tree_limit)
    assert_true(!result.status().work_limit)
    assert_eq(result.trees()[0].tokens(), [token("x", "x0", 0, 2)])
  }
  let epsilon = tree_extract_test_forest("S -> ['cycle'] S | ['empty'];", 0)
    .extract_trees()
    .unwrap()
  assert_eq(epsilon.tree_count(), 1)
  assert_eq(epsilon.trees()[0].rule_labels(), ["empty"])
  assert_true(epsilon.status().cycle_truncated)
}

///|
test "tree extraction explores finite families after a cycle-first family" {
  let f : Forest = {
    nodes: [
      {
        kind: SymbolNode("S"),
        start: 0,
        end: 1,
        families: [{ rule: 0, children: [1], }, { rule: 1, children: [2], }],
      },
      {
        kind: Intermediate(0, 1),
        start: 0,
        end: 1,
        families: [{ rule: 0, children: [0], }],
      },
      { kind: TokenLeaf(0), start: 0, end: 1, families: [], },
    ],
    rules: [
      { lhs: "S", rhs: [Nonterminal("S")], label: "cycle", },
      { lhs: "S", rhs: [Terminal("x")], label: "finite", },
    ],
    tokens: [token("x", "ok", 0, 2)],
    root: Some(0),
  }
  let result = f
    .extract_trees(limits=tree_extract_test_limits(1, 128, 1000))
    .unwrap()
  assert_eq(result.tree_count(), 1)
  assert_eq(result.trees()[0].rule_labels(), ["finite"])
  assert_true(result.status().cycle_truncated)
  assert_true(!result.status().tree_limit)
  let cyclic : Forest = { ..f, nodes: [f.nodes[0], f.nodes[1]], tokens: [], }
  cyclic.nodes[0].families.pop() |> ignore
  let only_cycle = cyclic.extract_trees().unwrap()
  assert_eq(only_cycle.tree_count(), 0)
  assert_true(only_cycle.status().cycle_truncated)
}

///|
test "tree extraction shares nullable siblings without falsely detecting cycles" {
  let result = tree_extract_test_forest(
      "S -> ['three'] A A A; A -> ['empty'];", 0,
    )
    .extract_trees()
    .unwrap()
  assert_eq(result.tree_count(), 1)
  assert_true(!result.truncated())
  assert_eq(result.trees()[0].rule_labels(), [
    "three", "empty", "empty", "empty",
  ])
  assert_eq(result.trees()[0].metrics(), { size: 4, depth: 2, tokens: 0, })
}

///|
test "tree extraction inclusive tree caps probe an extra tree without false completeness" {
  let f = tree_extract_test_forest("S -> ['a'] 'x' | ['b'] 'x' | ['c'] 'x';", 1)
  let all = f.extract_trees().unwrap().trees()
  for cap in [1, 2, 3, 4] {
    let result = f
      .extract_trees(limits=tree_extract_test_limits(cap, 128, 100000))
      .unwrap()
    let expected = if cap < 3 { cap } else { 3 }
    assert_eq(result.tree_count(), expected)
    assert_eq(result.status().tree_limit, cap < 3)
    assert_eq(result.truncated(), cap < 3)
    let trees = result.trees()
    for i = 0; i < trees.length(); i = i + 1 {
      assert_eq(trees[i], all[i])
    }
  }
}

///|
test "tree extraction charges Cartesian exploration and never hides work truncation" {
  let f = tree_extract_test_forest(
    "S -> ['pair'] A A; A -> ['one'] 'x' | ['two'] 'x';", 2,
  )
  let complete = f.extract_trees().unwrap()
  let all = complete.trees()
  let exact = f
    .extract_trees(limits=tree_extract_test_limits(64, 128, complete.work()))
    .unwrap()
  assert_true(!exact.truncated())
  assert_eq(exact.trees(), all)
  for budget in [1, 2, 5, 10, 25, 50, 100, complete.work() - 1] {
    let result = f
      .extract_trees(limits=tree_extract_test_limits(64, 128, budget))
      .unwrap()
    assert_true(result.status().work_limit)
    assert_true(result.truncated())
    assert_eq(result.work(), budget)
    let trees = result.trees()
    for i = 0; i < trees.length(); i = i + 1 {
      assert_eq(trees[i], all[i])
    }
  }
  let tiny = f
    .extract_trees(limits=tree_extract_test_limits(1, 128, 1))
    .unwrap()
  assert_eq(tiny.tree_count(), 0)
  assert_true(tiny.status().work_limit)
}

///|
test "tree extraction AST depth is inclusive and capped at 256" {
  let accepted = tree_extract_test_chain(127).extract_trees().unwrap()
  assert_eq(accepted.trees()[0].depth(), 128)
  assert_true(!accepted.truncated())
  let default_cut = tree_extract_test_chain(128).extract_trees().unwrap()
  assert_eq(default_cut.tree_count(), 0)
  assert_true(default_cut.status().depth_limit)
  let boundary = tree_extract_test_chain(255)
    .extract_trees(limits=tree_extract_test_limits(1, 256, 1000000))
    .unwrap()
  assert_eq(boundary.tree_count(), 1)
  assert_eq(boundary.trees()[0].depth(), 256)
  assert_true(!boundary.truncated())
  let cut = tree_extract_test_chain(256)
    .extract_trees(limits=tree_extract_test_limits(1, 256, 1000000))
    .unwrap()
  assert_eq(cut.tree_count(), 0)
  assert_true(cut.status().depth_limit)
  assert_true(!cut.status().work_limit)
  let epsilon = tree_extract_test_forest("S -> ;", 0)
    .extract_trees(limits=tree_extract_test_limits(1, 1, 1000))
    .unwrap()
  assert_eq(epsilon.tree_count(), 1)
  assert_true(!epsilon.truncated())
}

///|
test "tree extraction intermediate chains do not consume AST depth or native stack" {
  let rhs = StringBuilder()
  for i = 0; i < 300; i = i + 1 {
    rhs.write_string(" 'x'")
  }
  let source = "S -> ['long']\{rhs.to_string()};"
  let f = tree_extract_test_forest(source, 300)
  let result = f
    .extract_trees(limits=tree_extract_test_limits(1, 2, 1000000))
    .unwrap()
  assert_true(!result.truncated())
  assert_eq(result.tree_count(), 1)
  assert_eq(result.trees()[0].metrics(), { size: 301, depth: 2, tokens: 300, })
  assert_eq(result.trees()[0].rule_labels(), ["long"])
}

///|
test "tree extraction depth-skipped alternatives do not hide shallower finite trees" {
  let f = tree_extract_test_forest(
    "S -> ['deep'] A | ['shallow'] 'x'; A -> ['a'] B; B -> ['b'] 'x';", 1,
  )
  let result = f
    .extract_trees(limits=tree_extract_test_limits(10, 2, 10000))
    .unwrap()
  assert_eq(result.tree_count(), 1)
  assert_eq(result.trees()[0].rule_labels(), ["shallow"])
  assert_true(result.status().depth_limit)
  assert_true(!result.status().tree_limit)
}

///|
test "tree extraction report and tree snapshots isolate nested arrays" {
  let g = parse_grammar("S -> ['pair'] A A; A -> ['one'] 'x' | ['two'] 'x';").unwrap()
  let input = [token("x", "first", 0, 5), token("x", "second", 7, 13)]
  let forest = parse(g, input).unwrap().forest()
  input.clear()
  let result = forest.extract_trees().unwrap()
  let baseline = result.trees()
  let exposed = result.trees()
  match exposed[0] {
    RuleNode(root) => {
      match root.children[0] {
        RuleNode(child) => child.children.clear()
        _ => fail("expected child rule")
      }
      assert_eq(exposed[1].tokens().length(), 2)
      root.children.clear()
    }
    _ => fail("expected root rule")
  }
  exposed.clear()
  assert_eq(result.trees(), baseline)
  assert_eq(result.tree_count(), 4)
  forest.node(forest.root().unwrap()).unwrap().alternatives.clear()
  assert_eq(forest.extract_trees().unwrap().trees(), baseline)
  assert_eq(baseline[0].tokens(), [
    token("x", "first", 0, 5),
    token("x", "second", 7, 13),
  ])
}

///|
test "tree extraction rejection returns a complete empty report" {
  let f = tree_extract_test_forest("S -> 'x';", 0)
  assert_true(f.root() is None)
  let result = f
    .extract_trees(limits=tree_extract_test_limits(1, 1, 1))
    .unwrap()
  assert_eq(result.tree_count(), 0)
  assert_eq(result.work(), 0)
  assert_true(!result.truncated())
}

///|
test "tree extraction validates all budget boundaries before reading forest" {
  let f = tree_extract_test_forest("S -> ;", 0)
  for n in [-1, 0, 100001] {
    assert_true(
      f.extract_trees(limits=tree_extract_test_limits(n, 1, 1))
      is Err(InvalidLimit("max_trees")),
    )
  }
  for n in [-1, 0, 257] {
    assert_true(
      f.extract_trees(limits=tree_extract_test_limits(1, n, 1))
      is Err(InvalidLimit("max_depth")),
    )
  }
  for n in [-1, 0, 10000001] {
    assert_true(
      f.extract_trees(limits=tree_extract_test_limits(1, 1, n))
      is Err(InvalidLimit("work_budget")),
    )
  }
  assert_eq(tree_extract_test_limits(100000, 256, 10000000).validate(), Ok(()))
  assert_eq(default_tree_limits(), {
    max_trees: 64,
    max_depth: 128,
    work_budget: 100000,
  })
}

///|
test "tree extraction checks inconsistent internal references without panicking" {
  let f = tree_extract_test_chain(1)
  assert_true(extract_trees({ ..f, root: Some(-1), }) is Err(InvalidNode(-1)))
  assert_true(extract_trees({ ..f, root: Some(999), }) is Err(InvalidNode(999)))
  let bad_child : Forest = {
    ..f,
    nodes: [
      { ..f.nodes[0], families: [{ rule: 0, children: [999], }], },
      f.nodes[1],
    ],
  }
  assert_true(bad_child.extract_trees() is Err(InvalidNode(999)))
  let bad_rule : Forest = {
    ..f,
    nodes: [
      { ..f.nodes[0], families: [{ rule: 999, children: [1], }], },
      f.nodes[1],
    ],
  }
  assert_true(bad_rule.extract_trees() is Err(InvalidGrammar(_)))
  assert_true(extract_trees({ ..f, tokens: [], }) is Err(InvalidToken(0, _)))
}
