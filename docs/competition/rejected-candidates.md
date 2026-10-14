> Historical source-inspection snapshot; later implementation and execution are recorded separately.

# Rejected replacement candidates — public source evidence

Research snapshot: 2026-10-14 (Asia/Shanghai). Source and test bodies were read; **no tests, builds, Moon commands, implementation, commits, account operations or registry writes were performed**. Only the four requested known hits were investigated. No MoonEarley or additional domain research.

## Decision matrix

| Candidate | Existing substitute | Decision |
|---|---|---|
| Apache Thrift Binary/Compact codec + RPC envelopes | Xpeng/moonthrift@0.4.0; zhaojun-coding/thrift@0.7.0 | Reject: direct public APIs, actual codecs/envelopes, golden-byte tests and recent successful exact-HEAD CI already exist. |
| Reed-Solomon GF(256) erasure coding | oyjh0381/moonerasure@0.2.0 | Reject: systematic GF(256) shard encoding/recovery, selective reconstruction and incremental parity updates already exist. |
| GF(256) comparison boundary | CAIMEOX/reed_solomon@0.1.0 | Adjacent GF(32) codeword correction, not the direct rejection basis. |

## Xpeng/moonthrift@0.4.0

**Classification:** Direct substitute; reject the proposed standalone Binary/Compact codec and RPC-envelope candidate.

- Official docs: https://mooncakes.io/docs/Xpeng/moonthrift
- Official manifest endpoint: https://mooncakes.io/api-new/v0/manifest/Xpeng/moonthrift
- Published source ZIP: https://download.mooncakes.io/user/Xpeng/moonthrift/0.4.0.zip
- ZIP SHA256 (matches official manifest): `9f055d7f26b5ad1706247eeb4eaf2a2a88d5145b5094cf28d6bd49a01c0de1bf`
- Linked repository: https://github.com/pxgt/moonthrift
- Fixed inspected HEAD: `8df1fee5624700a9e299033d5573c9e7f9fa971a` (commit 2026-09-30T02:17:19Z); default branch `main`; archived=false.
- Registry publication timestamp: 2026-09-29T15:53:12.319603+00:00; build_status=success; yanked=false.

**API:** protocol/pkg.generated.mbti: encode_binary, decode_binary, encode_compact, decode_compact, encode_binary_message, decode_binary_message, encode_compact_message, decode_compact_message; Message contains method name, MessageType, sequence_id and struct body.

**Actual implementation:** protocol/binary.mbt implements big-endian primitives and recursive values/containers; protocol/compact.mbt implements ZigZag/varints, delta field headers and compact containers; protocol/message.mbt implements strict Binary version 1 and Compact 0x82 message headers. rpc/frame.mbt and rpc/runtime.mbt add framed transport and portable single-exchange RPC.

**Actual test evidence (declarations indexed; representative bodies read; none executed):**
- `binary protocol matches a known struct fixture` — protocol/binary_test.mbt:2 — https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/protocol/binary_test.mbt#L2
- `compact protocol matches a known struct fixture` — protocol/compact_test.mbt:2 — https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/protocol/compact_test.mbt#L2
- `binary message envelope matches strict protocol bytes` — protocol/message_test.mbt:2 — https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/protocol/message_test.mbt#L2
- `compact message envelope round-trips unicode name and body` — protocol/message_test.mbt:17 — https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/protocol/message_test.mbt#L17

**License:** Apache-2.0 in manifest and LICENSE; THIRD_PARTY.md records Apache Thrift specification/interoperability references.

**Maintenance:**
- Public GitHub Actions reports success for CI at exact SHA `8df1fee5624700a9e299033d5573c9e7f9fa971a`: https://github.com/pxgt/moonthrift/actions/runs/36659150928. This is server-reported CI, not a local test run.

**Boundaries:** Strict Binary headers only; missing HTTP/Header/JSON transport and long-lived concurrent server are broader runtime gaps, not differentiation for this candidate.

