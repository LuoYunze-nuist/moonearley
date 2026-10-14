///|
/// Structured rejection diagnostics; token indices and character offsets are distinct.
pub(all) struct ParseDiagnostic {
  token_index : Int
  char_start : Int
  char_end : Int
  actual_kind : String?
  expected_kinds : Array[String]
  at_eof : Bool
} derive(Eq, Debug)

///|
pub extend ParseDiagnostic with Eq::{equal, not_equal}

///|
pub extend ParseDiagnostic with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Accepted prefixes have no failure, even when further tokens could be accepted.
pub fn Report::diagnostic(self : Report) -> ParseDiagnostic? {
  if self.accepted() {
    return None
  }
  let tokens = self.forest.tokens
  let index = self.furthest
  if index < tokens.length() {
    let t = tokens[index]
    Some({
      token_index: index,
      char_start: t.start,
      char_end: t.end,
      actual_kind: Some(t.kind),
      expected_kinds: self.expected.copy(),
      at_eof: false,
    })
  } else {
    let end = if tokens.is_empty() {
      0
    } else {
      tokens[tokens.length() - 1].end
    }
    Some({
      token_index: index,
      char_start: end,
      char_end: end,
      actual_kind: None,
      expected_kinds: self.expected.copy(),
      at_eof: true,
    })
  }
}

///|
/// A bounded token window around the failure, or the end for an accepted report.
pub fn Report::context(
  self : Report,
  radius : Int,
) -> Result[Array[Token], Problem] {
  if radius < 0 || radius > 4096 {
    return Err(InvalidLimit("context radius"))
  }
  let tokens = self.forest.tokens
  let center = if self.accepted() { tokens.length() } else { self.furthest }
  let lo = if center > radius { center - radius } else { 0 }
  let hi = if center + radius + 1 < tokens.length() {
    center + radius + 1
  } else {
    tokens.length()
  }
  let result : Array[Token] = []
  for i = lo; i < hi; i = i + 1 {
    result.push(tokens[i])
  }
  Ok(result)
}

///|
/// Total tokens includes unmatched input; forest leaves contain only scanned tokens.
pub fn Forest::token_count(self : Forest) -> Int {
  self.tokens.length()
}

///|
pub fn Forest::rule_count(self : Forest) -> Int {
  self.rules.length()
}
