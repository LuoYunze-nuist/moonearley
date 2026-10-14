///|
/// The interpreter is downstream application logic, not a semantic-action engine.
fn evaluate(tree : @moonearley.Tree) -> Int raise {
  match tree {
    TokenNode(leaf) => @string.parse_int(leaf.token.text[:])
    RuleNode(node) =>
      match node.label {
        "number" => evaluate(node.children[0])
        "add" => evaluate(node.children[0]) + evaluate(node.children[2])
        "mul" => evaluate(node.children[0]) * evaluate(node.children[2])
        _ => abort("unexpected production in this example")
      }
  }
}

///|
fn main raise {
  let grammar = @moonearley.parse_grammar(
    "E -> ['add'] E '+' E | ['mul'] E '*' E | ['number'] 'n';",
  ).unwrap()
  let report = @moonearley.parse(grammar, [
    @moonearley.token("n", "1", 0, 1),
    @moonearley.token("+", "+", 1, 2),
    @moonearley.token("n", "2", 2, 3),
    @moonearley.token("*", "*", 3, 4),
    @moonearley.token("n", "3", 4, 5),
  ]).unwrap()
  assert_true(report.accepted())
  assert_eq(report.forest().count().unwrap(), @moonearley.Finite(2))
  let extraction = report.forest().extract_trees().unwrap()
  assert_true(!extraction.truncated())
  let values = extraction.trees().map(evaluate)
  values.sort()
  assert_eq(values, [7, 9])
  for value in values {
    println("a valid interpretation of 1+2*3: \{value}")
  }
  println(
    "The application can select precedence; the library did not discard alternatives.",
  )
}
