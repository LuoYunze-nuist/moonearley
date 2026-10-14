///|
/// Reusable fixed-point results. No mutable collections escape this value.
pub struct GrammarAnalysis {
  nullable_names : Map[String, Bool]
  productive_names : Map[String, Bool]
  reachable_names : Map[String, Bool]
  nullable_rules : Array[Bool]
  productive_rules : Array[Bool]
  reachable_rules : Array[Bool]
}

///|
/// Epsilon is nullable; terminals never are, even if their name is nullable.
fn grammar_sequence_nullable(
  symbols : Array[Symbol],
  nullable : Map[String, Bool],
) -> Bool {
  for symbol in symbols {
    match symbol {
      Terminal(_) => return false
      Nonterminal(name) => if !nullable.contains(name) { return false }
    }
  }
  true
}

///|
/// Productive means a finite derivation of terminal kinds, including epsilon.
fn grammar_sequence_productive(
  symbols : Array[Symbol],
  productive : Map[String, Bool],
) -> Bool {
  for symbol in symbols {
    match symbol {
      Terminal(_) => ()
      Nonterminal(name) => if !productive.contains(name) { return false }
    }
  }
  true
}

///|
/// Each iteration can add only defined nonterminals, so this terminates.
fn grammar_nullable_map(grammar : Grammar) -> Map[String, Bool] {
  let result : Map[String, Bool] = Map([])
  let mut changed = true
  while changed {
    changed = false
    for rule in grammar.rules {
      if !result.contains(rule.lhs) && grammar_sequence_nullable(rule.rhs, result) {
        ignore(grammar_add_name(result, rule.lhs))
        changed = true
      }
    }
  }
  result
}

///|
/// Least fixed point: a self-cycle without a base case is not productive.
fn grammar_productive_map(grammar : Grammar) -> Map[String, Bool] {
  let result : Map[String, Bool] = Map([])
  let mut changed = true
  while changed {
    changed = false
    for rule in grammar.rules {
      if !result.contains(rule.lhs) && grammar_sequence_productive(rule.rhs, result) {
        ignore(grammar_add_name(result, rule.lhs))
        changed = true
      }
    }
  }
  result
}

///|
/// Syntactic reachability deliberately includes nonproductive alternatives.
fn grammar_reachable_map(grammar : Grammar) -> Map[String, Bool] {
  let result : Map[String, Bool] = Map([])
  result[grammar.start] = true
  let mut changed = true
  while changed {
    changed = false
    for rule in grammar.rules {
      if result.contains(rule.lhs) {
        for symbol in rule.rhs {
          match symbol {
            Terminal(_) => ()
            Nonterminal(name) => {
              if grammar_add_name(result, name) {
                changed = true
              }
            }
          }
        }
      }
    }
  }
  result
}

///|
/// Compute independent finite fixed points and per-expansion facts once.
pub fn Grammar::analyze(self : Grammar) -> GrammarAnalysis {
  let nullable_names = grammar_nullable_map(self)
  let productive_names = grammar_productive_map(self)
  let reachable_names = grammar_reachable_map(self)
  let nullable_rules = self.rules.map(fn(rule) {
    grammar_sequence_nullable(rule.rhs, nullable_names)
  })
  let productive_rules = self.rules.map(fn(rule) {
    grammar_sequence_productive(rule.rhs, productive_names)
  })
  let reachable_rules = self.rules.map(fn(rule) {
    reachable_names.contains(rule.lhs)
  })
  {
    nullable_names,
    productive_names,
    reachable_names,
    nullable_rules,
    productive_rules,
    reachable_rules,
  }
}

///|
pub fn Grammar::nullable(self : Grammar) -> Array[String] {
  grammar_sorted_names(grammar_nullable_map(self))
}

///|
pub fn Grammar::productive(self : Grammar) -> Array[String] {
  grammar_sorted_names(grammar_productive_map(self))
}

///|
pub fn Grammar::reachable(self : Grammar) -> Array[String] {
  grammar_sorted_names(grammar_reachable_map(self))
}

///|
pub fn GrammarAnalysis::nullable(self : GrammarAnalysis) -> Array[String] {
  grammar_sorted_names(self.nullable_names)
}

///|
pub fn GrammarAnalysis::productive(self : GrammarAnalysis) -> Array[String] {
  grammar_sorted_names(self.productive_names)
}

///|
pub fn GrammarAnalysis::reachable(self : GrammarAnalysis) -> Array[String] {
  grammar_sorted_names(self.reachable_names)
}

///|
/// Unknown names return false rather than introducing implicit definitions.
pub fn GrammarAnalysis::is_nullable(self : GrammarAnalysis, name : String) -> Bool {
  self.nullable_names.contains(name)
}

///|
pub fn GrammarAnalysis::is_productive(self : GrammarAnalysis, name : String) -> Bool {
  self.productive_names.contains(name)
}

///|
pub fn GrammarAnalysis::is_reachable(self : GrammarAnalysis, name : String) -> Bool {
  self.reachable_names.contains(name)
}

///|
/// Safe index queries distinguish a negative/out-of-range index from false.
pub fn GrammarAnalysis::rule_is_nullable(self : GrammarAnalysis, index : Int) -> Bool? {
  if index < 0 || index >= self.nullable_rules.length() {
    None
  } else {
    Some(self.nullable_rules[index])
  }
}

///|
pub fn GrammarAnalysis::rule_is_productive(self : GrammarAnalysis, index : Int) -> Bool? {
  if index < 0 || index >= self.productive_rules.length() {
    None
  } else {
    Some(self.productive_rules[index])
  }
}

///|
pub fn GrammarAnalysis::rule_is_reachable(self : GrammarAnalysis, index : Int) -> Bool? {
  if index < 0 || index >= self.reachable_rules.length() {
    None
  } else {
    Some(self.reachable_rules[index])
  }
}
