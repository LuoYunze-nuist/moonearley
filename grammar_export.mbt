///|
/// Quote one value without changing its Unicode contents. The delimiter selects
/// nonterminal names (double quote) versus terminal kinds/labels (single quote).
fn grammar_export_quote(
  out : StringBuilder,
  text : String,
  quote : Char,
) -> Unit {
  out.write_char(quote)
  let hex = "0123456789abcdef"
  for c in text {
    if c == quote {
      out.write_char('\\')
      out.write_char(c)
      continue
    }
    match c {
      '\\' => out.write_string("\\\\")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ => {
        let value = c.to_int()
        if value < 32 || value == 127 {
          out.write_string("\\u")
          for shift in [12, 8, 4, 0] {
            out.write_view(
              hex[(value >> shift) & 15:((value >> shift) & 15) + 1],
            )
          }
        } else {
          out.write_char(c)
        }
      }
    }
  }
  out.write_char(quote)
}

///|
/// Canonical human CFG: explicit start, one production per line, all labels
/// explicit, every nonterminal double quoted, and a final newline. Rule and RHS
/// order are preserved, not sorted: they identify parser alternatives. Exporting
/// is read-only and returns the same string on every call for the same grammar.
/// Import using parse_grammar with sufficient FrontendLimits for this output;
/// export is not restricted to the importer's default budgets. No Lark claim.
pub fn export_grammar(grammar : Grammar) -> String {
  let out = StringBuilder()
  out.write_string("@start ")
  grammar_export_quote(out, grammar.start(), '"')
  out.write_string(";\n")
  for rule in grammar.rules() {
    grammar_export_quote(out, rule.lhs, '"')
    out.write_string(" -> [")
    grammar_export_quote(out, rule.label, '\'')
    out.write_char(']')
    for symbol in rule.rhs {
      out.write_char(' ')
      match symbol {
        Terminal(kind) => grammar_export_quote(out, kind, '\'')
        Nonterminal(name) => grammar_export_quote(out, name, '"')
      }
    }
    out.write_string(";\n")
  }
  out.to_string()
}