**Published ZIP vs inspected HEAD:** {"byte-identical": 129, "different": 6}. Comparison covers files present in the published ZIP; CRLF/LF-only differences are separately classified. Different files: CHANGELOG.md, README.md, docs/award-roadmap.md, docs/maintenance-evidence.md, docs/protocols.md, docs/public-api.md. The exact publication is not falsely equated to HEAD; core .mbt files match bytes or newline normalization.

**Fixed-SHA source URLs and local paths:**
- `README.md`: https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/README.md — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\github\moonthrift-8df1fee5624700a9e299033d5573c9e7f9fa971a\README.md`
- `protocol/pkg.generated.mbti`: https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/protocol/pkg.generated.mbti — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\github\moonthrift-8df1fee5624700a9e299033d5573c9e7f9fa971a\protocol\pkg.generated.mbti`
- `protocol/binary.mbt`: https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/protocol/binary.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\github\moonthrift-8df1fee5624700a9e299033d5573c9e7f9fa971a\protocol\binary.mbt`
- `protocol/compact.mbt`: https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/protocol/compact.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\github\moonthrift-8df1fee5624700a9e299033d5573c9e7f9fa971a\protocol\compact.mbt`
- `protocol/message.mbt`: https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/protocol/message.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\github\moonthrift-8df1fee5624700a9e299033d5573c9e7f9fa971a\protocol\message.mbt`
- `rpc/frame.mbt`: https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/rpc/frame.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\github\moonthrift-8df1fee5624700a9e299033d5573c9e7f9fa971a\rpc\frame.mbt`
- `rpc/runtime.mbt`: https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/rpc/runtime.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\github\moonthrift-8df1fee5624700a9e299033d5573c9e7f9fa971a\rpc\runtime.mbt`
- `LICENSE`: https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/LICENSE — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\github\moonthrift-8df1fee5624700a9e299033d5573c9e7f9fa971a\LICENSE`
- `THIRD_PARTY.md`: https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/THIRD_PARTY.md — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\github\moonthrift-8df1fee5624700a9e299033d5573c9e7f9fa971a\THIRD_PARTY.md`
- `.github/workflows/ci.yml`: https://github.com/pxgt/moonthrift/blob/8df1fee5624700a9e299033d5573c9e7f9fa971a/.github/workflows/ci.yml — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\github\moonthrift-8df1fee5624700a9e299033d5573c9e7f9fa971a\.github\workflows\ci.yml`

