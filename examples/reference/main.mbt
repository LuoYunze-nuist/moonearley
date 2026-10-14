///|
fn main {
  let sources = [
    "S -> S S | 'a';", "S -> S 'a' | ;", "S -> A 'b' A; A -> 'a' | ;", "S -> A | B; A -> 'a'; B -> 'a';",
  ]
  for which, source in sources {
    let grammar = @moonearley.parse_grammar(source).unwrap()
    for length = 0; length <= 5; length = length + 1 {
      for bits = 0; bits < 1 << length; bits = bits + 1 {
        let tokens : Array[@moonearley.Token] = []
        for i = 0; i < length; i = i + 1 {
          let kind = if ((bits >> i) & 1) == 0 { "a" } else { "b" }
          tokens.push(@moonearley.token(kind, kind, i, i + 1))
        }
        let report = @moonearley.parse(grammar, tokens).unwrap()
        let count = match report.forest().count().unwrap() {
          Finite(n) => n
          AtLeast(_) => -1
          Infinite => -2
        }
        println("\{which},\{length},\{bits},\{report.accepted()},\{count}")
      }
    }
  }
}
