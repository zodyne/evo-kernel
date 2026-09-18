---
id: pi-model-fallback-early-switch-and-retry
type: lesson
status: candidate
scope: global
domain: pi-harness
tags: [pi, extension, model-fallback, hooks, agent_settled, message_end]
triggers:
  - "给 pi 写『模型失败自动切备选』扩展，只在 agent_settled 钩子里 setModel"
  - "切了模型但用户仍看到 Connection error 结束，失败的那一回合没有自动重跑（失败信号）"
  - "已经切到备选模型、回合还是没跑成，纠结该再切一个还是补跑这一回合"
  - "想知道 pi 扩展的 message_end(error) 与 agent_settled 两条钩子在失败恢复里各能做什么"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a09e85-e0fb-75a9-9255-6adde3fc97aa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [hermes-fallback-providers-turn-scoped-auto-restore]
---

**主张**：pi 扩展里做「模型失败自动切换」要两条路径配合：① **失败当场**在 `message_end`(error) 钩子里 `setModel(备选)`；② 回合结束后在 `agent_settled` 里只负责补跑——发现"已经换过模型但这一回合没跑成"时用 `retry` 补该回合，而不是再切下一个模型。只在 `agent_settled` 里 `setModel` 不够：模型会被换掉，但失败的那一回合不会自动重跑，用户拿到的仍是 `Connection error.`。

**为什么**：切换模型只影响后续请求，不会重放已经以错误收尾的回合；`agent_settled` 是回合结束事件，在那里切换属于"为时已晚"。要在错误消息结束的当场切换，下一次请求（重试）才落在备选模型上。

**证据**（本会话命令 ↔ 结果，e2e 在 `/tmp/pi-fallback-e2e` 沙箱 profile 里跑）：
- 只靠 settled 兜底：trace `agent_settled decision=fallback current=dead-gateway/dead-model lastError=yes`，但同一条 `pi -p` 命令的可见输出是 `Connection error.`（不是模型回答）。
- 加 `message_end`(error) 早切后：同一条命令输出 `好`，trace `early switch #1 → glm-coding/glm-5.3-flash = true`。
- 自测把边角固定住：先出现失败用例 `❌ 已换过模型但回合没跑成 → retry（只补回合，不再切）`，改 `handleSettled` 后转绿，最终 `11/11 通过`；真实 profile 冒烟 `pi -p "只回答四个字：扩展已加载"` → `扩展已加载`，且真实配置下不触发无谓转移。

**边界/反例**：上下文溢出（换模型治不了）与用户中止（`stopReason=aborted`）都不该切，自测里这两条走"不切"分支；同回合内转移次数要有上限，备选自己也失败时再切下一个（自测覆盖 `备选自己也失败 → 切下一个备选`）。
