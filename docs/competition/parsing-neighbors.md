# Additional parsing substitute evidence

No direct substitute for the full proposed scope found among these four in the inspected API/source/test scope. All are adjacent, with genuine overlaps documented below. This is not a global uniqueness or contest eligibility guarantee.

**Execution:** source/test inspection only; no tests or downloaded code executed. No implementation, Git/account/registry changes or reservations.

| Module / fixed GitHub HEAD | Behavioral finding | License / maintenance |
|---|---|---|
| `sundaysebasidian-byte/moonabnf@0.1.0`<br>`323a3728c3faac0ca1052fb8f7590e98ee040156` | Adjacent: runtime byte-grammar recognizer; not a direct substitute for the proposed forest/session contract. Runtime ABNF compile/recognize over Bytes. Choice unions distinct ending offsets, not derivation identities. Nullable expressions supported, but nullable-prefix left recursion is diagnosed; nonproductive unit cycles rejected. Public MatchReport is status/offset/work/states, not a forest. ABNF incremental =/ extends rules, not an input-append session. | MIT declared; root LICENSE inspected (MIT text). Last pushed 2026-10-01T10:23:54Z; archived=False. |
| `bobzhang/peg@0.1.0`<br>`b51e271aaefa5aa06a065473245ad52219a9f5f9` | Adjacent: runtime grammar generation exists, but ordered single-result string parsing. generate(grammar) builds runtime parser over String (UTF-16 units). Choice falls through only on failure, discarding alternative successful derivations. Compiler check reports zero-consumption recursion. Public Session configures compiler passes/plugins; it is not retained append-only input parse state. No public packed-forest/bounded derivation-extraction API found in inspected interface. | MIT declared in manifest; no standalone LICENSE/COPYING file found in pinned GitHub snapshot. Do not treat declaration as inspected license text. Last pushed 2026-10-12T23:43:18Z; archived=False. |
| `kokic/talcparsec@0.4.0`<br>`39f787c6d2d5a158f1657eebf61b54edcaae7943` | Adjacent: custom-token cursor combinators, but committed/first-success single results. Open Cursor trait supports custom token streams; ParserRaw wraps I -> Result[(T,I),E]. choice stops at first Ok or committed Err. many rejects no-progress success. delay allows handwritten recursion, not demonstrated cycle-safe chart fixed points. parse_partial returns residual cursor, not a retained chart/forest append session. No public packed-forest/count API found in inspected public source. | AGPL-3.0 declared; root LICENSE inspected (GNU Affero GPL version 3 text). Last pushed 2026-09-29T03:17:26Z; archived=False. |
| `peter-jerry-ye/parser-combinator@0.9.1`<br>`773e25361f397d80a4f1529c51b146e426b37a53` | Adjacent: generic external-token combinators, but single optional parse result. Parser[Token,Value] is Seq[Token] -> (Value,Seq[Token])?. pvalue supports generic external tokens. or_else returns first Some, trying other parser only on None; repeat builds one result chain. Seq is lazy, not a public retained append-session/chart contract. No public shared packed forest/count API or cycle-safe recursion engine found in the inspected two-source-file library. | Apache-2.0 declared in manifest; no standalone LICENSE/COPYING file found in pinned GitHub snapshot. Do not treat declaration as inspected license text. Last pushed 2024-09-04T02:21:05Z; archived=True. |

## sundaysebasidian-byte/moonabnf

