# Changelog

## 0.1.1 — 2026-11-01

- Require moonc >= 0.10.16 and enforce the compiler floor in all CI validation jobs.
- Document and revalidate with the official October 28 toolchain (moonc 0.10.18).
- Keep the runtime parsing API and grammar/forest semantics unchanged.

## 0.1.0 — 2026-10-14

- Runtime typed token-kind CFGs, validated snapshots, bounded text syntax and canonical export.
- Nullable/productive/reachable, FIRST/FOLLOW and advisory recursion/duplicate diagnostics.
- Resource-limited Earley recognition with ambiguity-preserving shared packed forests.
- Finite/capped/infinite derivation counts, productive ambiguity/span queries and DOT graphs.
- Bounded ordered AST witnesses with separate cycle/depth/tree/work truncation flags.
- Transactional retained-chart append sessions, forks and immutable reports.
- Positioned rejection diagnostics, three downstream workflows and reference tests.
- MIT provenance, AI disclosure, security boundaries and four-backend CI.

This release does not implement lexing, arbitrary-edit incremental parsing, recovery,
Lark syntax compatibility, semantic actions or Leo optimization.
