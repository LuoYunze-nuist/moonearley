///|
/// Budgets count UTF-16 source units, productions, and total RHS symbols.
/// All limits must be positive and at most ten million. Comments count as source.
pub(all) struct FrontendLimits {
  max_chars : Int32
  max_rules : Int32
  max_symbols : Int32
} derive(Eq, Debug)

///|
pub extend FrontendLimits with Eq::{equal, not_equal}

///|
pub extend FrontendLimits with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Defaults bound both lexer storage and the grammar passed to validation.
pub fn default_frontend_limits() -> FrontendLimits {
  { max_chars: 65536, max_rules: 4096, max_symbols: 16384, }
}

///|
pub fn FrontendLimits::validate(self : FrontendLimits) -> Result[Unit, Problem] {
  for
    pair in [
      ("max_chars", self.max_chars),
      ("max_rules", self.max_rules),
      ("max_symbols", self.max_symbols),
    ] {
    let (name, value) = pair
    if value <= 0 || value > 10000000 {
      return Err(InvalidLimit(name))
    }
  }
  Ok(())
}

///|
priv enum FrontendKind {
  Name(String)
  Quoted(String)
  Arrow
  Bar
  Semi
  OpenLabel
  CloseLabel
  Start
  End
} derive(Eq)

///|
priv struct FrontendToken {
  kind : FrontendKind
  offset : Int32
}

