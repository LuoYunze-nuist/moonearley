///|
fn main raise {
  let grammar = @moonearley.parse_grammar(
    "S -> ['entry'] A; A -> ['loop'] A | ['empty']; Dead -> ['dead'] 'x';",
  ).unwrap()
  assert_eq(grammar.nullable(), ["A", "S"])
  println("nullable nonterminals: \{grammar.nullable().join(",")}")
  for finding in grammar.lint() {
    println("warning: \{finding.message}")
  }
  let report = @moonearley.parse(grammar, []).unwrap()
  assert_true(report.accepted())
  assert_eq(report.forest().count().unwrap(), @moonearley.Infinite)
  let extracted = report.forest().extract_trees().unwrap()
  assert_eq(extracted.tree_count(), 1)
  assert_true(extracted.status().cycle_truncated)
  println("productive unit cycle: infinitely many finite derivations")
  println(
    "bounded extraction retained \{extracted.tree_count()} cycle-free tree; cycle truncation is explicit",
  )
  assert_true(report.forest().reachable_nodes().unwrap().length() > 0)
  println(report.forest().to_dot().unwrap())
}