Local official artifacts: `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\mooncakes-manifest.json`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\mooncakes-docs.html`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\mooncakes-transcript.json`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\mooncakes-published.zip`. Full test declaration inventory: `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\Xpeng--moonthrift\test-catalogue.json`; inventory is not a count of executed/passing tests.

## zhaojun-coding/thrift@0.7.0

**Classification:** Direct codec/envelope overlap plus an upstream-dependent RPC-session extension; corroborating rejection evidence, not an independent blank ecosystem area.

- Official docs: https://mooncakes.io/docs/zhaojun-coding/thrift
- Official manifest endpoint: https://mooncakes.io/api-new/v0/manifest/zhaojun-coding/thrift
- Published source ZIP: https://download.mooncakes.io/user/zhaojun-coding/thrift/0.7.0.zip
- ZIP SHA256 (matches official manifest): `f78820cabe7cb3d3fec1f85f06e44558f6ab42a4f41ac588e0f66a4292dd5795`
- Linked repository: https://github.com/zhaojun-coding/moonbit-thrift
- Fixed inspected HEAD: `bc1775391570219eb877d7476abc00fcc9d13d97` (commit 2026-09-29T15:05:03Z); default branch `main`; archived=false.
- Registry publication timestamp: 2026-09-28T16:35:08.238912+00:00; build_status=success; yanked=false.

**API:** pkg.generated.mbti: encode/decode, encode_message/decode_message, MessageCodec, FrameDecoder, FrameStream and Client (call, feed, finish, abort, pending_calls).

**Actual implementation:** encode.mbt and decode.mbt contain actual scalar/container Binary/Compact codecs, not only declarations; message.mbt supplies RPC serialization; message_codec.mbt validates envelope/body/type/name/resource bounds; client.mbt correlates in-flight requests. moonthrift/adapter.mbt and moonthrift/framing.mbt adapt upstream Xpeng/moonthrift@0.3.0. README explicitly acknowledges shared codec/IDL scope.

**Actual test evidence (declarations indexed; representative bodies read; none executed):**
- `strict Binary and Compact RPC golden envelopes` — message_test.mbt:2 — https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/message_test.mbt#L2
- `client correlation reverse response order exceptions and oneway` — client_test.mbt:2 — https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/client_test.mbt#L2
- `Apache Python 0.22.0 BinaryProtocol vector 0` — apache_vectors_test.mbt:5 — https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/apache_vectors_test.mbt#L5
- `Apache Python 0.22.0 CompactProtocol vector 0` — apache_vectors_test.mbt:25 — https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/apache_vectors_test.mbt#L25

**License:** Registry/module declare MIT AND Apache-2.0; root LICENSE is MIT; upstream Xpeng/moonthrift is Apache-2.0. These are distinct provenance layers, not a claim the root license text is Apache.

**Maintenance:**
- Public GitHub Actions reports success for MoonBit quality checks at exact SHA `bc1775391570219eb877d7476abc00fcc9d13d97`: https://github.com/zhaojun-coding/moonbit-thrift/actions/runs/36652035083. This is server-reported CI, not a local test run.

**Boundaries:** README limits upstream mode to strict Binary/Compact, excludes UUID/legacy Binary in that mode, and assigns TCP/TLS scheduling to Node host adapters. Existing builtin codecs remain present.

**Published ZIP vs inspected HEAD:** {"byte-identical": 146, "newline-only": 39, "different": 4}. Comparison covers files present in the published ZIP; CRLF/LF-only differences are separately classified. Different files: PROPOSAL.md, README.md, REVIEW-RESPONSE.md, SUBMISSION.json. The exact publication is not falsely equated to HEAD; core .mbt files match bytes or newline normalization.

**Fixed-SHA source URLs and local paths:**
- `README.md`: https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/README.md — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\github\moonbit-thrift-bc1775391570219eb877d7476abc00fcc9d13d97\README.md`
- `pkg.generated.mbti`: https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/pkg.generated.mbti — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\github\moonbit-thrift-bc1775391570219eb877d7476abc00fcc9d13d97\pkg.generated.mbti`
- `encode.mbt`: https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/encode.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\github\moonbit-thrift-bc1775391570219eb877d7476abc00fcc9d13d97\encode.mbt`
- `decode.mbt`: https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/decode.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\github\moonbit-thrift-bc1775391570219eb877d7476abc00fcc9d13d97\decode.mbt`
- `message.mbt`: https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/message.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\github\moonbit-thrift-bc1775391570219eb877d7476abc00fcc9d13d97\message.mbt`
- `message_codec.mbt`: https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/message_codec.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\github\moonbit-thrift-bc1775391570219eb877d7476abc00fcc9d13d97\message_codec.mbt`
- `client.mbt`: https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/client.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\github\moonbit-thrift-bc1775391570219eb877d7476abc00fcc9d13d97\client.mbt`
- `moonthrift/adapter.mbt`: https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/moonthrift/adapter.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\github\moonbit-thrift-bc1775391570219eb877d7476abc00fcc9d13d97\moonthrift\adapter.mbt`
- `moonthrift/framing.mbt`: https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/moonthrift/framing.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\github\moonbit-thrift-bc1775391570219eb877d7476abc00fcc9d13d97\moonthrift\framing.mbt`
- `LICENSE`: https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/LICENSE — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\github\moonbit-thrift-bc1775391570219eb877d7476abc00fcc9d13d97\LICENSE`
- `THIRD-PARTY-NOTICES.md`: https://github.com/zhaojun-coding/moonbit-thrift/blob/bc1775391570219eb877d7476abc00fcc9d13d97/THIRD-PARTY-NOTICES.md — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\github\moonbit-thrift-bc1775391570219eb877d7476abc00fcc9d13d97\THIRD-PARTY-NOTICES.md`