- Official docs: https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf
- Fixed source root: `C:/Users/42673/.codex/competition-deliverables/LuoYunze-nuist/replacement-research/additional-parsing-evidence/sundaysebasidian-byte__moonabnf/github/MoonABNF-323a3728c3faac0ca1052fb8f7590e98ee040156`
- Pin: `C:/Users/42673/.codex/competition-deliverables/LuoYunze-nuist/replacement-research/additional-parsing-evidence/sundaysebasidian-byte__moonabnf/pin.json`
- Actual implementation/API evidence:
  - `pkg.generated.mbti:1` — https://github.com/sundaysebasidian-byte/MoonABNF/blob/323a3728c3faac0ca1052fb8f7590e98ee040156/pkg.generated.mbti#L1
  - `analysis.mbt:108` — https://github.com/sundaysebasidian-byte/MoonABNF/blob/323a3728c3faac0ca1052fb8f7590e98ee040156/analysis.mbt#L108
  - `recognizer.mbt:64` — https://github.com/sundaysebasidian-byte/MoonABNF/blob/323a3728c3faac0ca1052fb8f7590e98ee040156/recognizer.mbt#L64
  - `recognizer.mbt:98` — https://github.com/sundaysebasidian-byte/MoonABNF/blob/323a3728c3faac0ca1052fb8f7590e98ee040156/recognizer.mbt#L98
  - `recognizer.mbt:239` — https://github.com/sundaysebasidian-byte/MoonABNF/blob/323a3728c3faac0ca1052fb8f7590e98ee040156/recognizer.mbt#L239
- Actual test bodies read (not executed):
  - `compiler_test.mbt:27` — **productive and nullable-prefix cycles are diagnosed** — https://github.com/sundaysebasidian-byte/MoonABNF/blob/323a3728c3faac0ca1052fb8f7590e98ee040156/compiler_test.mbt#L27
  - `recognizer_test.mbt:10` — **all alternatives, case modes and exact numeric sequences** — https://github.com/sundaysebasidian-byte/MoonABNF/blob/323a3728c3faac0ca1052fb8f7590e98ee040156/recognizer_test.mbt#L10
  - `recognizer_test.mbt:27` — **nullable repeats, exact counts, incremental choices and endpoints** — https://github.com/sundaysebasidian-byte/MoonABNF/blob/323a3728c3faac0ca1052fb8f7590e98ee040156/recognizer_test.mbt#L27
- Published release vs pinned HEAD (local byte comparison): `README.md`: different; `pkg.generated.mbti`: byte-identical; `analysis.mbt`: byte-identical; `recognizer.mbt`: byte-identical; `compiler_test.mbt`: byte-identical; `recognizer_test.mbt`: byte-identical; `LICENSE`: byte-identical.
- Caveat: nullable expressions are supported; the rejected cases are nonproductive/unit or nullable-prefix recursion. Ending-offset sets do not preserve distinct derivations with the same span.

## bobzhang/peg

- Official docs: https://mooncakes.io/docs/bobzhang/peg
- Fixed source root: `C:/Users/42673/.codex/competition-deliverables/LuoYunze-nuist/replacement-research/additional-parsing-evidence/bobzhang__peg/github/peg.mbt-b51e271aaefa5aa06a065473245ad52219a9f5f9`
- Pin: `C:/Users/42673/.codex/competition-deliverables/LuoYunze-nuist/replacement-research/additional-parsing-evidence/bobzhang__peg/pin.json`
- Actual implementation/API evidence:
  - `README.mbt.md:1` — https://github.com/bobzhang/peg.mbt/blob/b51e271aaefa5aa06a065473245ad52219a9f5f9/README.mbt.md#L1
  - `pkg.generated.mbti:1` — https://github.com/bobzhang/peg.mbt/blob/b51e271aaefa5aa06a065473245ad52219a9f5f9/pkg.generated.mbti#L1
  - `vm/parser.mbt:15` — https://github.com/bobzhang/peg.mbt/blob/b51e271aaefa5aa06a065473245ad52219a9f5f9/vm/parser.mbt#L15
  - `vm/parser.mbt:36` — https://github.com/bobzhang/peg.mbt/blob/b51e271aaefa5aa06a065473245ad52219a9f5f9/vm/parser.mbt#L36
  - `compiler/pass_checks.mbt:146` — https://github.com/bobzhang/peg.mbt/blob/b51e271aaefa5aa06a065473245ad52219a9f5f9/compiler/pass_checks.mbt#L146
  - `compiler/pass_generate_bytecode.mbt:199` — https://github.com/bobzhang/peg.mbt/blob/b51e271aaefa5aa06a065473245ad52219a9f5f9/compiler/pass_generate_bytecode.mbt#L199
  - `compiler/session.mbt:19` — https://github.com/bobzhang/peg.mbt/blob/b51e271aaefa5aa06a065473245ad52219a9f5f9/compiler/session.mbt#L19
