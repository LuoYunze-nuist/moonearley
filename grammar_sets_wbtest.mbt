///|
fn grammar_test_expression() -> Grammar {
  Grammar::new("E", [
    grammar_test_rule("E", [Nonterminal("T"), Nonterminal("Erest")], "e"),
    grammar_test_rule("Erest", [Terminal("+"), Nonterminal("T"), Nonterminal("Erest")], "plus"),
    grammar_test_rule("Erest", [], "end_e"),
    grammar_test_rule("T", [Nonterminal("F"), Nonterminal("Trest")], "t"),
    grammar_test_rule("Trest", [Terminal("*"), Nonterminal("F"), Nonterminal("Trest")], "times"),
    grammar_test_rule("Trest", [], "end_t"),
    grammar_test_rule("F", [Terminal("("), Nonterminal("E"), Terminal(")")], "paren"),
    grammar_test_rule("F", [Terminal("id")], "id"),
  ]).unwrap()
}

///|
test "FIRST FOLLOW expression grammar nullable tails and nested start" {
  let g = grammar_test_expression()
  let sets = g.sets()
  assert_eq(sets.nonterminals(), ["E", "Erest", "F", "T", "Trest"])
  for name in ["E", "F", "T"] {
    let first = sets.first(name).unwrap()
    assert_eq(first.terminals(), ["(", "id"])
    assert_true(!first.is_nullable())
  }
  assert_eq(sets.first("Erest").unwrap().terminals(), ["+"])
  assert_true(sets.first("Erest").unwrap().is_nullable())
  assert_eq(sets.first("Trest").unwrap().terminals(), ["*"])
  assert_true(sets.first("Trest").unwrap().is_nullable())
  assert_eq(sets.follow("E").unwrap().terminals(), [")"])
  assert_eq(sets.follow("Erest").unwrap().terminals(), [")"])
  assert_eq(sets.follow("T").unwrap().terminals(), [")", "+"])
  assert_eq(sets.follow("Trest").unwrap().terminals(), [")", "+"])
  assert_eq(sets.follow("F").unwrap().terminals(), [")", "*", "+"])
  for name in sets.nonterminals() {
    assert_true(sets.follow(name).unwrap().includes_eof())
    assert_eq(g.first(name), sets.first(name))
    assert_eq(g.follow(name), sets.follow(name))
  }
}

///|
test "sequence FIRST crosses only nullable prefixes and has independent epsilon" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("A"), Nonterminal("B"), Terminal("z")], "s"),
    grammar_test_rule("A", [Terminal("a")], "a"),
    grammar_test_rule("A", [], "ae"),
    grammar_test_rule("B", [Terminal("b")], "b"),
    grammar_test_rule("B", [], "be"),
    grammar_test_rule("Dead", [Nonterminal("Dead")], "dead"),
  ]).unwrap()
  let sets = g.sets()
  assert_eq(sets.first("S").unwrap().terminals(), ["a", "b", "z"])
  assert_true(!sets.first("S").unwrap().is_nullable())
  let sequence = [Nonterminal("A"), Nonterminal("B")]
  let first = sets.first_sequence(sequence).unwrap()
  assert_eq(first.terminals(), ["a", "b"])
  assert_true(first.is_nullable())
  assert_eq(g.first_sequence(sequence), sets.first_sequence(sequence))
  let empty = sets.first_sequence([]).unwrap()
  assert_eq(empty.terminals(), [])
  assert_true(empty.is_nullable())
  let blocked = sets.first_sequence([Nonterminal("Dead"), Terminal("never")]).unwrap()
  assert_eq(blocked.terminals(), [])
  assert_true(!blocked.is_nullable())
  assert_eq(sets.first_sequence([Terminal("new"), Nonterminal("A")]).unwrap().terminals(), ["new"])
  assert_eq(sets.follow("A").unwrap().terminals(), ["b", "z"])
  assert_eq(sets.follow("B").unwrap().terminals(), ["z"])
  assert_true(!sets.follow("A").unwrap().includes_eof())
  assert_true(!sets.follow("B").unwrap().includes_eof())
}

///|
test "FIRST queries validate the entire sequence including unreachable suffixes" {
  let sets = grammar_test_expression().sets()
  for symbol in [Nonterminal("Unknown"), Nonterminal(""), Terminal("")] {
    assert_true(sets.first_sequence([Terminal("ok"), symbol]) is Err(InvalidGrammar(_)))
  }
  for name in ["", "Missing", "id"] {
    assert_true(sets.first(name) is Err(InvalidGrammar(_)))
    assert_true(sets.follow(name) is Err(InvalidGrammar(_)))
  }
}

