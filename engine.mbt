///|
priv suberror Halt {
  Halt(Problem)
}

///|
priv struct Item {
  rule : Int32
  dot : Int32
  origin : Int32
  node : Int32
}

///|
priv struct Chart {
  items : Array[Item]
  mut cursor : Int32
}

///|
struct Engine {
  grammar : Grammar
  limits : Limits
  charts : Array[Chart]
  nodes : Array[Node]
  tokens : Array[Token]
  mut item_count : Int32
  mut family_count : Int32
  mut work : Int32
}

///|
/// A parse report is an immutable snapshot, including when a session later advances.
pub struct Report {
  forest : Forest
  expected : Array[String]
  furthest : Int32
  stats : Statistics
}

///|
pub fn Report::accepted(self : Report) -> Bool {
  self.forest.root is Some(_)
}

///|
pub fn Report::forest(self : Report) -> Forest {
  self.forest
}

///|
pub fn Report::expected(self : Report) -> Array[String] {
  self.expected.copy()
}

///|
/// Furthest chart with at least one state, in token indices rather than source offsets.
pub fn Report::furthest(self : Report) -> Int32 {
  self.furthest
}

///|
pub fn Report::statistics(self : Report) -> Statistics {
  self.stats
}

///|
fn Engine::tick(self : Engine) -> Unit raise Halt {
  if self.work >= self.limits.work {
    raise Halt(Limit("work", self.limits.work))
  }
  self.work += 1
}

///|
/// Node identity includes kind and token interval. Families may grow after parents refer to it.
fn Engine::node_id(
  self : Engine,
  kind : NodeKind,
  start : Int32,
  end : Int32,
) -> Int32 raise Halt {
  for i, n in self.nodes {
    self.tick()
    if n.kind == kind && n.start == start && n.end == end {
      return i
    }
  }
  if self.nodes.length() >= self.limits.nodes {
    raise Halt(Limit("nodes", self.limits.nodes))
  }
  let id = self.nodes.length()
  self.nodes.push({ kind, start, end, families: [], })
  id
}

///|
/// Pack families, not parse trees; duplicates of the same rule/children are idempotent.
fn Engine::family(
  self : Engine,
  node : Int32,
  rule : Int32,
  children : Array[Int32],
) -> Unit raise Halt {
  let target = self.nodes[node].families
  for f in target {
    self.tick()
    if f.rule == rule && f.children == children {
      return
    }
  }
  if self.family_count >= self.limits.families {
    raise Halt(Limit("families", self.limits.families))
  }
  target.push({ rule, children: children.copy(), })
  self.family_count += 1
}

///|
/// Add one finite Earley state; additional families do not require state reprocessing.
fn Engine::item(
  self : Engine,
  end : Int32,
  rule : Int32,
  dot : Int32,
  origin : Int32,
) -> Int32 raise Halt {
  let chart = self.charts[end]
  for it in chart.items {
    self.tick()
    if it.rule == rule && it.dot == dot && it.origin == origin {
      return it.node
    }
  }
  if self.item_count >= self.limits.items {
    raise Halt(Limit("items", self.limits.items))
  }
  let node = self.node_id(Intermediate(rule, dot), origin, end)
  if dot == 0 {
    self.family(node, rule, [])
  }
  chart.items.push({ rule, dot, origin, node, })
  self.item_count += 1
  node
}

///|
fn Engine::advance(
  self : Engine,
  end : Int32,
  waiting : Item,
  child : Int32,
) -> Unit raise Halt {
  let prefix = self.item(end, waiting.rule, waiting.dot + 1, waiting.origin)
  self.family(prefix, waiting.rule, [waiting.node, child])
}