- Actual test bodies read (not executed):
  - `api_test.mbt:17` — **default tracer logs rule events** — https://github.com/bobzhang/peg.mbt/blob/b51e271aaefa5aa06a065473245ad52219a9f5f9/api_test.mbt#L17
  - `api_test.mbt:29` — **custom tracer receives tracing events** — https://github.com/bobzhang/peg.mbt/blob/b51e271aaefa5aa06a065473245ad52219a9f5f9/api_test.mbt#L29
  - `compiler/pass_fixture_test.mbt:1534` — **compiler passes match PEG.js** — https://github.com/bobzhang/peg.mbt/blob/b51e271aaefa5aa06a065473245ad52219a9f5f9/compiler/pass_fixture_test.mbt#L1534
- Published release vs pinned HEAD (local byte comparison): `README.md`: different; `README.mbt.md`: byte-identical; `pkg.generated.mbti`: byte-identical; `vm/parser.mbt`: byte-identical; `compiler/pass_checks.mbt`: byte-identical; `compiler/pass_generate_bytecode.mbt`: byte-identical; `compiler/session.mbt`: byte-identical; `api_test.mbt`: byte-identical; `compiler/pass_fixture_test.mbt`: byte-identical.

## kokic/talcparsec

- Official docs: https://mooncakes.io/docs/kokic/talcparsec
- Fixed source root: `C:/Users/42673/.codex/competition-deliverables/LuoYunze-nuist/replacement-research/additional-parsing-evidence/kokic__talcparsec/github/talcparsec-39f787c6d2d5a158f1657eebf61b54edcaae7943`
- Pin: `C:/Users/42673/.codex/competition-deliverables/LuoYunze-nuist/replacement-research/additional-parsing-evidence/kokic__talcparsec/pin.json`
- Actual implementation/API evidence:
  - `input.mbt:21` — https://github.com/kokic/talcparsec/blob/39f787c6d2d5a158f1657eebf61b54edcaae7943/input.mbt#L21
  - `parser.mbt:12` — https://github.com/kokic/talcparsec/blob/39f787c6d2d5a158f1657eebf61b54edcaae7943/parser.mbt#L12
  - `parser.mbt:21` — https://github.com/kokic/talcparsec/blob/39f787c6d2d5a158f1657eebf61b54edcaae7943/parser.mbt#L21
  - `combinator.mbt:331` — https://github.com/kokic/talcparsec/blob/39f787c6d2d5a158f1657eebf61b54edcaae7943/combinator.mbt#L331
  - `repetition.mbt:13` — https://github.com/kokic/talcparsec/blob/39f787c6d2d5a158f1657eebf61b54edcaae7943/repetition.mbt#L13
- Actual test bodies read (not executed):
  - `parser_test.mbt:41` — **choice does not backtrack committed consumption** — https://github.com/kokic/talcparsec/blob/39f787c6d2d5a158f1657eebf61b54edcaae7943/parser_test.mbt#L41
  - `parser_test.mbt:55` — **attempt enables explicit backtracking** — https://github.com/kokic/talcparsec/blob/39f787c6d2d5a158f1657eebf61b54edcaae7943/parser_test.mbt#L55
  - `parser_test.mbt:81` — **repetition rejects empty parser** — https://github.com/kokic/talcparsec/blob/39f787c6d2d5a158f1657eebf61b54edcaae7943/parser_test.mbt#L81
- Published release vs pinned HEAD (local byte comparison): `README.md`: byte-identical; `input.mbt`: byte-identical; `parser.mbt`: byte-identical; `combinator.mbt`: byte-identical; `repetition.mbt`: byte-identical; `parser_test.mbt`: byte-identical; `LICENSE`: byte-identical.
- Caveat: the test titled “method chain parses token list” uses string Input; generic-token capability is established by the public Cursor abstraction, not that test title.

