///|
fn main raise {
  let grammar = @moonearley.parse_grammar("S -> 'let' 'name' '=' 'number' ';';").unwrap()
  let session = @moonearley.Session::new(grammar).unwrap()
  println("initial expected: \{session.report().expected().join(",")}")
  let prefix = session
    .push_all([
      @moonearley.token("let", "let", 0, 3),
      @moonearley.token("name", "answer", 4, 10),
    ])
    .unwrap()
  println("after declaration name: \{prefix.expected().join(",")}")
  let branch = session.fork()
  let bad = branch.push(@moonearley.token("number", "42", 11, 13)).unwrap()
  let diagnostic = bad.diagnostic().unwrap()
  assert_eq(diagnostic.token_index, 2)
  assert_eq(diagnostic.char_start, 11)
  assert_eq(diagnostic.expected_kinds, ["="])
  println(
    "rejected kind at offset \{diagnostic.char_start}; expected \{diagnostic.expected_kinds.join(",")}",
  )
  let complete = session
    .push_all([
      @moonearley.token("=", "=", 11, 12),
      @moonearley.token("number", "42", 13, 15),
      @moonearley.token(";", ";", 15, 16),
    ])
    .unwrap()
  assert_true(complete.accepted())
  assert_true(!prefix.accepted())
  println(
    "original branch accepted: \{complete.accepted()}; old snapshot accepted: \{prefix.accepted()}",
  )
}