Local official artifacts: `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\mooncakes-manifest.json`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\mooncakes-docs.html`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\mooncakes-transcript.json`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\mooncakes-published.zip`. Full test declaration inventory: `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\zhaojun-coding--thrift\test-catalogue.json`; inventory is not a count of executed/passing tests.

## oyjh0381/moonerasure@0.2.0

**Classification:** Direct substitute; reject the proposed GF(256) Reed-Solomon erasure-code candidate.

- Official docs: https://mooncakes.io/docs/oyjh0381/moonerasure
- Official manifest endpoint: https://mooncakes.io/api-new/v0/manifest/oyjh0381/moonerasure
- Published source ZIP: https://download.mooncakes.io/user/oyjh0381/moonerasure/0.2.0.zip
- ZIP SHA256 (matches official manifest): `eceea1ef297f0692772f7c54ad47cdbf36bcdc7bc544db4d18c57cd85025cd37`
- Linked repository: https://github.com/oyjh0381/MoonErasure
- Fixed inspected HEAD: `5ca10e5527c07d8c4969dd0797186e74a887236d` (commit 2026-10-13T12:35:18Z); default branch `main`; archived=false.
- Registry publication timestamp: 2026-10-13T12:49:19.116423+00:00; build_status=success; yanked=false.

**API:** pkg.generated.mbti: Codec::new, encode, encode_all, verify, reconstruct, reconstruct_selected, update_parity and plan, plus object/frame/range-repair and recovery-session interfaces.

**Actual implementation:** field.mbt builds 512-entry exponent and 256-entry logarithm tables using irreducible polynomial 0x11d and generator 2; matrix.mbt builds a systematic Vandermonde matrix and uses Gauss-Jordan inversion; codec.mbt performs bytewise matrix parity and recovery from selected available shards; selective_recovery.mbt implements requested-index recovery; parity_update.mbt applies old/new-data deltas to parity.

**Actual test evidence (declarations indexed; representative bodies read; none executed):**
- `two missing data shards recover from parity` — codec_test.mbt:2 — https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/codec_test.mbt#L2
- `field multiplication and inverses cover every nonzero byte` — field_wbtest.mbt:2 — https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/field_wbtest.mbt#L2
- `selected recovery agrees with full codewords for every small erasure pattern` — selective_recovery_test.mbt:2 — https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/selective_recovery_test.mbt#L2
- `delta parity agrees with full encoding for every subset of changed data` — parity_update_test.mbt:2 — https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/parity_update_test.mbt#L2

**License:** Apache-2.0 in manifest and LICENSE; THIRD_PARTY_NOTICES.md documents algorithm/reference boundaries.

**Maintenance:**
- Public GitHub Actions reports success for Generate reference vectors at exact SHA `5ca10e5527c07d8c4969dd0797186e74a887236d`: https://github.com/oyjh0381/MoonErasure/actions/runs/38400507911. This is server-reported CI, not a local test run.
- Public GitHub Actions reports success for MoonBit CI at exact SHA `5ca10e5527c07d8c4969dd0797186e74a887236d`: https://github.com/oyjh0381/MoonErasure/actions/runs/38400507906. This is server-reported CI, not a local test run.

**Boundaries:** Known-erasure recovery, not arbitrary unknown-error correction. Equal-length shards; 1..255 data/parity individually, total <=256; bounded encoded-byte budget. These are normal erasure-code boundaries, not evidence of an unfilled basic codec gap.

**Published ZIP vs inspected HEAD:** {"newline-only": 118, "byte-identical": 1}. Comparison covers files present in the published ZIP; CRLF/LF-only differences are separately classified. Different files: none. The exact publication is not falsely equated to HEAD; core .mbt files match bytes or newline normalization.

**Fixed-SHA source URLs and local paths:**
- `README.md`: https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/README.md — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\github\MoonErasure-5ca10e5527c07d8c4969dd0797186e74a887236d\README.md`
- `pkg.generated.mbti`: https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/pkg.generated.mbti — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\github\MoonErasure-5ca10e5527c07d8c4969dd0797186e74a887236d\pkg.generated.mbti`
- `field.mbt`: https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/field.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\github\MoonErasure-5ca10e5527c07d8c4969dd0797186e74a887236d\field.mbt`
- `matrix.mbt`: https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/matrix.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\github\MoonErasure-5ca10e5527c07d8c4969dd0797186e74a887236d\matrix.mbt`
- `codec.mbt`: https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/codec.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\github\MoonErasure-5ca10e5527c07d8c4969dd0797186e74a887236d\codec.mbt`
- `selective_recovery.mbt`: https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/selective_recovery.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\github\MoonErasure-5ca10e5527c07d8c4969dd0797186e74a887236d\selective_recovery.mbt`
- `parity_update.mbt`: https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/parity_update.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\github\MoonErasure-5ca10e5527c07d8c4969dd0797186e74a887236d\parity_update.mbt`
- `LICENSE`: https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/LICENSE — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\github\MoonErasure-5ca10e5527c07d8c4969dd0797186e74a887236d\LICENSE`
- `THIRD_PARTY_NOTICES.md`: https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/THIRD_PARTY_NOTICES.md — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\github\MoonErasure-5ca10e5527c07d8c4969dd0797186e74a887236d\THIRD_PARTY_NOTICES.md`
- `.github/workflows/ci.yml`: https://github.com/oyjh0381/MoonErasure/blob/5ca10e5527c07d8c4969dd0797186e74a887236d/.github/workflows/ci.yml — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\github\MoonErasure-5ca10e5527c07d8c4969dd0797186e74a887236d\.github\workflows\ci.yml`