## peter-jerry-ye/parser-combinator

- Official docs: https://mooncakes.io/docs/peter-jerry-ye/parser-combinator
- Fixed source root: `C:/Users/42673/.codex/competition-deliverables/LuoYunze-nuist/replacement-research/additional-parsing-evidence/peter-jerry-ye__parser-combinator/github/moonbit-parser-combinator-773e25361f397d80a4f1529c51b146e426b37a53`
- Pin: `C:/Users/42673/.codex/competition-deliverables/LuoYunze-nuist/replacement-research/additional-parsing-evidence/peter-jerry-ye__parser-combinator/pin.json`
- Actual implementation/API evidence:
  - `parsec.mbt:2` — https://github.com/peter-jerry-ye/moonbit-parser-combinator/blob/773e25361f397d80a4f1529c51b146e426b37a53/parsec.mbt#L2
  - `parsec.mbt:20` — https://github.com/peter-jerry-ye/moonbit-parser-combinator/blob/773e25361f397d80a4f1529c51b146e426b37a53/parsec.mbt#L20
  - `parsec.mbt:93` — https://github.com/peter-jerry-ye/moonbit-parser-combinator/blob/773e25361f397d80a4f1529c51b146e426b37a53/parsec.mbt#L93
  - `parsec.mbt:112` — https://github.com/peter-jerry-ye/moonbit-parser-combinator/blob/773e25361f397d80a4f1529c51b146e426b37a53/parsec.mbt#L112
  - `parsec.mbt:242` — https://github.com/peter-jerry-ye/moonbit-parser-combinator/blob/773e25361f397d80a4f1529c51b146e426b37a53/parsec.mbt#L242
  - `seq.mbt:2` — https://github.com/peter-jerry-ye/moonbit-parser-combinator/blob/773e25361f397d80a4f1529c51b146e426b37a53/seq.mbt#L2
  - `seq.mbt:74` — https://github.com/peter-jerry-ye/moonbit-parser-combinator/blob/773e25361f397d80a4f1529c51b146e426b37a53/seq.mbt#L74
- Actual test bodies read (not executed):
  - `parsec.mbt:84` — **sequence** — https://github.com/peter-jerry-ye/moonbit-parser-combinator/blob/773e25361f397d80a4f1529c51b146e426b37a53/parsec.mbt#L84
  - `parsec.mbt:276` — **repeat** — https://github.com/peter-jerry-ye/moonbit-parser-combinator/blob/773e25361f397d80a4f1529c51b146e426b37a53/parsec.mbt#L276
  - `seq.mbt:124` — **Seq from array** — https://github.com/peter-jerry-ye/moonbit-parser-combinator/blob/773e25361f397d80a4f1529c51b146e426b37a53/seq.mbt#L124
- Published release vs pinned HEAD (local byte comparison): `README.md`: byte-identical; `parsec.mbt`: byte-identical; `seq.mbt`: byte-identical.

## Uncertainty / limits
- Negative API findings are bounded to inspected interfaces/core source, not proof that arbitrary user closures/plugins cannot implement additional behavior.
- GitHub HEAD pins are not assumed to be release commits. Reviewed file equality is recorded individually; entire repositories are not asserted release-identical.
- License declarations and presence of actual license text are distinguished. Maintenance timestamps are saved API metadata, not proof of project health or toolchain compatibility.
- Tests were read only. No builds, test runs, generated-parser execution, implementation, Git/account/registry operations, or reservations were performed.

Evidence inventory and all indexed test declarations: per-module `source-file-inventory.json` / `test-catalogue.json`; these catalogues do not mean every indexed test body was inspected.
Public archive retrieval and checksum evidence: `C:/Users/42673/.codex/competition-deliverables/LuoYunze-nuist/replacement-research/additional-parsing-evidence/retrieval-ledger.json`.