///|
/// Saturate prediction and completion before scanning. Pair both nullable insertion orders.
fn Engine::close_chart(self : Engine, end : Int32) -> Unit raise Halt {
  let chart = self.charts[end]
  while chart.cursor < chart.items.length() {
    self.tick()
    let item = chart.items[chart.cursor]
    chart.cursor += 1
    let rule = self.grammar.rules[item.rule]
    if item.dot == rule.rhs.length() {
      let symbol = self.node_id(SymbolNode(rule.lhs), item.origin, end)
      self.family(symbol, item.rule, [item.node])
      // Copy because completing epsilon rules can append to this same origin chart.
      for waiting in self.charts[item.origin].items.copy() {
        self.tick()
        let wr = self.grammar.rules[waiting.rule]
        if waiting.dot < wr.rhs.length() &&
          wr.rhs[waiting.dot] == Nonterminal(rule.lhs) {
          self.advance(end, waiting, symbol)
        }
      }
    } else {
      match rule.rhs[item.dot] {
        Terminal(_) => ()
        Nonterminal(name) => {
          for rid, prediction in self.grammar.rules {
            self.tick()
            if prediction.lhs == name {
              ignore(self.item(end, rid, 0, end))
            }
          }
          // A newly inserted waiter must also see a nullable completion already processed.
          for complete in chart.items.copy() {
            self.tick()
            let cr = self.grammar.rules[complete.rule]
            if complete.origin == end &&
              complete.dot == cr.rhs.length() &&
              cr.lhs == name {
              let symbol = self.node_id(SymbolNode(name), end, end)
              self.family(symbol, complete.rule, [complete.node])
              self.advance(end, item, symbol)
            }
          }
        }
      }
    }
  }
}

///|
fn Engine::new(grammar : Grammar, limits : Limits) -> Engine raise Halt {
  let engine : Engine = {
    grammar,
    limits,
    charts: [{ items: [], cursor: 0, }],
    nodes: [],
    tokens: [],
    item_count: 0,
    family_count: 0,
    work: 0,
  }
  for i, rule in grammar.rules {
    if rule.lhs == grammar.start {
      ignore(engine.item(0, i, 0, 0))
    }
  }
  engine.close_chart(0)
  engine
}

///|
/// Extend only the sealed last chart; earlier charts remain as completion origins.
fn Engine::append(self : Engine, token : Token) -> Unit raise Halt {
  let end = self.tokens.length()
  if end >= self.limits.tokens {
    raise Halt(Limit("tokens", self.limits.tokens))
  }
  self.tokens.push(token)
  self.charts.push({ items: [], cursor: 0, })
  for item in self.charts[end].items.copy() {
    self.tick()
    let rule = self.grammar.rules[item.rule]
    if item.dot < rule.rhs.length() &&
      rule.rhs[item.dot] == Terminal(token.kind) {
      let leaf = self.node_id(TokenLeaf(end), end, end + 1)
      self.advance(end + 1, item, leaf)
    }
  }
  self.close_chart(end + 1)
}

///|
fn Engine::report(self : Engine) -> Report {
  let mut root = None
  let end = self.tokens.length()
  for i, node in self.nodes {
    if node.kind == SymbolNode(self.grammar.start) &&
      node.start == 0 &&
      node.end == end {
      root = Some(i)
    }
  }
  let mut furthest = 0
  for i, chart in self.charts {
    if !chart.items.is_empty() {
      furthest = i
    }
  }
  let expected : Array[String] = []
  for item in self.charts[furthest].items {
    let rule = self.grammar.rules[item.rule]
    if item.dot < rule.rhs.length() {
      match rule.rhs[item.dot] {
        Terminal(kind) => if !expected.contains(kind) { expected.push(kind) }
        Nonterminal(_) => ()
      }
    }
  }
  expected.sort()
  let forest : Forest = {
    nodes: self.nodes.map(n => {
      kind: n.kind,
      start: n.start,
      end: n.end,
      families: n.families.map(copy_family),
    }),
    tokens: self.tokens.copy(),
    rules: self.grammar.rules.map(copy_rule),
    root,
  }
  {
    forest,
    expected,
    furthest,
    stats: {
      tokens: end,
      items: self.item_count,
      nodes: self.nodes.length(),
      families: self.family_count,
      work: self.work,
    },
  }
}

///|
/// Recognize and preserve all derivations. Rejection is Ok(report); failure is Err(problem).
pub fn parse(
  grammar : Grammar,
  tokens : Array[Token],
  limits~ : Limits = default_limits(),
) -> Result[Report, Problem] {
  match limits.validate() {
    Err(p) => return Err(p)
    Ok(_) => ()
  }
  match validate_tokens(tokens) {
    Err(p) => return Err(p)
    Ok(_) => ()
  }
  if tokens.length() > limits.tokens {
    return Err(Limit("tokens", limits.tokens))
  }
  try {
    let engine = Engine::new(grammar, limits)
    for token in tokens {
      engine.append(token)
    }
    Ok(engine.report())
  } catch {
    Halt(p) => Err(p)
  }
}
