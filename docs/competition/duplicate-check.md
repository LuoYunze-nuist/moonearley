# 新项目三域候选复核（研究阶段）

日期：2026-10-14（Asia/Shanghai）。固定截止日期：2026-10-30 24:00。绑定账号：LuoYunze-nuist。本文件不是项目预留、实现、验收报告或申报书。

## 授权边界

保留用户原先明确的具体选题确认门禁：展示排序候选后，取得明确方向选择前，不追加新项目指纹，不初始化目标仓库，不写实现、不提交、不建远程或发布。最近的“继续/再搞一个”用于继续研究，不能冒充对 MoonEarley 这个具体方向的确认。账号统一按用户后来更正的 LuoYunze-nuist；不修改全局 Git 身份、不读取或展示凭据、不切换共享登录。旧 MoonQP、迁移副本和工作区其他文件不变。

## 三个不同问题域：广度与工作流

| 排序 | 预选方向 | 三类下游及完整核心工作流 | 复用契约 | 当前结论 |
|---|---|---|---|---|
| 1 | MoonEarley：运行时 CFG 与共享压缩解析森林 | DSL 解释器：规则与 token→保留所有推导→选择并求值；编辑器/语言服务：token 前缀→增量识别→可接受性及期望 token；语法 QA/工具链：CFG→可空/可生成/可达分析和解析森林→歧义证据及有界树提取 | Grammar/Rule/Symbol/Token/Forest、诊断、资源限制与有界遍历；不依赖网站、厂商或单一 DSL | 推荐；在已记录检索范围内未发现成熟直接替代 |
| 2 | Apache Thrift Binary/Compact 与 RPC 消息封装 | 服务客户端：值→编码→RPC 请求；网关：消息→解码/校验→协议转发；测试工具：golden 字节→双向互操作→差异报告 | 稳定值模型、线协议与消息头 | 淘汰，直接替代 |
| 3 | Reed–Solomon GF(256) 纠删码 | 对象存储：数据→k+m 分片→缺失恢复；备份：分片损坏→校验/重构→恢复字节；分发系统：数据更新→增量校验→选择性修复 | GF(256)、分片大小/数量、校验矩阵与恢复 API | 淘汰，直接替代 |

评分仅用于工程优先级，不用总分抵消查重硬失败。各项 1–5，依次为生态广度、用户多样性、复用、重合风险低、实现深度、验证可行性、工期可行性、维护：MoonEarley=5/4/5/3/5/4/3/4（33）；Thrift=5/5/5/1/4/5/4/4（33）；GF256=5/5/5/1/4/5/4/4（33）。MoonEarley 的森林/可空循环正确性风险高于其余两项，需要专项验证；其余两项即使高分仍淘汰。

## 检索覆盖与限制

已保存 moon search --limit 100 的多域、中英文同义词检索原始输出，包括 thrift/rpc/compact protocol/parquet，reed solomon/erasure/fec，以及 earley/generalized parser/grammar/chart parsing/parse forest/GLR/GLL/CYK/context free/lark/predict complete/parser combinator/sppf/nullable grammar/chart recognizer/上下文无关/歧义解析/LALR。

GitHub 的 earley/GLR/parse forest/context-free MoonBit 仓库与 earley/sppf/parse_forest 代码查询已保存，检索返回空列表不证明不存在。读取官方 awesome-moonbit 清单，追踪 MoonYacc。MoonCakes 模糊检索有大量不相关命中，逐一按真实任务而不是包名评估；核心高相邻项检查 README、API、实际实现与代表测试。

已按域复核永久 project-registry.md 中相关条目/指纹，包含 MoonShard、MoonPeg、MoonCite、MoonPhone、MoonQP 与解析相关目录项。MoonPeg 的核心是 peg solitaire，不是 Parsing Expression Grammar。没有以“不重名”作通过理由。研究阶段不写注册表；若后续选择本方向，须在固定排他锁内重读再预留，不能用本次快照覆盖其他窗口新记录。

限制：仅覆盖当时可查询的公开索引、已保存的固定 SHA 源码与精确版本元数据；不保证覆盖未公开、未索引、尚未发布项目。GitHub HEAD 不冒充发布 ZIP；源码/测试阅读不冒充执行通过。公开网页搜索未返回可用结果，结论依靠已保存 CLI、官方 API、源码与测试证据。

## MoonEarley 与已完成关键邻项比较

