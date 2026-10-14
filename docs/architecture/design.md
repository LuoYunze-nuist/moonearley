# MoonEarley architecture and invariants

1. `model` / `grammar`: named terminal and nonterminal namespaces stay distinct.
   Production labels are unique; duplicate expansions with different labels are
   separate derivations. Owned copies prevent caller array mutation.
2. `grammar_analysis` / `grammar_sets` / `grammar_lint`: finite monotonic sets,
   nullable prefix/suffix propagation, explicit EOF, iterative graph closure.
   Recursive or unproductive grammars are diagnostic findings, not blanket errors.
3. `frontend` / `grammar_export`: bounded UTF-16 lexer, self-contained small CFG
   syntax, explicit labels and lossless canonical export. Not Lark grammar syntax.
4. `engine`: chart key (end, rule, dot, origin); queue saturates prediction and
   completion before scanning. New waiters also match already completed nullable
   items in the same chart, covering both insertion orders.
5. `forest`: token leaf, symbol(name,start,end), intermediate(rule,dot,start,end).
   Families are OR alternatives of ordered AND children. Completed rules point
   to shared prefixes; advances point to previous-prefix plus scanned/completed
   child. New alternatives on an existing node need no new chart item.
6. `forest_count`: least productivity fixed point; ignore nonproductive AND
   alternatives when constructing the productive root-reachable graph. A cycle
   there gives infinitely many finite labeled derivations. Otherwise topological
   evaluation sums/products with exact-cap distinction and saturation safeguards.
7. `tree_extract`: explicit task stack flattens intermediate prefixes. Branch-local
   path checks cut cyclic unfolding; finite cycle-free witnesses remain available.
   Tree/depth/work/cycle truncation flags are public; never report partial output
   as exhaustive. This is NOT enumeration of every finite cyclic unfolding.
8. `session`: chart persistence with deep-copy transactions and forks. Old charts
   are retained, not re-parsed from token zero. Copies provide safety, not a claim
   of optimal incremental time or memory. Arbitrary edits are out of scope.

Stable external contract is in `pkg.generated.mbti`. Array-bearing query results
are copied; IDs belong to one forest snapshot. Input token spans are caller source
coordinates; forest/tree spans always count tokens. Rejection is Ok(Report) with
accepted=false; malformed input and resource failure are Err(Problem).

## Verification strategy

- Assertions on nullable/recursive/ambiguous cases and mutation isolation.
- Independent test-only span fixed-point oracle: 32 grammar variants × 31 binary
  token strings = 992 cases, with session-vs-batch checks for each nonempty prefix.
- Pinned MIT Lark: four grammars × 63 binary strings = 252 acceptance AND derivation
  count comparisons, including nullable productions and two independently labeled
  parses. No upstream tests are claimed executed as MoonEarley tests.
- Count tests include Catalan numbers, independently labeled duplicate rules,
  productive and dead cycles, shared DAG edges, overflow and capped equality.
- Tree tests exercise ordered flattening, cycle/depth/work truncation and copies.
- Public workflows demonstrate DSL interpretation, prefix language service and CFG QA.
