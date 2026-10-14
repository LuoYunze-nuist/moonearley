///|
/// A validated, owned snapshot of a token-kind context-free grammar.
/// Fields are private outside this package; the parser can read them directly.
pub struct Grammar {
  start : String
  rules : Array[Rule]
}

///|
/// Copy the mutable expansion while retaining immutable symbol/name values.
fn grammar_copy_rule(rule : Rule) -> Rule {
  { lhs: rule.lhs, rhs: rule.rhs.copy(), label: rule.label }
}

///|
/// Insert a set member and report whether a finite fixed point changed.
fn grammar_add_name(set : Map[String, Bool], name : String) -> Bool {
  if set.contains(name) {
    false
  } else {
    set[name] = true
    true
  }
}

///|
/// Map iteration order is deliberately not exposed by any grammar query.
fn grammar_sorted_names(set : Map[String, Bool]) -> Array[String] {
  let names = set.keys().to_array()
  names.sort_by(fn(a, b) { a.lexical_compare(b) })
  names
}

///|
/// Construct a grammar without retaining any caller-owned arrays.
/// Empty expansions and repeated expansions with distinct labels are legal.
/// Names are exact strings: whitespace is meaningful, not silently trimmed.
pub fn Grammar::new(
  start : String,
  rules : Array[Rule],
) -> Result[Grammar, Problem] {
  if start == "" {
    return Err(InvalidGrammar("empty start nonterminal"))
  }
  if rules.is_empty() {
    return Err(InvalidGrammar("grammar has no rules"))
  }
  let definitions : Map[String, Bool] = Map([])
  let labels : Map[String, Bool] = Map([])
  let owned : Array[Rule] = []
  // Gather all definitions before resolving forward references.
  for index, rule in rules {
    if rule.lhs == "" {
      return Err(InvalidGrammar("empty lhs at rule \{index}"))
    }
    if rule.label == "" {
      return Err(InvalidGrammar("empty label at rule \{index}"))
    }
    if labels.contains(rule.label) {
      return Err(InvalidGrammar("duplicate rule label: \{rule.label}"))
    }
    ignore(grammar_add_name(labels, rule.label))
    ignore(grammar_add_name(definitions, rule.lhs))
    owned.push(grammar_copy_rule(rule))
  }
  if !definitions.contains(start) {
    return Err(InvalidGrammar("start nonterminal is undefined: \{start}"))
  }
  for rule in owned {
    for position, symbol in rule.rhs {
      match symbol {
        Terminal(kind) => {
          if kind == "" {
            return Err(
              InvalidGrammar("empty terminal kind in \{rule.label} at \{position}"),
            )
          }
        }
        Nonterminal(name) => {
          if name == "" {
            return Err(
              InvalidGrammar("empty nonterminal in \{rule.label} at \{position}"),
            )
          }
          if !definitions.contains(name) {
            return Err(
              InvalidGrammar("undefined nonterminal \{name} in \{rule.label}"),
            )
          }
        }
      }
    }
  }
  Ok({ start, rules: owned })
}

///|
/// The distinguished nonterminal, unchanged from construction.
pub fn Grammar::start(self : Grammar) -> String {
  self.start
}

///|
/// Return an independent outer array AND independent expansion arrays.
/// Rule ordering is retained because rule indices identify parser alternatives.
pub fn Grammar::rules(self : Grammar) -> Array[Rule] {
  self.rules.map(grammar_copy_rule)
}

///|
/// All defined nonterminals, including disconnected and nonproductive ones.
pub fn Grammar::nonterminals(self : Grammar) -> Array[String] {
  let names : Map[String, Bool] = Map([])
  for rule in self.rules {
    names[rule.lhs] = true
  }
  grammar_sorted_names(names)
}

///|
/// Distinct token kinds, sorted independently of production ordering.
pub fn Grammar::terminals(self : Grammar) -> Array[String] {
  let names : Map[String, Bool] = Map([])
  for rule in self.rules {
    for symbol in rule.rhs {
      match symbol {
        Terminal(kind) => names[kind] = true
        Nonterminal(_) => ()
      }
    }
  }
  grammar_sorted_names(names)
}

///|
/// Includes epsilon rules and distinct labels sharing an expansion.
pub fn Grammar::rule_count(self : Grammar) -> Int {
  self.rules.length()
}


