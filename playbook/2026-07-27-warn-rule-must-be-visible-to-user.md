---
id: warn-rule-must-be-visible-to-user
type: lesson
status: validated
scope: global
domain: security-tooling
tags: [hook, warn, observability, progressive-enforcement, feedback-loop]
triggers:
  - "设计 warn → block 的渐进式约束/拦截机制"
  - "hook 有 warn 档但不阻断，只写日志"
  - "评估约束规则的误报率，却只有命中计数可看"
  - "观察期结束要判断规则能否收紧"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
渐进式约束（warn 观察期 → block 阻断）里，**warn 必须当场对用户可见**（Claude 侧走 `systemMessage` 非阻塞浮现，pi 侧走 `ctx.ui.notify`），不能只静静写日志。

**为什么**：升 block 的判据建立在观察期数据上，而"这次命中是不是误报"只有人在当场看到才判得出。若 warn 不可见，观察期结束时手里只有一堆裸命中计数——**知道命中了多少次，但不知道其中有多少该命中**。拿这份数据去决定要不要开始阻断，等于用不可解读的证据做不可逆的决定。

**边界**：可见 ≠ 打断。warn 的价值恰在于不阻塞——浮现一行让人有机会说"这条误报"，但不拦住手上的活。做成需要确认的弹窗会让人形成盲点击习惯，比不可见更糟。

关联 [[substring-matcher-cannot-tell-exec-from-mention]]：那条讲误报为什么无法在 matcher 层根除，本条讲误报要靠什么渠道被人看见。
