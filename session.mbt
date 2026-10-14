///|
/// A session owns a persistent chart; each successful push only adds a new chart.
pub struct Session {
  engines : Array[Engine]
}

///|
/// Deep clone supports transactional resource failures and independent forks.
fn Engine::clone(self : Engine) -> Engine {
  {
    grammar: self.grammar,
    limits: self.limits,
    charts: self.charts.map(c => { items: c.items.copy(), cursor: c.cursor, }),
    nodes: self.nodes.map(n => {
      kind: n.kind,
      start: n.start,
      end: n.end,
      families: n.families.map(copy_family),
    }),
    tokens: self.tokens.copy(),
    item_count: self.item_count,
    family_count: self.family_count,
    work: self.work,
  }
}

///|
/// Opening a session can fail during nullable closure before the first token.
pub fn Session::new(
  grammar : Grammar,
  limits~ : Limits = default_limits(),
) -> Result[Session, Problem] {
  match limits.validate() {
    Err(p) => return Err(p)
    Ok(_) => ()
  }
  Ok({ engines: [Engine::new(grammar, limits)], }) catch {
    Halt(p) => Err(p)
  }
}

///|
/// Validate and append one token atomically; failed appends leave statistics unchanged.
pub fn Session::push(self : Session, token : Token) -> Result[Report, Problem] {
  let previous = self.engines[0].tokens
  let index = previous.length()
  if token.kind == "" || token.start < 0 || token.end < token.start {
    return Err(InvalidToken(index, "invalid kind or character span"))
  }
  if index > 0 && token.start < previous[index - 1].end {
    return Err(
      InvalidToken(index, "overlapping or nonmonotonic character span"),
    )
  }
  let next = self.engines[0].clone()
  try {
    next.append(token)
    self.engines[0] = next
    Ok(next.report())
  } catch {
    Halt(p) => Err(p)
  }
}

///|
/// Append a batch atomically. Input can start at any later character offset.
pub fn Session::push_all(
  self : Session,
  tokens : Array[Token],
) -> Result[Report, Problem] {
  let fork = self.fork()
  for token in tokens {
    match fork.push(token) {
      Err(p) => return Err(p)
      Ok(_) => ()
    }
  }
  self.engines[0] = fork.engines[0]
  Ok(self.report())
}

///|
/// Snapshots and forked sessions have no shared mutable chart or family arrays.
pub fn Session::fork(self : Session) -> Session {
  { engines: [self.engines[0].clone()], }
}

///|
/// Reports copy the packed forest and remain valid after future appends.
pub fn Session::report(self : Session) -> Report {
  self.engines[0].report()
}
