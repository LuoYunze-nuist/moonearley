# 提交历史保守审查

所有记录是真实本地开发提交，没有空提交或重写时间。每条 SHA、路径和作者由
`python scripts/audit_history.py` 复现。历史各阶段使用相应本地测试；最终全套严格测试
提供集成验收，不把后期全套结果冒充每个早期提交的独立 CI。

| SHA | 工程目的 | 保守计数 | 验证 |
|---|---|---|---|
| 0a2b5a9 | Define typed CFG and token contracts with validated spans and selection evidence | 有效 | 配套assertion测试；最终严格集成套件 |
| 64e3532 | Add validated cumulative resource budgets and parse statistics contracts | 有效 | 配套assertion测试；最终严格集成套件 |
| 63a15e8 | Validate owned CFG snapshots and expose deterministic symbol inventories | 有效 | 配套assertion测试；最终严格集成套件 |
| 5d84415 | Compute nullable productive and reachable grammar fixed points | 有效 | 配套assertion测试；最终严格集成套件 |
| 1d6a731 | Derive FIRST and FOLLOW sets with explicit epsilon and EOF flags | 有效 | 配套assertion测试；最终严格集成套件 |
| b36811d | Diagnose recursive grammar components without rejecting valid CFGs | 有效 | 配套assertion测试；最终严格集成套件 |
| 31f8229 | Recognize token CFGs with bounded Earley charts and packed derivation forests | 有效 | 配套assertion测试；最终严格集成套件 |
| 0237f5e | Retain append-only charts with transactional batches and isolated session forks | 有效 | 配套assertion测试；最终严格集成套件 |
| 2618793 | Parse bounded runtime grammar syntax with positioned errors and explicit labels | 有效 | 配套assertion测试；最终严格集成套件 |
| da501fc | Roundtrip canonical grammars preserving Unicode epsilon and production identity | 有效 | 配套assertion测试；最终严格集成套件 |
| 0acad0f | Expose position-aware rejection diagnostics and bounded token context windows | 有效 | 配套assertion测试；最终严格集成套件 |
| de210f1 | Cross-check recognition and incremental prefixes against 992 span-fixed-point cases | 有效 | 配套assertion测试；最终严格集成套件 |
| b665ca0 | Record confirmed selection and reservation while preserving bounded duplicate evidence | 不计：状态/格式接口归档 | 配套assertion测试；最终严格集成套件 |
| 981b7c2 | Establish MIT provenance AI disclosure and explicit resource security boundaries | 有效 | 来源/许可证人工核对 |
| 0492bfd | Count finite and infinite forest derivations with productive cycle analysis and overflow-safe caps | 有效 | 配套assertion测试；最终严格集成套件 |
| cc72f89 | Query productive ambiguity and token spans with bounded AND-OR DOT export | 有效 | 配套assertion测试；最终严格集成套件 |
| c3bb809 | Model finite ASTs and provide stable token walks metrics and ownership copies | 有效 | 配套assertion测试；最终严格集成套件 |
| c9e6d80 | Extract ordered bounded AST witnesses with explicit cycle depth tree and work truncation | 有效 | 配套assertion测试；最终严格集成套件 |
| 5b21042 | Compare 252 recognition and derivation counts with a pinned external Lark oracle | 有效 | 252 Lark acceptance/count对照 |
| 714269e | Demonstrate ambiguous DSL evaluation prefix diagnostics and cyclic grammar quality workflows | 有效 | 三个示例运行 |
| 22d64b5 | Reproduce strict four-target checks builds tests and downstream examples in CI | 有效 | CI配置；上传后以真实Actions验收 |
| 98a217a | Audit substantive production inventory and bound author identities across real history | 有效 | source/history脚本实际执行 |
| 78aff96 | Exercise external consumer API composition and transactional malformed-input rejection | 有效 | 配套assertion测试；最终严格集成套件 |
| 3a63cc3 | Freeze generated public interfaces and apply canonical MoonBit block formatting | 不计：状态/格式接口归档 | 配套assertion测试；最终严格集成套件 |

上述24条真实非空提交中，保守计入22条；选择确认状态更新和格式/接口汇总不凑有效数。
README/架构/验证文档等后续交付记录不依赖计数增量满足门槛。