///|
test "FOLLOW epsilon cycles repeated occurrences and EOF token collision" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("A"), Nonterminal("A"), Terminal("$")], "dollar"),
    grammar_test_rule("S", [Nonterminal("B")], "b"),
    grammar_test_rule("A", [], "ae"),
    grammar_test_rule("A", [Terminal("a")], "a"),
    grammar_test_rule("B", [Nonterminal("C")], "bc"),
    grammar_test_rule("C", [Nonterminal("B")], "cb"),
    grammar_test_rule("C", [], "ce"),
  ]).unwrap()
  let sets = g.sets()
  assert_eq(sets.first("S").unwrap().terminals(), ["$", "a"])
  assert_true(sets.first("S").unwrap().is_nullable())
  assert_eq(sets.follow("A").unwrap().terminals(), ["$", "a"])
  assert_true(!sets.follow("A").unwrap().includes_eof())
  for name in ["S", "B", "C"] {
    assert_eq(sets.follow(name).unwrap().terminals(), [])
    assert_true(sets.follow(name).unwrap().includes_eof())
  }
}

///|
test "FIRST FOLLOW cover disconnected rules without seeding their EOF" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [], "s"),
    grammar_test_rule("U", [Nonterminal("V"), Terminal("after")], "u"),
    grammar_test_rule("V", [Terminal("before")], "v"),
    grammar_test_rule("Loop", [Nonterminal("Loop")], "loop"),
  ]).unwrap()
  let sets = g.sets()
  assert_eq(sets.first("U").unwrap().terminals(), ["before"])
  assert_eq(sets.follow("V").unwrap().terminals(), ["after"])
  assert_true(!sets.follow("V").unwrap().includes_eof())
  assert_eq(sets.first("Loop").unwrap().terminals(), [])
  assert_true(!sets.first("Loop").unwrap().is_nullable())
  assert_eq(sets.follow("Loop").unwrap().terminals(), [])
  assert_true(!sets.follow("Loop").unwrap().includes_eof())
}

///|
test "FIRST FOLLOW ownership and lexical ordering are stable" {
  let input = [Terminal("z"), Terminal("later")]
  let g = Grammar::new("S", [
    grammar_test_rule("S", input, "z"),
    grammar_test_rule("S", [Terminal("apple")], "a"),
    grammar_test_rule("S", [Terminal("aa")], "aa"),
  ]).unwrap()
  let sets = g.sets()
  input.clear()
  let names = sets.nonterminals()
  names.clear()
  let first = sets.first("S").unwrap()
  let kinds = first.terminals()
  kinds.clear()
  assert_eq(first.terminals(), ["aa", "apple", "z"])
  assert_eq(sets.first("S").unwrap(), first)
  let follow = sets.follow("S").unwrap()
  let followers = follow.terminals()
  followers.push("fake")
  assert_eq(follow.terminals(), [])
  assert_true(follow.includes_eof())
  assert_eq(sets.nonterminals(), ["S"])
  let sequence = [Terminal("独立")]
  let sequence_first = sets.first_sequence(sequence).unwrap()
  sequence[0] = Terminal("changed")
  assert_eq(sequence_first.terminals(), ["独立"])
}

///|
test "FIRST FOLLOW left recursive tables converge with terminals and EOF" {
  let g = Grammar::new("S", [
    grammar_test_rule("S", [Nonterminal("S"), Terminal("tail")], "left"),
    grammar_test_rule("S", [Terminal("base")], "base"),
  ]).unwrap()
  assert_eq(g.first("S").unwrap().terminals(), ["base"])
  assert_true(!g.first("S").unwrap().is_nullable())
  assert_eq(g.follow("S").unwrap().terminals(), ["tail"])
  assert_true(g.follow("S").unwrap().includes_eof())
}

///|
test "FIRST FOLLOW long reverse chain and reordered productions agree" {
  let rules : Array[Rule] = []
  for i in 0..<45 {
    rules.push(grammar_test_rule("N\{i}", [Nonterminal("N\{i + 1}")], "r\{i}"))
  }
  rules.push(grammar_test_rule("N45", [], "empty"))
  rules.push(grammar_test_rule("N45", [Terminal("end")], "terminal"))
  let g = Grammar::new("N0", rules).unwrap()
  let reversed_rules = rules.mapi(fn(i, _) { rules[rules.length() - i - 1] })
  let other = Grammar::new("N0", reversed_rules).unwrap().sets()
  let sets = g.sets()
  for name in sets.nonterminals() {
    assert_eq(sets.first(name).unwrap().terminals(), ["end"])
    assert_true(sets.first(name).unwrap().is_nullable())
    assert_true(sets.follow(name).unwrap().includes_eof())
    assert_eq(sets.first(name), other.first(name))
    assert_eq(sets.follow(name), other.follow(name))
  }
}
