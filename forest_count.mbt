///|
/// Counts distinguish exact equality to the cap from actual saturation.
/// Infinite means arbitrarily many finite derivation trees, not an infinite tree.
pub(all) enum DerivationCount {
  Finite(Int32)
  AtLeast(Int32)
  Infinite
} derive(Eq, Debug)

///|
pub extend DerivationCount with Eq::{equal, not_equal}

///|
pub extend DerivationCount with @moonbitlang/core/debug.Debug::{to_repr}

///|
priv suberror ForestAnalysisHalt {
  ForestAnalysisHalt(Problem)
}

///|
/// A single cumulative budget covers fixed points, graph traversal and counting.
priv struct ForestAnalysisBudget {
  name : String
  limit : Int32
  mut used : Int32
}

///|
fn ForestAnalysisBudget::tick(
  self : ForestAnalysisBudget,
) -> Unit raise ForestAnalysisHalt {
  if self.used >= self.limit {
    raise ForestAnalysisHalt(Limit(self.name, self.limit))
  }
  self.used += 1
}

///|
fn forest_analysis_check_id(
  forest : Forest,
  id : Int32,
) -> Unit raise ForestAnalysisHalt {
  if id < 0 || id >= forest.nodes.length() {
    raise ForestAnalysisHalt(InvalidNode(id))
  }
}

///|
/// AND-edge productivity; epsilon families succeed by vacuous conjunction.
fn forest_analysis_family_productive(
  forest : Forest,
  family : Family,
  productive : Array[Bool],
  budget : ForestAnalysisBudget,
) -> Bool raise ForestAnalysisHalt {
  budget.tick()
  for child in family.children {
    budget.tick()
    forest_analysis_check_id(forest, child)
    if !productive[child] {
      return false
    }
  }
  true
}

///|
/// Least fixed point, rather than treating a DFS back-edge as a derivation.
/// Token leaves have one derivation. Other nodes require a finite AND/OR proof.
fn forest_analysis_productive(
  forest : Forest,
  budget : ForestAnalysisBudget,
) -> Array[Bool] raise ForestAnalysisHalt {
  let productive = Array::make(forest.nodes.length(), false)
  let mut changed = true
  while changed {
    changed = false
    for id, node in forest.nodes {
      budget.tick()
      if !productive[id] {
        match node.kind {
          TokenLeaf(_) => {
            productive[id] = true
            changed = true
          }
          _ =>
            for family in node.families {
              if forest_analysis_family_productive(
                  forest, family, productive, budget,
                ) {
                productive[id] = true
                changed = true
                break
              }
            }
        }
      }
    }
  }
  productive
}

///|
priv struct ForestCappedCount {
  value : Int32
  clipped : Bool
}

///|
/// Never form an overflowing sum. An exact cap is still exact.
fn forest_count_add(
  a : ForestCappedCount,
  b : ForestCappedCount,
  cap : Int32,
) -> ForestCappedCount {
  if a.clipped || b.clipped || a.value > cap - b.value {
    { value: cap, clipped: true, }
  } else {
    { value: a.value + b.value, clipped: false, }
  }
}

///|
/// Divide before multiplying; zero annihilates even a clipped factor.
fn forest_count_multiply(
  a : ForestCappedCount,
  b : ForestCappedCount,
  cap : Int32,
) -> ForestCappedCount {
  if a.value == 0 || b.value == 0 {
    { value: 0, clipped: false, }
  } else if a.clipped || b.clipped || a.value > cap / b.value {
    { value: cap, clipped: true, }
  } else {
    { value: a.value * b.value, clipped: false, }
  }
}

///|
/// Family alternatives add; ordered children multiply, including repeated IDs.
/// Intermediate prefixes contribute no additional rule-choice multiplier.
fn forest_count_node(
  forest : Forest,
  id : Int32,
  productive : Array[Bool],
  counts : Array[ForestCappedCount],
  cap : Int32,
  budget : ForestAnalysisBudget,
) -> ForestCappedCount raise ForestAnalysisHalt {
  match forest.nodes[id].kind {
    TokenLeaf(_) => return { value: 1, clipped: false, }
    _ => ()
  }
  let mut sum : ForestCappedCount = { value: 0, clipped: false, }
  for family in forest.nodes[id].families {
    if forest_analysis_family_productive(forest, family, productive, budget) {
      let mut product : ForestCappedCount = { value: 1, clipped: false, }
      for child in family.children {
        budget.tick()
        product = forest_count_multiply(product, counts[child], cap)
      }
      sum = forest_count_add(sum, product, cap)
    }
  }
  sum
}

