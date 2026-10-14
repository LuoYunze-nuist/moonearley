///|
test "diagnostics locate rejected token kinds in caller character coordinates" {
  let g = grammar_for_test("s",[{lhs:"s",rhs:[Terminal("a"),Terminal("b")],label:"pair"}])
  let report = parse(g,[token("a","first",3,8),token("bad","?",12,13),token("b","last",15,19)]).unwrap()
  assert_eq(report.diagnostic(),Some({token_index:1,char_start:12,char_end:13,actual_kind:Some("bad"),expected_kinds:["b"],at_eof:false}))
  assert_eq(report.context(0).unwrap().map(t=>t.kind),["bad"])
  assert_eq(report.context(1).unwrap().map(t=>t.kind),["a","bad","b"])
  assert_eq(report.forest().token_count(),3)
  assert_eq(report.forest().rule_count(),1)
  assert_true(report.context(-1) is Err(InvalidLimit(_)))
  assert_true(report.context(4097) is Err(InvalidLimit(_)))
  let view = report.diagnostic().unwrap()
  view.expected_kinds.clear()
  assert_eq(report.diagnostic().unwrap().expected_kinds,["b"])
}

///|
test "EOF diagnostics preserve offsets and accepted prefixes have no failure" {
  let g = grammar_for_test("s",[{lhs:"s",rhs:[Terminal("a"),Terminal("b")],label:"pair"}])
  assert_eq(parse(g,[]).unwrap().diagnostic().unwrap().char_start,0)
  let partial=parse(g,[token("a","",9,9)]).unwrap()
  assert_eq(partial.diagnostic().unwrap().char_start,9)
  assert_true(partial.diagnostic().unwrap().at_eof)
  let full=parse(g,[token("a","",9,9),token("b","",9,9)]).unwrap()
  assert_eq(full.diagnostic(),None)
  assert_eq(full.context(0).unwrap(),[])
}
