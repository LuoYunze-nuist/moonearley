///|
test "canonical export specifies start labels and ordered rules" {
  let g = parse_grammar("@start B; A -> ['first'] 'x' B | ; B -> ['epsilon'];").unwrap()
  let text = export_grammar(g)
  assert_eq(
    text, "@start \"B\";\n\"A\" -> ['first'] 'x' \"B\";\n\"A\" -> ['rule:1'];\n\"B\" -> ['epsilon'];\n",
  )
  let rebuilt = parse_grammar(text).unwrap()
  assert_eq(rebuilt.start(), g.start())
  assert_eq(rebuilt.rules(), g.rules())
  assert_eq(export_grammar(rebuilt), text)
  assert_eq(export_grammar(g), text)
}

///|
test "canonical export handles arbitrary names and Unicode quotes escapes" {
  let name = "名 字😀#[]|;->\"\\\n\r\t"
  let terminal = "终端😀'\"\\\n\r\t#|;[]"
  let label = "label😀'\"\\\n\r\t#|;[]"
  let g = Grammar::new(name, [
    { lhs: name, rhs: [Terminal(terminal), Nonterminal(name)], label, },
    { lhs: name, rhs: [], label: "empty", },
    { lhs: "other 非终结符", rhs: [], label: "disconnected", },
  ]).unwrap()
  let text = export_grammar(g)
  let roundtrip = parse_grammar(text).unwrap()
  assert_eq(roundtrip.start(), name)
  assert_eq(roundtrip.rules(), g.rules())
  assert_eq(export_grammar(roundtrip), text)
}

///|
test "canonical quote escapes all forbidden ASCII controls" {
  let out = StringBuilder()
  grammar_export_quote(
    out, "\u{0000}\u{0001}\u{0008}\t\n\r\u{001f}\u{007f}", '\'',
  )
  assert_eq(out.to_string(), "'\\u0000\\u0001\\u0008\\t\\n\\r\\u001f\\u007f'")
  let controls = StringBuilder()
  for i = 0; i < 32; i = i + 1 {
    controls.write_char(i.unsafe_to_char())
  }
  controls.write_char('\u{007f}')
  let value = controls.to_string()
  let g = Grammar::new(value, [
    { lhs: value, rhs: [Terminal(value)], label: value, },
  ]).unwrap()
  let roundtrip = parse_grammar(export_grammar(g)).unwrap()
  assert_eq(roundtrip.start(), value)
  assert_eq(roundtrip.rules(), g.rules())
}

///|
test "canonical export retains duplicates epsilon cycles and explicit auto-like labels" {
  let rules : Array[Rule] = [
    { lhs: "Z", rhs: [], label: "rule:0", },
    { lhs: "A", rhs: [Nonterminal("A")], label: "cycle", },
    { lhs: "Z", rhs: [Terminal("id")], label: "one", },
    { lhs: "Z", rhs: [Terminal("id")], label: "two", },
  ]
  let g = Grammar::new("A", rules).unwrap()
  let exported = export_grammar(g)
  assert_eq(parse_grammar(exported).unwrap().rules(), rules)
  let copied = g.rules()
  copied[2].rhs.clear()
  copied.clear()
  assert_eq(export_grammar(g), exported)
}

///|
test "canonical importer budgets are caller controlled not hidden export defaults" {
  let g = parse_grammar("A -> ['label'] 'token' |;").unwrap()
  let text = export_grammar(g)
  let exact : FrontendLimits = {
    max_chars: text.length(),
    max_rules: 2,
    max_symbols: 1,
  }
  assert_eq(parse_grammar(text, limits=exact).unwrap().rules(), g.rules())
  assert_true(
    parse_grammar(text, limits={ ..exact, max_chars: text.length() - 1, })
    is Err(Limit("grammar_chars", _)),
  )
  assert_true(
    parse_grammar(text, limits={ ..exact, max_rules: 1, })
    is Err(Limit("grammar_rules", 1)),
  )
}

///|
test "canonical export normalizes equivalent frontend spellings" {
  let a = parse_grammar("# hi\n A->['a']'id'|['b'];").unwrap()
  let b = parse_grammar("@start \"A\"; \"A\" -> ['a'] '\\u0069d'; A -> ['b'];").unwrap()
  assert_eq(export_grammar(a), export_grammar(b))
}
