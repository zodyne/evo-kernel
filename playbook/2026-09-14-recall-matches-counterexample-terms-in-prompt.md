---
id: recall-matches-counterexample-terms-in-prompt
type: lesson
status: validated
scope: global
domain: agent-memory
tags: [retrieval, injection, recall, benchmark, labeling]
triggers:
  - "给检索/注入系统写盲标注或评测指令，指令里引用了某条目的名字当反例/示例"
  - "排查某条目为什么被注入：它的触发词只出现在 prompt 的『举例说明』段落，而非任务本体"
  - "标注/评测会话被注入了与任务无关的条目，污染盲标注上下文"
  - "召回命中不相关条目，且该条目的关键词恰好是 prompt 里反例文字的原文（失败信号）"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a09f56-7681-7129-be3e-249c6e4cb7e6
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: [substring-matcher-cannot-tell-exec-from-mention]
---

# 主张

词法召回/注入无法区分「任务主题」与「prompt 里作为反例/示例引用的术语」——盲标注指令里用『vim.fs.normalize 会展开 ~』当「同工具不同子问题」的反例，注入器按词面命中这段反例文字，把 vim-fs-normalize-expands-tilde 注入了与 nvim 完全无关的标注会话。

# 为什么

反例/示例文字是教学辅助材料，不是任务本体，但词法匹配只看词面。本次盲标注任务（判断 query×条目 是否实质相关）的指令为教标注者避免「同工具不同子问题」假阳性，把 vim-fs-normalize-expands-tilde 这条自身当成反例引用：「查询是『nvim 的 LSP 报错』，条目讲『nvim 的 vim.fs.normalize 会展开 ~』……不是同一子问题 ⇒ I」。注入层命中这段引用里的 vim.fs.normalize，把该条目作为「经验」注回了这个与 nvim 无任何关系的标注会话——8 条注入里 7 条与标注任务无关（reconcile 全记 irrelevant），而这条的反例引用是唯一能在 prompt 原文里直接定位到词面重合的命中源。它暴露：基准/标注指令自己的教学文字会成为注入器的触发词，污染盲标注上下文，使「盲」名存实亡。

# 反例 / 边界

- 不是 prompt 里出现条目名就一定误注——若任务本身就是要用该条目（如任务就是「给 vim.fs.normalize 加展开 ~ 的处理」），命中即正确。判据：该术语在 prompt 里是「任务对象」还是「举例材料」。
- 本条目讲的是**注入/召回通道**的词面命中，与命令拦截正则（substring-matcher-cannot-tell-exec-from-mention）是同一原理、不同通道、不同失败形态（误注入 vs 误拦截）。
- 只能证实「反例文字与注入条目词面重合、且条目与任务无关」这一层；注入器具体的分词/关键词抽取日志未在切片里，因果链靠推理补全，故 verified_by 标 human。

# 证据

2026-09-14 会话 01a09f56（对 evo-kernel 检索评测集做盲标注）的 evo-recall 注入清单含 vim-fs-normalize-expands-tilde；首条 user 指令原文以「反例：查询是『nvim 的 LSP 报错』，条目讲『nvim 的 vim.fs.normalize 会展开 ~』—— 同为 nvim……但不是同一子问题 ⇒ I」作为「同工具不同子问题」偏见防范说明；该条目与标注任务无关，reconcile 记为 irrelevant。
