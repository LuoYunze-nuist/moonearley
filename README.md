# MoonEarley

MoonBit 运行时 CFG 解析基础库：接收调用者提供的 token，支持左递归、可空规则和歧义，
将推导保存在可查询的共享 packed forest 中，而不是提前选择一棵树。

模块：`LuoYunze-nuist/moonearley@0.1.0`。许可证：MIT。

## 安装和最小调用

```sh
moon add LuoYunze-nuist/moonearley@0.1.0
```

在消费者 `moon.pkg` 中加入：

```moonbit
import { "LuoYunze-nuist/moonearley" }
```

```moonbit
let grammar = @moonearley.parse_grammar("S -> 'name' '=' 'number';").unwrap()
let report = @moonearley.parse(grammar, [
  @moonearley.token("name", "answer", 0, 6),
  @moonearley.token("=", "=", 7, 8),
  @moonearley.token("number", "42", 9, 11),
]).unwrap()
assert_true(report.accepted())
assert_eq(report.forest().count().unwrap(), @moonearley.Finite(1))
```

`parse` 返回 `Result[Report, Problem]`。语法不接受是 `Ok(report)` 且 `accepted=false`；
非法输入或预算耗尽是 `Err`。accepted prefix 仍可有 expected terminals。
请避免在生产应用直接 unwrap 不可信输入。

## 数据模型和 API

- `Symbol::{Terminal,Nonterminal}`：名称精确、区分两种 namespace。
- `Rule {lhs,rhs,label}`：label 必须唯一；重复 rhs 不同 label 是不同推导。
- `Grammar::new` 复制输入；`analyze`、`sets`、`lint` 提供可空/可生成/可达、FIRST/FOLLOW、递归诊断。
- `Token {kind,text,start,end}`：只按 kind 匹配；text 原样保留。start/end 是调用者源坐标，
  非负单调不重叠；空跨度及间隔合法。
- `Report`：accepted、expected、furthest、statistics、diagnostic、context、forest。
- `Forest`：symbol/intermediate/token 节点，families 是有序 AND 子节点的 OR 备选。
  root/node/rule_at/token_at 均只读快照；可变数组查询返回副本。
- `count(cap?,work_limit?)`：`Finite(n)`、`AtLeast(cap)` 或 `Infinite`。
  恰好等于 cap 保持 Finite；只对生产性且从根可达的循环判 Infinite。
- `extract_trees(limits?)`：Intermediate 被展开为真实 AST 的有序 children；检查
  `truncated()` 和 status 的 tree/depth/work/cycle 标志，不能把部分结果当全集。
  对循环仅给 cycle-free 有限代表，不枚举任意循环次数的有限树。
- `reachable_nodes` / `productive_nodes` / `ambiguity_nodes` / span queries / `to_dot`。
  ambiguity 是至少两个生产性 families 的局部歧义，可以位于 Intermediate。
- `Session::new`、`push`、`push_all`、`fork`、`report`：保留已完成 chart，支持
  append-only 前缀解析，失败事务回滚。为所有权安全深拷贝，不宣称常数时间增量。

forest/tree 区间是半开 token-index 区间，与 Token 的源坐标不同。
完整可见 API：`pkg.generated.mbti`；算法约束：`docs/architecture/design.md`。

## 文法前端

```text
@start E;
E -> ['add'] E '+' E | ['number'] 'n' | ['empty'] ;
```

start directive 可省略（第一条 lhs 为 start）；空分支为 epsilon。
裸非终结符是 ASCII identifier，任意名称可双引号；terminal 和 label 单引号。
支持 `#` 行注释和引号/Unicode 转义。错误 offset 是零基 UTF-16 单位。
默认 65536 source units、4096 rules、16384 RHS symbols；`export_grammar` 保留规则顺序与标签。
不是 Lark grammar syntax，不会把裸 `epsilon` 自动当成空分支。

## 三个可运行下游场景

```sh
moon run examples/expression --target js --deny-warn
moon run examples/language_service --target js --deny-warn
moon run examples/grammar_qa --target js --deny-warn
```

1. **DSL 解释器**：`1+2*3` 外部 token → 两种完整推导 → 下游求值输出 7 和 9，
   由解释器决定优先级；库没有丢弃替代解释。
2. **语言服务**：声明前缀 → retained chart 和 expected `=` → fork 试输错误 kind
   得到源 offset 11 的诊断；原会话继续至接受，旧 report 不变化。
3. **文法 QA**：包含可空 unit cycle 及不可达 production 的 CFG → lint、Infinite
   推导计数、带 cycle_truncated 的有限见证及可视化 AND/OR DOT 图。

## 验证

```sh
moon info && moon fmt
moon fmt --check
moon check --target wasm-gc --deny-warn
moon build --target wasm-gc --deny-warn
moon test --target wasm-gc --deny-warn
python scripts/audit_sources.py --require-production 1500
python scripts/audit_history.py --minimum-nonempty 20
```

本地 Windows / moon 0.1.20261012 / moonc v0.10.15+943464bfa：
102 个命名测试在 wasm-gc、wasm、JS 各全通过；三个示例各目标运行。
独立 span-oracle 992 识别用例；固定 Lark SHA 的 252 接受性与推导数对照在 JS、wasm-gc 一致。
不是性能比较。Native 本机缺少 cc/gcc/clang，不宣称本地已执行；CI 含 native job。
当前版本测试结果与 CI 链接见仓库 Actions，实质规模和方法见 `docs/verification.md`。

外部对照（先检出固定上游，不依赖 PyPI 浮动版本）：

```sh
git clone https://github.com/lark-parser/lark ../lark-reference
git -C ../lark-reference checkout 9a4fb9c7458e8155636773a3cded0016d52516da
python scripts/reference_check.py --lark-source ../lark-reference --target js
```

## 功能边界和来源

参考 MIT Python Lark 的 Earley/packed forest 核心并独立 MoonBit 重写，不是完整 Lark 移植。
没有 lexer/dynamic lexing、ANTLR/LR codegen、错误恢复、semantic-action 引擎、Leo 优化，
不处理任意位置编辑，也不声称优于确定性解析器的性能。输入规模、文字长度及进程资源
需要调用者控制，详见 `SECURITY.md`。

完整上游版权、参考与独立测试来源：`THIRD_PARTY_NOTICES.md`、`licenses/Lark-MIT.txt`。
AI 辅助范围：`AI_USAGE.md`。查重记录：`docs/competition/duplicate-check.md`。
有限结论：**在已记录检索范围内未发现成熟直接替代**，不声称绝对不存在。

