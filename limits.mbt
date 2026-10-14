///| All counters are cumulative for one parse/session, not reset per token.
pub(all) struct Limits {
  tokens : Int
  items : Int
  nodes : Int
  families : Int
  work : Int
} derive(Eq, Debug)

///|
pub extend Limits with Eq::{equal, not_equal}

///|
pub extend Limits with @moonbitlang/core/debug.Debug::{to_repr}

///| Conservative defaults for small/medium runtime grammars; not performance guarantees.
pub fn default_limits() -> Limits {
  { tokens: 4096, items: 100000, nodes: 200000, families: 400000, work: 5000000 }
}

///| Bound configuration arithmetic before any allocation or chart work.
pub fn Limits::validate(self : Limits) -> Result[Unit, Problem] {
  for pair in [
    ("tokens", self.tokens), ("items", self.items), ("nodes", self.nodes),
    ("families", self.families), ("work", self.work),
  ] {
    let (name, n) = pair
    if n < (if name == "tokens" { 0 } else { 1 }) || n > 10000000 {
      return Err(InvalidLimit(name))
    }
  }
  Ok(())
}

///| Stable counters describe allocated states, not derivation counts.
pub(all) struct Statistics {
  tokens : Int
  items : Int
  nodes : Int
  families : Int
  work : Int
} derive(Eq, Debug)

///|
pub extend Statistics with Eq::{equal, not_equal}

///|
pub extend Statistics with @moonbitlang/core/debug.Debug::{to_repr}