| 邻项 / 版本 / 固定 SHA | 实际行为证据 | 相邻程度与独立边界 |
|---|---|---|
| Nanaloveyuki/parsec@0.1.4 / 87da54c7942588bb3c780b78f2a0928d33abe0ad | src/choice.mbt 的 or_else 返回首个成功结果，attempt 处理回溯；reference.mbt 递归绑定；parsec_test.mbt 验证单结果/错误 | 高相邻的 token 通用组合子； inspected 行为并非公开 CFG 全推导森林 API |
| cogna-dev/parkit@0.1.1 / bc620c2168b54400bb6a152a7caeea4470514dcb | src/antlr/runtime/parser.mbt 实现替代评分与最佳 ParserMatch；result.mbt 返回事件、诊断、ambiguities 计数；parsercheck.mbt 包含实际快照测试 | 高相邻且功能实质完整的 nom/ANTLR 工具链，不能称小组合子；核心最佳路径+计数与保留全部 packed families 的可查询森林不同 |
| moonbitlang/moonyacc / 73dbc071b69a38400df4a12beccaf0d73363ee96 | lr1/resolve_conflicts.mbt 按优先级/结合性与规则顺序选动作；resolve_conflicts_test.mbt 和 parse_test.mbt 验证冲突及单栈解析 | 高相邻生成式 LR 工具链；不复制 GPL-2.0 代码。运行时 CFG+显式森林与生成后单一动作解析契约不同 |
| erzhuzi259/moongrammata@0.1.1 / d9cf3512b636fd45e941f30010d3fceb7cc2e4fc | grammar.mbt/grammar_test.mbt：Literal/Integer/Sequence/Choice/Repeat/Reference，带权生成、变异、语料与 replay | 同方向不同任务：生成测试输入而不是识别 token 与保留推导；不把 fuzz 框架写成本项目核心 |
| mizchi/nom@0.1.3 精确发布源码 | src/branch.mbt 的 alt/alt2 返回首个成功；combinator.mbt、pkg.generated.mbti；str/streaming_test.mbt 的 tag/take 不完整输入测试 | 高相邻组合子/流式输入；流式缓冲并不等于 CFG chart 会话或公开全部推导森林 |
| tonyfettes/tree_sitter@0.4.6 精确发布源码 | README；src/parser.native.mbt 调用 C parser，set_language 处理预编译 Language ABI；parse_string 返回 Tree | 高相邻增量语法树工具；已编译语言+单一 Tree 与运行时 CFG+全部推导森林任务不同。未运行其 native 代码；发布包中未找到对应 parser 测试，不虚构测试证据 |
| bobzhang/bap@0.4.0 精确发布源码 | README/API 表明 binary loading/lifting/BIL/BIR/Primus | 模糊搜索命中，不是 CFG 解析森林直接替代；链接仓库 404 不被解释成无人维护 |
| Juwan-Hwang/moon-certified@0.1.1 / 94dd850ce24db5610e720035d5bdb1ecb2923e43 | 递归 tree 元数据 truncated=false，未找到 parser/grammar/Earley 相关路径 | 模糊搜索命中；不以目录检索代替全仓源码不存在证明。其 optimization/kkt 已使旧 MoonQP 选题失败 |

补充四项已完成 README/API/核心源码/代表测试和精确发布内容比较，证据见 additional-parsing-evidence/source-evidence-matrix.md 与 JSON。主代理另行复核 moonabnf 的 recognizer.mbt/ compiler_test.mbt 和 talcparsec 的 choice 实现。

