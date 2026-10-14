# 安全与资源边界

这是 CFG 分析/解析库，不是用于执行不可信代码的沙箱。
输入 token payload 是不透明字符串，不执行 semantic actions。字符位置由调用者提供，
必须非负、单调、不重叠；零宽 token 和间隔合法。forest span 是 token 索引。

parse 的 token/item/node/family/work 限制是累计资源上限。超限是 Err(Limit)，
不冒充语法拒绝。work 计量搜索和 deduction，不是墙钟超时或内存字节数。
report 的深拷贝、transactional session 的全状态复制也消耗时间和内存；
预算不包含这些复制，不应在大规模不可信输入上依赖默认值获得 DoS 保证。
先验证 token/text 长度和 grammar 规模，再设置较小预算及进程级限制。

文本前端限制源 UTF-16 单位、productions、RHS symbols。类型化 Grammar::new
没有同样的输入规模预算；分析和 lint 为 finite fixed points，最坏开销仍可很高。
树提取具有单独深度/数量/work 边界，生产性 unit/nullable cycles 可代表无限多个
有限树；计数区分 Infinite 与 capped finite count。不要展开无限森林。
公开 Tree 可由调用者构造；遍历工具只接受有限无环 Tree。

Session 是 append-only，不支持中间文本编辑、lexer 状态或增量 invalidation。
失败的 push 不改变会话；语法拒绝仍是成功产生非 accepted report。
不要把 expected token list 当成完整 IDE recovery 或错误修复算法。

报告问题请在仓库开 issue，附最小 grammar/tokens/limits，不上传敏感 payload。