///|
/// Build only the root-reachable graph of productive families. An edge from
/// an unproductive AND-family must NOT cause a false Infinite classification.
/// Keep parallel child occurrences: dependency decrements mirror increments.
fn forest_count_reachable_graph(
  forest : Forest,
  root : Int32,
  productive : Array[Bool],
  budget : ForestAnalysisBudget,
) -> (Array[Int32], Array[Int32], Array[Array[Int32]]) raise ForestAnalysisHalt {
  let visited = Array::make(forest.nodes.length(), false)
  let pending = Array::make(forest.nodes.length(), 0)
  let parents : Array[Array[Int32]] = Array::makei(forest.nodes.length(), fn(
    _,
  ) {
    []
  })
  let nodes = [root]
  visited[root] = true
  let mut cursor = 0
  while cursor < nodes.length() {
    budget.tick()
    let id = nodes[cursor]
    cursor += 1
    match forest.nodes[id].kind {
      TokenLeaf(_) => ()
      _ =>
        for family in forest.nodes[id].families {
          if forest_analysis_family_productive(
              forest, family, productive, budget,
            ) {
            for child in family.children {
              budget.tick()
              pending[id] += 1
              parents[child].push(id)
              if !visited[child] {
                visited[child] = true
                nodes.push(child)
              }
            }
          }
        }
    }
  }
  (nodes, pending, parents)
}

///|
/// Reverse Kahn traversal evaluates a DAG bottom-up without recursive calls.
/// Any remaining productive reachable cycle can be unfolded arbitrarily often,
/// choosing productive exits each time, and therefore gives infinitely many trees.
fn forest_count_evaluate(
  forest : Forest,
  root : Int32,
  productive : Array[Bool],
  cap : Int32,
  budget : ForestAnalysisBudget,
) -> DerivationCount raise ForestAnalysisHalt {
  let (nodes, pending, parents) = forest_count_reachable_graph(
    forest, root, productive, budget,
  )
  let ready : Array[Int32] = []
  for id in nodes {
    budget.tick()
    if pending[id] == 0 {
      ready.push(id)
    }
  }
  let zero : ForestCappedCount = { value: 0, clipped: false, }
  let counts = Array::make(forest.nodes.length(), zero)
  let mut cursor = 0
  while cursor < ready.length() {
    budget.tick()
    let id = ready[cursor]
    cursor += 1
    counts[id] = forest_count_node(forest, id, productive, counts, cap, budget)
    for parent in parents[id] {
      budget.tick()
      pending[parent] -= 1
      if pending[parent] == 0 {
        ready.push(parent)
      }
    }
  }
  if ready.length() < nodes.length() {
    Infinite
  } else if counts[root].clipped {
    AtLeast(cap)
  } else {
    Finite(counts[root].value)
  }
}

///|
/// Counts all labeled derivations represented by the accepted root.
/// A rejected forest or nonproductive root has zero, not Infinite.
/// Both limits must be positive Int values; arithmetic remains safe even at
/// Int's maximum cap. Work charges node visits, family checks and child edges
/// across every pass; exhausted budgets are errors, never partial counts.
pub fn Forest::count(
  self : Forest,
  cap~ : Int32 = 1000000,
  work_limit~ : Int32 = 1000000,
) -> Result[DerivationCount, Problem] {
  if cap <= 0 {
    return Err(InvalidLimit("cap"))
  }
  if work_limit <= 0 {
    return Err(InvalidLimit("work_limit"))
  }
  let root = match self.root {
    None => return Ok(Finite(0))
    Some(id) => id
  }
  let budget : ForestAnalysisBudget = {
    name: "count_work",
    limit: work_limit,
    used: 0,
  }
  try {
    forest_analysis_check_id(self, root)
    let productive = forest_analysis_productive(self, budget)
    if !productive[root] {
      Ok(Finite(0))
    } else {
      Ok(forest_count_evaluate(self, root, productive, cap, budget))
    }
  } catch {
    ForestAnalysisHalt(problem) => Err(problem)
  }
}