| 补充邻项 / 固定 SHA | 实际行为及测试 | 独立边界 |
|---|---|---|
| sundaysebasidian-byte/moonabnf@0.1.0 / 323a3728c3faac0ca1052fb8f7590e98ee040156 | runtime byte ABNF；Choice 保留不同结束 offset，不保留不同推导身份。compiler_test 的 productive and nullable-prefix cycles are diagnosed 明确拒绝 x=x/"a" 及 nullable-prefix 递归 | 高相邻；不能说它只是 ordered-choice。森林、接受左递归的固定点、token 模型才是实质差异，ABNF =/ 不是 token append 会话 |
| bobzhang/peg@0.1.0 / b51e271aaefa5aa06a065473245ad52219a9f5f9 | runtime generate(grammar)→String 单结果；VM/bytecode ordered-choice；compiler passes match PEG.js 实际测试；Session 配置 compiler/plugin | 高相邻；不能以 runtime grammar 作为独有性；公开单结果契约并不保留全部推导。MIT 仅声明，未发现独立许可文本，不复制其代码 |
| kokic/talcparsec@0.4.0 / 39f787c6d2d5a158f1657eebf61b54edcaae7943 | Cursor 支持自定义 token；choice 第一个 Ok 或 committed Err 停止；实际回溯/重复空输入测试 | 高相邻；不能以外部 token 作为独有性。AGPL-3.0 许可文本已读，仅查重不复制 |
| peter-jerry-ye/parser-combinator@0.9.1 / 773e25361f397d80a4f1529c51b146e426b37a53 | Seq[Token]→(Value,Seq)? 单结果；or_else 首个 Some；sequence/repeat/Seq from array 测试；仓库 archived | 高相邻；lazy Seq 不是 retained chart/forest append session。Apache-2.0 仅声明，未发现独立许可文本，不复制其代码 |

MoonEarley 核心不是把几个现成辅助功能拼成“全套缺失”来声称新颖，而是让运行时 CFG 的合法推导作为公开共享压缩图保留，允许下游查询、计数与有界提取；这是已检查邻项的实际结果契约未覆盖的主要任务。辅助分析和前缀诊断均有其他相邻实现，不声称独有。

推荐方向查重结论：**在已记录检索范围内未发现成熟直接替代**。这是有限范围研究判断，不是赛事裁决或对整个生态的不存在证明。

## 推荐方向功能边界（尚未实现）

核心必须是外部 token 上的运行时 CFG 接受性与可查询共享压缩森林。支持左递归、可空规则和歧义；维护节点/packed family 资源预算；有界树提取与有限计数，正确区别生产性循环造成的无限推导；快照避免调用者数组变更污染结果。可空 completion 顺序与循环终止是正确性关键，而不是性能宣传。

三个交付示例分别覆盖表达式 DSL 的歧义/求值、前缀会话诊断、语法质量/森林分析。明确不做 lexer/dynamic lexing、完整 Lark 语法兼容、ANTLR/MoonYacc 生成器、错误恢复、语义动作引擎、Leo 优化或无实测的高性能承诺。算法名称不同本身不构成独立价值。

独立建设理由：保存并允许下游查询/计数/提取全部合法推导，是不同于先选最佳路径的输出契约；简单包裹既有组合子或单树 parser 无法恢复已经丢弃的推导。已有生成式解析/组合子工具仍更适合其任务，不宣称取代它们。若补充检查发现实际森林直接替代，应撤回推荐而不是缩到冷门子集。

## 上游许可与移植来源

Python Lark（lark-parser/lark），固定 SHA 9a4fb9c7458e8155636773a3cded0016d52516da，MIT，Copyright © 2017 Erez Shinan。已读 LICENSE、lark/parsers/earley.py、earley_forest.py 的 SymbolNode/PackedNode，以及 tests/test_parser.py 的 test_earley_explicit_ambiguity、test_ambiguity1 和 tests/test_tree_forest_transformer.py 的身份/歧义转换测试。

未来实现采用独立 MoonBit 重写其核心思路，不复制 GPL MoonYacc/AGPL 邻项代码；保留 Lark 许可与版权说明，明确只覆盖 token-based CFG/森林，不宣称完整 Lark 移植。对照测试固定上游版本与环境，实测后才记录数量/时间。本阶段未执行这些第三方测试，也没有项目实现测试可报告。

## 淘汰证据

Thrift 与 GF256 的完整固定 SHA、实际 API/源码/测试、精确发布 ZIP 校验和、维护与服务端 CI 信号见 rejected-candidates/source-evidence-matrix.md 及 JSON。Xpeng/moonthrift 与 zhaojun-coding/thrift 已覆盖所拟 Binary/Compact/RPC 核心；oyjh0381/moonerasure 已覆盖系统 GF256 k+m 编码/恢复、选择性恢复、增量校验。CAIMEOX/reed_solomon 是 GF32 码字纠错，不能用作 GF256 的直接淘汰依据。

## 当前状态

本轮仅研究证据；新目标目录/仓库、指纹预留、实现、提交、远程、CI、Release 和 MoonCakes 发布均未进行。中文申报书也尚未生成。交付前必须重跑查重、身份绑定、实现与工程门禁，不用本研究结论代替验收。
