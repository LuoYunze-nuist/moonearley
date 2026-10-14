# 来源、许可证与移植边界

MoonEarley 参考 Python **Lark** 的 token-based Earley 与 packed forest 概念，
以 MoonBit 独立重写运行时 CFG 识别、符号/中间/叶节点及 packed families。
不是 Lark API、语法或功能的完整移植，没有调用 Python 解析后端。

- 上游：https://github.com/lark-parser/lark
- 阅读固定版本：`9a4fb9c7458e8155636773a3cded0016d52516da`（该树声明 Lark 1.3.1）
- 许可证：MIT；Copyright © 2017 Erez Shinan，完整文本在 `licenses/Lark-MIT.txt`。
- 参考文件：`lark/parsers/earley.py`、`earley_forest.py`；歧义与 forest transformer 测试。
- 改动：外部 token-kind 输入；自有 bounded 文法语法；显式累积预算；持久 chart 的
  transactional append/fork；不可变 report；有限/无限推导计数及有界 AST 提取。
- 未移植：Lark lexer/dynamic lexing、完整 grammar syntax、LALR、transformer/visitor API、
  错误恢复、semantic actions、Leo 优化。

标准 FIRST/FOLLOW、fixed-point、Earley deduction 与 AND/OR 图算法是独立实现。
GPL MoonYacc、AGPL talcparsec 等邻项仅为查重检查，没有复制源码或测试。
独立 span-oracle 和测试 grammar/corpus 在本项目编写，没有来源不明的 fixture。
Lark 差分脚本仅外部导入精确上游源码并比较生成输入，不把该源码打包发布。

运行时仅依赖 MoonBit core（moonbitlang/core，Apache-2.0；工具链自带，未 vendoring）。
本项目源码及原创测试/文档为 MIT。生成的 `.mbti` 是本项目编译器接口产物，
不计入实质生产代码规模。
