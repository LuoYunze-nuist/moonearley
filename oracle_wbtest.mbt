///|
/// Independent finite span fixed-point recognizer, only in tests.
/// Unlike Earley it derives nonterminal intervals without chart items or forests.
fn oracle_accept(g : Grammar, input : Array[String]) -> Bool {
  let names = g.nonterminals()
  let side = input.length() + 1
  let cells = side * side
  let known : Array[Array[Bool]] = names.map(_ => Array::make(cells, false))
  let mut changed = true
  while changed {
    changed = false
    for rule in g.rules() {
      let lhs = names.search(rule.lhs).unwrap()
      for lo = 0; lo < side; lo = lo + 1 {
        let mut ends = Array::make(side, false)
        ends[lo] = true
        for symbol in rule.rhs {
          let next = Array::make(side, false)
          for begin = lo; begin < side; begin = begin + 1 {
            if ends[begin] {
              match symbol {
                Terminal(kind) =>
                  if begin < input.length() && input[begin] == kind {
                    next[begin + 1] = true
                  }
                Nonterminal(name) => {
                  let id = names.search(name).unwrap()
                  for end = begin; end < side; end = end + 1 {
                    if known[id][begin * side + end] {
                      next[end] = true
                    }
                  }
                }
              }
            }
          }
          ends = next
        }
        for hi = lo; hi < side; hi = hi + 1 {
          if ends[hi] && !known[lhs][lo * side + hi] {
            known[lhs][lo * side + hi] = true
            changed = true
          }
        }
      }
    }
  }
  known[names.search(g.start()).unwrap()][input.length()]
}

///|
test "independent span oracle compares 992 bounded recognition cases" {
  let choices : Array[Array[Symbol]] = [
    [],
    [Terminal("a")],
    [Terminal("b")],
    [Nonterminal("S")],
    [Nonterminal("S"), Nonterminal("S")],
    [Nonterminal("A"), Terminal("b")],
    [Terminal("a"), Nonterminal("A")],
    [Nonterminal("A"), Nonterminal("S")],
  ]
  let mut compared = 0
  for variant = 0; variant < 32; variant = variant + 1 {
    let g = Grammar::new("S", [
      { lhs: "S", rhs: choices[variant % 8], label: "s0", },
      { lhs: "S", rhs: choices[(variant / 4 + 1) % 8], label: "s1", },
      { lhs: "A", rhs: choices[(variant / 8 + 2) % 8], label: "a0", },
      { lhs: "A", rhs: [Terminal("a")], label: "a1", },
    ]).unwrap()
    for length = 0; length <= 4; length = length + 1 {
      for bits = 0; bits < 1 << length; bits = bits + 1 {
        let kinds : Array[String] = []
        for index = 0; index < length; index = index + 1 {
          kinds.push(if ((bits >> index) & 1) == 0 { "a" } else { "b" })
        }
        let tokens = kinds.mapi((i, k) => token(k, k, i, i + 1))
        assert_eq(parse(g, tokens).unwrap().accepted(), oracle_accept(g, kinds))
        let session = Session::new(g).unwrap()
        let batch : Array[Token] = []
        for t in tokens {
          batch.push(t)
          let step = session.push(t).unwrap()
          assert_eq(step.accepted(), parse(g, batch).unwrap().accepted())
          assert_eq(step.statistics(), parse(g, batch).unwrap().statistics())
        }
        compared = compared + 1
      }
    }
  }
  assert_eq(compared, 992)
}