///|
fn frontend_name_start(c : Int32) -> Bool {
  (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95
}

///|
fn frontend_name_part(c : Int32) -> Bool {
  frontend_name_start(c) || (c >= 48 && c <= 57)
}

///|
fn frontend_hex(c : Int32) -> Int32? {
  if c >= 48 && c <= 57 {
    Some(c - 48)
  } else if c >= 65 && c <= 70 {
    Some(c - 55)
  } else if c >= 97 && c <= 102 {
    Some(c - 87)
  } else {
    None
  }
}

///|
/// Four hexadecimal digits, diagnosed at the offending digit or EOF.
fn frontend_hex4(source : String, at : Int32) -> Result[Int32, Problem] {
  let mut value = 0
  for i = 0; i < 4; i = i + 1 {
    if at + i >= source.length() {
      return Err(Syntax(source.length(), "incomplete Unicode escape"))
    }
    match frontend_hex(source[at + i].to_int()) {
      Some(digit) => value = value * 16 + digit
      None => return Err(Syntax(at + i, "expected hexadecimal digit"))
    }
  }
  Ok(value)
}

///|
/// Decode a Unicode escape; surrogate halves must form one valid pair.
fn frontend_unicode(
  source : String,
  at : Int32,
) -> Result[(Char, Int32), Problem] {
  let high = match frontend_hex4(source, at) {
    Ok(value) => value
    Err(problem) => return Err(problem)
  }
  if high >= 0xDC00 && high <= 0xDFFF {
    return Err(Syntax(at, "unpaired low surrogate"))
  }
  if high < 0xD800 || high > 0xDBFF {
    return Ok((high.unsafe_to_char(), at + 4))
  }
  let next = at + 4
  if next + 1 >= source.length() ||
    source[next].to_int() != 92 ||
    source[next + 1].to_int() != 117 {
    return Err(Syntax(next, "expected low surrogate Unicode escape"))
  }
  let low = match frontend_hex4(source, next + 2) {
    Ok(value) => value
    Err(problem) => return Err(problem)
  }
  if low < 0xDC00 || low > 0xDFFF {
    return Err(Syntax(next + 2, "expected low surrogate"))
  }
  Ok(
    (
      (0x10000 + (high - 0xD800) * 1024 + low - 0xDC00).unsafe_to_char(),
      next + 6,
    ),
  )
}

///|
/// Both quote styles share escapes; literal CR/LF and controls are rejected.
fn frontend_quoted(
  source : String,
  at : Int32,
) -> Result[(String, Int32), Problem] {
  let quote = source[at].to_int()
  let out = StringBuilder()
  let mut pos = at + 1
  while pos < source.length() {
    let c = source[pos].to_int()
    if c == quote {
      return Ok((out.to_string(), pos + 1))
    }
    if c < 32 || c == 127 {
      return Err(Syntax(pos, "control character in quoted string"))
    }
    if c != 92 {
      let begin = pos
      while pos < source.length() {
        let unit = source[pos].to_int()
        if unit == quote || unit == 92 || unit < 32 || unit == 127 {
          break
        }
        pos = pos + 1
      }
      out.write_view(source[begin:pos])
      continue
    }
    let escape = pos
    pos = pos + 1
    if pos == source.length() {
      return Err(Syntax(escape, "unfinished escape"))
    }
    match source[pos].to_int() {
      92 => out.write_char('\\')
      39 => out.write_char('\'')
      34 => out.write_char('"')
      110 => out.write_char('\n')
      114 => out.write_char('\r')
      116 => out.write_char('\t')
      117 =>
        match frontend_unicode(source, pos + 1) {
          Ok((decoded, end)) => {
            out.write_char(decoded)
            pos = end
            continue
          }
          Err(problem) => return Err(problem)
        }
      _ => return Err(Syntax(escape, "unknown escape"))
    }
    pos = pos + 1
  }
  Err(Syntax(at, "unterminated quoted string"))
}

///|
/// Each token consumes at least one unit; storage is bounded by max_chars + EOF.
fn frontend_lex(source : String) -> Result[Array[FrontendToken], Problem] {
  let tokens : Array[FrontendToken] = []
  let mut pos = 0
  while pos < source.length() {
    let at = pos
    let c = source[pos].to_int()
    if c == 32 || c == 9 || c == 10 || c == 13 {
      pos = pos + 1
      continue
    }
    if c == 35 {
      while pos < source.length() &&
            source[pos].to_int() != 10 &&
            source[pos].to_int() != 13 {
        pos = pos + 1
      }
      continue
    }
    let kind = if c == 39 || c == 34 {
      match frontend_quoted(source, pos) {
        Ok((text, end)) => {
          pos = end
          if c == 39 {
            Quoted(text)
          } else {
            Name(text)
          }
        }
        Err(problem) => return Err(problem)
      }
    } else if frontend_name_start(c) {
      pos = pos + 1
      while pos < source.length() && frontend_name_part(source[pos].to_int()) {
        pos = pos + 1
      }
      Name(source[at:pos].to_owned())
    } else if c == 64 {
      if pos + 6 > source.length() || source[pos:pos + 6] != "@start" {
        return Err(Syntax(pos, "expected @start directive"))
      }
      pos = pos + 6
      if pos < source.length() && frontend_name_part(source[pos].to_int()) {
        return Err(Syntax(pos, "expected separator after @start"))
      }
      Start
    } else {
      pos = pos + 1
      match c {
        45 => {
          if pos >= source.length() || source[pos].to_int() != 62 {
            return Err(Syntax(at, "expected ->"))
          }
          pos = pos + 1
          Arrow
        }
        124 => Bar
        59 => Semi
        91 => OpenLabel
        93 => CloseLabel
        _ => return Err(Syntax(at, "unexpected character"))
      }
    }
    tokens.push({ kind, offset: at, })
  }
  tokens.push({ kind: End, offset: source.length(), })
  Ok(tokens)
}

///|
/// Assign missing labels after reserving explicit labels, including later rules.
/// Explicit duplicates remain constructor errors rather than being renamed.
fn frontend_assign_labels(rules : Array[Rule]) -> Unit {
  let used : Map[String, Bool] = Map([])
  for rule in rules {
    if rule.label != "" {
      used[rule.label] = true
    }
  }
  for i = 0; i < rules.length(); i = i + 1 {
    let rule = rules[i]
    if rule.label != "" {
      continue
    }
    let mut suffix = i
    let mut label = "rule:\{suffix}"
    while used.contains(label) {
      suffix = suffix + 1
      label = "rule:\{suffix}"
    }
    used[label] = true
    rules[i] = { lhs: rule.lhs, rhs: rule.rhs, label, }
  }
}

///|
/// Parse a finite token sequence. EOF is always present, so lookahead is safe.
fn frontend_parse_rules(
  tokens : Array[FrontendToken],
  limits : FrontendLimits,
) -> Result[(String, Array[Rule]), Problem] {
  let mut pos = 0
  let mut start : String? = None
  if tokens[pos].kind == Start {
    pos = pos + 1
    match tokens[pos].kind {
      Name(name) => start = Some(name)
      _ => return Err(Syntax(tokens[pos].offset, "expected start nonterminal"))
    }
    pos = pos + 1
    if tokens[pos].kind != Semi {
      return Err(Syntax(tokens[pos].offset, "expected ; after @start"))
    }
    pos = pos + 1
  }
  let rules : Array[Rule] = []
  let mut symbols = 0
  while tokens[pos].kind != End {
    let lhs = match tokens[pos].kind {
      Name(name) => name
      _ => return Err(Syntax(tokens[pos].offset, "expected production lhs"))
    }
    if start is None {
      start = Some(lhs)
    }
    pos = pos + 1
    if tokens[pos].kind != Arrow {
      return Err(Syntax(tokens[pos].offset, "expected -> after lhs"))
    }
    pos = pos + 1
    let mut more = true
    while more {
      if rules.length() >= limits.max_rules {
        return Err(Limit("grammar_rules", limits.max_rules))
      }
      let mut label = ""
      if tokens[pos].kind == OpenLabel {
        pos = pos + 1
        match tokens[pos].kind {
          Quoted(text) => {
            if text == "" {
              return Err(Syntax(tokens[pos].offset, "empty explicit label"))
            }
            label = text
          }
          _ =>
            return Err(
              Syntax(tokens[pos].offset, "expected single-quoted label"),
            )
        }
        pos = pos + 1
        if tokens[pos].kind != CloseLabel {
          return Err(Syntax(tokens[pos].offset, "expected ] after label"))
        }
        pos = pos + 1
      }
      let rhs : Array[Symbol] = []
      while true {
        let symbol = match tokens[pos].kind {
          Name(name) => Nonterminal(name)
          Quoted(kind) => Terminal(kind)
          Bar | Semi => break
          _ => return Err(Syntax(tokens[pos].offset, "expected symbol, | or ;"))
        }
        if symbols >= limits.max_symbols {
          return Err(Limit("grammar_symbols", limits.max_symbols))
        }
        rhs.push(symbol)
        symbols = symbols + 1
        pos = pos + 1
      }
      rules.push({ lhs, rhs, label, })
      more = tokens[pos].kind == Bar
      pos = pos + 1
    }
  }
  frontend_assign_labels(rules)
  match start {
    Some(name) => Ok((name, rules))
    None => Err(InvalidGrammar("grammar has no rules"))
  }
}

///|
/// A small token-kind CFG language, not Lark syntax or a text-tokenizing lexer.
/// Syntax: optional initial `@start Name;`, then `Name -> ['label'] symbols | ;`.
/// Each alternative may have one label; an empty alternative means epsilon.
/// Bare names match [A-Za-z_][A-Za-z0-9_]*; double quotes allow arbitrary names.
/// Single quotes denote terminal kinds or bracketed labels. Both quotes accept
/// escaped backslash/quotes, n/r/t and uXXXX (paired for supplementary Unicode).
/// Space, tab, CR/LF and # line comments are ignored outside quoted strings.
/// Default start is the first lhs. Missing labels get collision-free rule:N names.
/// Syntax offsets are zero-based UTF-16 units, including the EOF offset.
/// Lexical/syntax failures precede semantic validation; exhaustion is never rejection.
pub fn parse_grammar(
  source : String,
  limits~ : FrontendLimits = default_frontend_limits(),
) -> Result[Grammar, Problem] {
  match limits.validate() {
    Err(problem) => return Err(problem)
    Ok(_) => ()
  }
  if source.length() > limits.max_chars {
    return Err(Limit("grammar_chars", limits.max_chars))
  }
  let tokens = match frontend_lex(source) {
    Ok(value) => value
    Err(problem) => return Err(problem)
  }
  match frontend_parse_rules(tokens, limits) {
    Ok((start, rules)) => Grammar::new(start, rules)
    Err(problem) => Err(problem)
  }
}
