# Verification record — 0.1.0

## Scope and local environment

Windows, 2026-10-14 Asia/Shanghai. Official stable moon 0.1.20261012 (748b63c),
moonc v0.10.15+943464bfa. AI tests and source inspection are not official contest acceptance.

Production inventory: **3435 physical .mbt lines / 2755 nonblank noncomment lines**,
16 source files, independently reviewed substantive grammar/parser/forest/session engines.
`python scripts/audit_sources.py --require-production 1500` reproduces the full inventory.
Exclude tests, examples, generated interfaces, benchmark/vendor/generated directories;
formatting changes physical counts but is not treated as new functionality.

102 named tests (including two external public-API blackbox tests); 992 independently
implemented span fixed-point recognition cases, each with retained-session prefix checks.
Lark source SHA 9a4fb9c7458e8155636773a3cded0016d52516da: 252/252 acceptance AND labeled
finite-count cases match on JS and wasm-gc. Inputs are generated small binary sequences,
not a benchmark or a claim about large-input performance.

## Commands

- `moon info && moon fmt`; interface review confirmed the intended API plus inaccessible
  representation types Node/Engine. `moon fmt --check` passes.
- Strict check/build/test and three runnable examples on wasm-gc, wasm, JS.
- `python scripts/reference_check.py --lark-source PINNED_SOURCE --target js` and wasm-gc.
- `moon test --enable-coverage --deny-warn` and `moon coverage analyze`: used to find and
  add public-entrypoint rejection tests. Some defensive internal-corruption guards are
  intentionally not covered by normal public parses; no 100% coverage claim.
- `python scripts/audit_history.py --minimum-nonempty 20`: author and committer identity
  matches repository binding for every real commit. Conservative review in history-review.md.

Native test attempt failed locally before compilation: no system C compiler, tried
cc/gcc/clang. Native is a required CI target, not a claimed local success.
The workflow installs the official toolchain on clean Ubuntu and records its actual
version; the upstream differential job checks out the fixed Lark SHA.

## External evidence and privacy

GitHub/Release/MoonCakes completion is determined from the actual bound-account service
responses and fresh consumers, not from this preflight document or a configured URL.
The final run IDs, tested commit, ZIP digest and external verification are retained in
an external local delivery record. Public Actions and Release are the remote evidence.
The Chinese application and account credential stores are outside this repository.
Privacy scanner examines worktree and reachable Git history; package ZIP content is
also reviewed. Passing a scanner is not a guarantee of absence of every possible secret.

## Toolchain compatibility repair

The first actual GitHub run (38536907851) installed moon 0.1.20261012 and
rejected the older formatter spelling (`Int` and `parameter?`), not a test result.
An independently installed official 20261012 toolchain canonicalized sources to
`Int32` and `parameter~`; generated public interfaces remained unchanged.
Strict checks, builds, all 102 tests and three examples were repeated locally on
JS, wasm and wasm-gc. This compatibility/format repair is not counted toward
the twenty substantive development commits. Native remains CI-only.

## 0.1.1 compiler acceptance revalidation — 2026-11-01

The participant-provided acceptance guide now requires **moonc >= 0.10.16**.
The original 0.1.0 record above remains historical. This patch was revalidated on
Windows with the official moon 0.1.20261028 / moonc v0.10.18+6c83a7f62 toolchain.
Run `python scripts/check_toolchain.py` before the other validation commands.
All portable CI matrix jobs and the pinned Lark job enforce the same floor.
The gate was exercised against real 0.10.15 (rejected) and 0.10.18 (accepted) installations.

Strict check/build/test: 102/102 named tests on each of JS, wasm and wasm-gc;
all three downstream examples run on each of those backends. The pinned Lark
comparison still agrees on 252 acceptance/count vectors on JS and wasm-gc.
An independent span-hypergraph oracle additionally compared 840 inputs over
56 grammars on all three portable backends, including nullable permutations,
productive/dead cycles and ordered rule-labeled ASTs. Separate mathematical
fixtures verify exact/saturated Int32 counts and inclusive extraction depth limits.
These are correctness checks, not performance claims.

The generated interface changes only the legacy `Int` alias spelling to `Int32`;
production MoonBit source and parsing semantics are unchanged. No local native
success is claimed: Windows MSVC C++ tools/linker/SDK remain unavailable.
Native must pass the CI run for the exact patch commit before publication.
