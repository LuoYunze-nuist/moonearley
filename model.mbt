///|
/// An input or budget failure. Results never silently report budget exhaustion as rejection.
pub(all) enum Problem {
  InvalidGrammar(String)
  InvalidToken(Int32, String)
  Limit(String, Int32)
  InvalidNode(Int32)
  InvalidLimit(String)
  Syntax(Int32, String)
} derive(Eq, Debug)

///|
/// CFG symbols are names, never regular expressions or literal text matchers.
pub(all) enum Symbol {
  Terminal(String)
  Nonterminal(String)
} derive(Eq, Debug)

///|
/// Rule labels identify alternatives independently of their symbol sequences.
pub(all) struct Rule {
  lhs : String
  rhs : Array[Symbol]
  label : String
} derive(Eq, Debug)

///|
/// Span units belong to the caller (typically UTF-16 or byte offsets).
pub(all) struct Token {
  kind : String
  text : String
  start : Int32
  end : Int32
} derive(Eq, Debug)

///|
/// Snapshot a token, preventing accidental dependence on caller arrays.
pub fn token(kind : String, text : String, start : Int32, end : Int32) -> Token {
  { kind, text, start, end, }
}

///|
/// Validate monotonic nonoverlapping spans; zero-width tokens are permitted.
pub fn validate_tokens(tokens : Array[Token]) -> Result[Unit, Problem] {
  let mut previous = 0
  for i, t in tokens {
    if t.kind == "" {
      return Err(InvalidToken(i, "empty token kind"))
    }
    if t.start < previous || t.end < t.start {
      return Err(InvalidToken(i, "negative, reversed or overlapping span"))
    }
    previous = t.end
  }
  Ok(())
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Symbol with Eq::{equal, not_equal}

///|
pub extend Symbol with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Rule with Eq::{equal, not_equal}

///|
pub extend Rule with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Token with Eq::{equal, not_equal}

///|
pub extend Token with @moonbitlang/core/debug.Debug::{to_repr}