Local official artifacts: `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\mooncakes-manifest.json`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\mooncakes-docs.html`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\mooncakes-transcript.json`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\mooncakes-published.zip`. Full test declaration inventory: `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\oyjh0381--moonerasure\test-catalogue.json`; inventory is not a count of executed/passing tests.

## CAIMEOX/reed_solomon@0.1.0

**Classification:** Adjacent error-correction implementation, NOT a direct GF(256) byte-shard substitute. Do not use it alone to reject the GF(256) candidate.

- Official docs: https://mooncakes.io/docs/CAIMEOX/reed_solomon
- Official manifest endpoint: https://mooncakes.io/api-new/v0/manifest/CAIMEOX/reed_solomon
- Published source ZIP: https://download.mooncakes.io/user/CAIMEOX/reed_solomon/0.1.0.zip
- ZIP SHA256 (matches official manifest): `ce43a7aa04de455029ede5e89a04645ef34a8ef1151238908b2289ef8cca74b2`
- Linked repository: https://github.com/CAIMEOX/reed_solomon
- Fixed inspected HEAD: `6bd7e05c300930d4df71c2867f77bec1f01a7a46` (commit 2025-10-31T08:22:21Z); default branch `main`; archived=false.
- Registry publication timestamp: 2025-10-31T08:23:42.515075+00:00; build_status=legacy; yanked=false.

**API:** src/encoder.mbt: encode(ArrayView[Int], Int) -> Result[Buffer, UsageError]; src/decoder.mbt: correct, correct_err_count, is_corrupted, including optional erase_pos. Official module_index.json exposes package CAIMEOX/reed_solomon/src.

**Actual implementation:** README specifies GF(2^5). src/poly.mbt sets FIELD_SYMBOL_MAX and POLYNOMIAL_MAX_LENGTH to 31, uses 32-symbol log tables and modulus 31. src/encoder.mbt generates polynomial parity; src/decoder.mbt implements syndrome/error-locator/Forney-style correction. This is short symbol-codeword correction, not GF(256) storage-shard matrix coding.

**Actual test evidence (declarations indexed; representative bodies read; none executed):**
- `encode computes expected ecc` — src/test_rs.mbt:13 — https://github.com/CAIMEOX/reed_solomon/blob/6bd7e05c300930d4df71c2867f77bec1f01a7a46/src/test_rs.mbt#L13
- `correct repairs message` — src/test_rs.mbt:29 — https://github.com/CAIMEOX/reed_solomon/blob/6bd7e05c300930d4df71c2867f77bec1f01a7a46/src/test_rs.mbt#L29
- `is_corrupted identifies errors` — src/test_rs.mbt:48 — https://github.com/CAIMEOX/reed_solomon/blob/6bd7e05c300930d4df71c2867f77bec1f01a7a46/src/test_rs.mbt#L48
- `correct_err_count reports number of fixes` — src/test_rs.mbt:74 — https://github.com/CAIMEOX/reed_solomon/blob/6bd7e05c300930d4df71c2867f77bec1f01a7a46/src/test_rs.mbt#L74

**License:** Apache-2.0 in manifest and LICENSE. README says it mirrors a Rust crate but does not identify a specific crate/revision in the inspected README; that provenance detail remains unclear.

**Maintenance:**
- No exact-HEAD workflow runs returned. No workflow files in the inspected source snapshot.

**Boundaries:** Legacy registry documentation (build_status=legacy, has_package=false) still supplies index/docs and an available source ZIP; no retrieved exact-HEAD Actions runs or .github/workflows files. Do not infer tests fail or repo abandonment from that absence.

**Published ZIP vs inspected HEAD:** {"byte-identical": 8}. Comparison covers files present in the published ZIP; CRLF/LF-only differences are separately classified. Different files: none. The exact publication is not falsely equated to HEAD; core .mbt files match bytes or newline normalization.

**Fixed-SHA source URLs and local paths:**
- `README.md`: https://github.com/CAIMEOX/reed_solomon/blob/6bd7e05c300930d4df71c2867f77bec1f01a7a46/README.md — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\github\reed_solomon-6bd7e05c300930d4df71c2867f77bec1f01a7a46\README.md`
- `src/poly.mbt`: https://github.com/CAIMEOX/reed_solomon/blob/6bd7e05c300930d4df71c2867f77bec1f01a7a46/src/poly.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\github\reed_solomon-6bd7e05c300930d4df71c2867f77bec1f01a7a46\src\poly.mbt`
- `src/encoder.mbt`: https://github.com/CAIMEOX/reed_solomon/blob/6bd7e05c300930d4df71c2867f77bec1f01a7a46/src/encoder.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\github\reed_solomon-6bd7e05c300930d4df71c2867f77bec1f01a7a46\src\encoder.mbt`
- `src/decoder.mbt`: https://github.com/CAIMEOX/reed_solomon/blob/6bd7e05c300930d4df71c2867f77bec1f01a7a46/src/decoder.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\github\reed_solomon-6bd7e05c300930d4df71c2867f77bec1f01a7a46\src\decoder.mbt`
- `src/test_rs.mbt`: https://github.com/CAIMEOX/reed_solomon/blob/6bd7e05c300930d4df71c2867f77bec1f01a7a46/src/test_rs.mbt — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\github\reed_solomon-6bd7e05c300930d4df71c2867f77bec1f01a7a46\src\test_rs.mbt`
- `src/moon.pkg.json`: https://github.com/CAIMEOX/reed_solomon/blob/6bd7e05c300930d4df71c2867f77bec1f01a7a46/src/moon.pkg.json — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\github\reed_solomon-6bd7e05c300930d4df71c2867f77bec1f01a7a46\src\moon.pkg.json`
- `LICENSE`: https://github.com/CAIMEOX/reed_solomon/blob/6bd7e05c300930d4df71c2867f77bec1f01a7a46/LICENSE — local `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\github\reed_solomon-6bd7e05c300930d4df71c2867f77bec1f01a7a46\LICENSE`

Local official artifacts: `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\mooncakes-manifest.json`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\mooncakes-docs.html`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\mooncakes-transcript.json`, `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\mooncakes-published.zip`. Full test declaration inventory: `C:\Users\42673\.codex\competition-deliverables\LuoYunze-nuist\replacement-research\rejected-candidates\CAIMEOX--reed_solomon\test-catalogue.json`; inventory is not a count of executed/passing tests.

## Limits and write-scope compliance

These rejection decisions apply to the two stated scopes, not every possible Thrift transport or coding-theory project. No exhaustive uniqueness claim is made. Registry reservations were not altered; this evidence report is not a reservation or approval of MoonEarley. Only public registry, GitHub metadata/source and research-generated indexes were saved. All persisted outputs are inside this rejected-candidates folder.

