///|
/// FIRST has terminal kinds plus a separate epsilon bit, never a magic token.
pub struct FirstSet {
  kinds : Array[String]
  empty : Bool
} derive(Eq, Debug)

///|
pub extend FirstSet with Eq::{equal, not_equal}

///|
pub extend FirstSet with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// FOLLOW distinguishes end of input from every possible caller token kind.
pub struct FollowSet {
  kinds : Array[String]
  eof : Bool
} derive(Eq, Debug)

///|
pub extend FollowSet with Eq::{equal, not_equal}

///|
pub extend FollowSet with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Immutable-by-API, reusable set tables for all defined nonterminals.
pub struct GrammarSets {
  names : Array[String]
  nullable : Map[String, Bool]
  first : Map[String, Map[String, Bool]]
  follow : Map[String, Map[String, Bool]]
  end_of_input : Map[String, Bool]
}

///|
pub fn FirstSet::terminals(self : FirstSet) -> Array[String] {
  self.kinds.copy()
}

///|
pub fn FirstSet::is_nullable(self : FirstSet) -> Bool {
  self.empty
}

///|
pub fn FollowSet::terminals(self : FollowSet) -> Array[String] {
  self.kinds.copy()
}

///|
pub fn FollowSet::includes_eof(self : FollowSet) -> Bool {
  self.eof
}

///|
/// Union also works when target and source are the same map: no new keys then.
fn grammar_union_names(
  target : Map[String, Bool],
  source : Map[String, Bool],
) -> Bool {
  let mut changed = false
  for name in source.keys() {
    if grammar_add_name(target, name) {
      changed = true
    }
  }
  changed
}

///|
/// FIRST of a suffix using the current approximation of nonterminal FIRST.
/// The offset is internal and always in 0..=symbols.length().
fn grammar_first_suffix(
  symbols : Array[Symbol],
  offset : Int32,
  nullable : Map[String, Bool],
  first : Map[String, Map[String, Bool]],
) -> (Map[String, Bool], Bool) {
  let kinds : Map[String, Bool] = Map([])
  for i in offset..<symbols.length() {
    match symbols[i] {
      Terminal(kind) => {
        kinds[kind] = true
        return (kinds, false)
      }
      Nonterminal(name) => {
        match first.get(name) {
          Some(set) => ignore(grammar_union_names(kinds, set))
          None => ()
        }
        if !nullable.contains(name) {
          return (kinds, false)
        }
      }
    }
  }
  (kinds, true)
}

///|
/// Initialize every row, including disconnected and nonproductive definitions.
fn grammar_empty_table(names : Array[String]) -> Map[String, Map[String, Bool]] {
  let table : Map[String, Map[String, Bool]] = Map([])
  for name in names {
    table[name] = Map([])
  }
  table
}

///|
/// Terminal sets grow monotonically within the finite grammar token universe.
fn grammar_first_table(
  grammar : Grammar,
  names : Array[String],
  nullable : Map[String, Bool],
) -> Map[String, Map[String, Bool]] {
  let table = grammar_empty_table(names)
  let mut changed = true
  while changed {
    changed = false
    for rule in grammar.rules {
      let (kinds, _) = grammar_first_suffix(rule.rhs, 0, nullable, table)
      let target = table[rule.lhs]
      if grammar_union_names(target, kinds) {
        changed = true
      }
    }
  }
  table
}

///|
/// For A -> alpha B beta: FIRST(beta) enters FOLLOW(B); when beta is
/// nullable, FOLLOW(A), including the independent EOF bit, enters FOLLOW(B).
fn grammar_follow_tables(
  grammar : Grammar,
  names : Array[String],
  nullable : Map[String, Bool],
  first : Map[String, Map[String, Bool]],
) -> (Map[String, Map[String, Bool]], Map[String, Bool]) {
  let table = grammar_empty_table(names)
  let eof : Map[String, Bool] = Map([])
  eof[grammar.start] = true
  let mut changed = true
  while changed {
    changed = false
    for rule in grammar.rules {
      for i, symbol in rule.rhs {
        match symbol {
          Terminal(_) => ()
          Nonterminal(name) => {
            let (suffix, empty) = grammar_first_suffix(
              rule.rhs,
              i + 1,
              nullable,
              first,
            )
            let target = table[name]
            if grammar_union_names(target, suffix) {
              changed = true
            }
            if empty {
              if grammar_union_names(target, table[rule.lhs]) {
                changed = true
              }
              if eof.contains(rule.lhs) && grammar_add_name(eof, name) {
                changed = true
              }
            }
          }
        }
      }
    }
  }
  (table, eof)
}

///|
/// FOLLOW obeys the equations for ALL rules, not only reachable productions.
/// Only the distinguished start is initially seeded with end of input.
pub fn Grammar::sets(self : Grammar) -> GrammarSets {
  let names = self.nonterminals()
  let nullable = grammar_nullable_map(self)
  let first = grammar_first_table(self, names, nullable)
  let (follow, end_of_input) = grammar_follow_tables(
    self, names, nullable, first,
  )
  { names, nullable, first, follow, end_of_input, }
}

///|
pub fn GrammarSets::nonterminals(self : GrammarSets) -> Array[String] {
  self.names.copy()
}

///|
/// Reject unknown names rather than returning a misleading empty FIRST row.
pub fn GrammarSets::first(
  self : GrammarSets,
  name : String,
) -> Result[FirstSet, Problem] {
  match self.first.get(name) {
    None =>
      Err(InvalidGrammar("FIRST requested for undefined nonterminal: \{name}"))
    Some(kinds) =>
      Ok({
        kinds: grammar_sorted_names(kinds),
        empty: self.nullable.contains(name),
      })
  }
}

///|
pub fn GrammarSets::follow(
  self : GrammarSets,
  name : String,
) -> Result[FollowSet, Problem] {
  match self.follow.get(name) {
    None =>
      Err(InvalidGrammar("FOLLOW requested for undefined nonterminal: \{name}"))
    Some(kinds) =>
      Ok({
        kinds: grammar_sorted_names(kinds),
        eof: self.end_of_input.contains(name),
      })
  }
}

///|
/// A sequence may contain new nonempty terminal kinds, but every nonterminal
/// must be defined. Validate even the suffix behind a nonnullable prefix.
pub fn GrammarSets::first_sequence(
  self : GrammarSets,
  symbols : Array[Symbol],
) -> Result[FirstSet, Problem] {
  for i, symbol in symbols {
    match symbol {
      Terminal(kind) =>
        if kind == "" {
          return Err(
            InvalidGrammar("empty terminal kind in FIRST sequence at \{i}"),
          )
        }
      Nonterminal(name) =>
        if !self.first.contains(name) {
          return Err(
            InvalidGrammar(
              "undefined nonterminal \{name} in FIRST sequence at \{i}",
            ),
          )
        }
    }
  }
  let (kinds, empty) = grammar_first_suffix(
    symbols,
    0,
    self.nullable,
    self.first,
  )
  Ok({ kinds: grammar_sorted_names(kinds), empty, })
}

///|
/// Convenience one-shot query. Reuse sets() when querying many symbols.
pub fn Grammar::first(
  self : Grammar,
  name : String,
) -> Result[FirstSet, Problem] {
  self.sets().first(name)
}

///|
pub fn Grammar::follow(
  self : Grammar,
  name : String,
) -> Result[FollowSet, Problem] {
  self.sets().follow(name)
}

///|
pub fn Grammar::first_sequence(
  self : Grammar,
  symbols : Array[Symbol],
) -> Result[FirstSet, Problem] {
  self.sets().first_sequence(symbols)
}
