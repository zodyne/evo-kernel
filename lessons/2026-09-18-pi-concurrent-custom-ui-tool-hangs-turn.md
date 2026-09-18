---
id: pi-concurrent-custom-ui-tool-hangs-turn
type: lesson
status: candidate
scope: global
domain: pi
tags: [pi, extension, ctx-ui-custom, ask_user, tool-execution-mode, hang, tui, forensics]
triggers:
  - "pi 会话 spinner 一直转、几十分钟没有任何新输出（失败信号）"
  - "同一条 assistant 消息里发起了多个 ask_user / 交互式提问调用，用户却只看到一个框"
  - "答完弹出的问题后 transcript 毫无变化，必须按 Esc 才继续（失败信号）"
  - "给 pi 扩展注册走 ctx.ui.custom() 的交互式工具（问答框 / 选择器）"
  - "多条工具结果时间戳仅差几毫秒、却比调用时刻晚了几十分钟，要判断是人为操作还是 Promise.all 解锁"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a801-014f-7485-9b7c-35a1fb467c3a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pi-print-mode-waits-on-non-tty-stdin, nvim-headless-hangs-without-explicit-quit]
---

**主张**：同一条 assistant 消息里并发多个走 `ctx.ui.custom()` 的交互工具（典型：`ask_user`）会把整个回合**永久挂起** —— pi 并行执行同消息内的工具调用，而 interactive 模式的 custom UI 只有**一个** editor 插槽，后到的那个把先到的从渲染树上摘掉且永不 resolve，只有 abort 信号能解开；而并行批次要等 `Promise.all` 全完成才逐条 emit 工具结果，于是**任何**结果都不落盘，表现为 spinner 空转。

**为什么（pi 0.85.1 实测证据链）**

1. 现场时间线（`~/.pi/agent/sessions/--Users-zodyne-Dev-SPC865--/2026-09-16T01-34-44-343Z_01a0a7da-...jsonl`）：
   - `01:39:49.580` 一条 assistant 消息里**两个** `ask_user`（技术栈 / 交付范围）；
   - `01:41:07`–`01:53:44` 只有后台 subagent 完成记录，**零 assistant 输出**；
   - `02:16:26.277` / `.278` 两条工具结果只差 **1 ms** 同时落盘 —— 前者 `cancelled:true`（"User dismissed"）、后者 `selected`；`.280` 紧接 `stopReason:"error"` / `This operation was aborted`。
   - 即：不是"用户点错两次"，而是用户按 Esc → abort → 隐藏框 `cancel()` → `Promise.all` 解开 → 两结果同时落盘。空窗 **22 分 37 秒**，该回合 `agent-summary.durationMs=2344486`（39 分钟）。
   - 横向旁证：遍历 `~/.pi/agent/sessions/**`（22 个项目目录）统计"一条 assistant 消息含 ≥2 个 ask_user"，**全库仅此 1 例**。
2. 代码路径：
   - `node_modules/@earendil-works/pi-agent-core/dist/agent-loop.js:330` `executeToolCallsParallel()`：把每个调用包成 thunk，`:372` `await Promise.all(...)` 之后才 `:374` 逐条 `emitToolResultMessage` → 一条永不 settle 就一条结果都不发。
   - `dist/modes/interactive/interactive-mode.js:2158` `showExtensionCustom()` 的非 overlay 分支 `:2212` 只做 `disposeActiveSelector(); editorContainer.clear(); addChild(component)` —— `clear()` 摘除节点但**不 dispose、不 resolve** 前一个组件；前一个框从此收不到键盘，其 promise 唯一出路是 abort。
   - `~/.pi/agent/extensions/ask-user/index.ts:278` 每次调用都 `await ctx.ui.custom(...)`，`:248` `registerTool` **既没有 `executionMode`、也没有单例守卫**。
3. 修法（代码层可行，本会话未实跑验证）：
   - 给该工具定义加 `executionMode: "sequential"`：`core/tools/tool-definition-wrapper.js:10` 透传该字段，`agent-loop.js:287` 一旦发现批次含 sequential 工具就改走 `executeToolCallsSequential`（`:293`），两个问题变成先答完一个再弹下一个；
   - 或在扩展内加模块级 `active` 守卫：已有问询在进行时直接返回 error 结果，让模型一次只问一个；
   - 上游缺陷：`showExtensionCustom` 静默挤掉前一个扩展自绘 UI，应改为拒绝或排队。

**反例 / 边界**

- 仅对**非 overlay** 分支成立：若组件走 `overlay: true`，第二个框是叠上去（`ui.showOverlay`）而不是顶掉，但被压在下层的那个同样不可交互 —— 现象不同，别混判。
- 消息里只有一个交互工具时完全正常（全库 22 个项目的 transcript 里"单条消息 ≥2 个 ask_user"仅此 1 例），所以这是**并发批次**问题，不是 ask_user 本身坏了。
- 任何走 `ctx.ui.custom()` 的扩展工具都同理，不限 `ask_user`（选择器 / 编辑器 / 表单）。
- 排查时勿误判为 provider 超时（本机 `retry.provider.timeoutMs=1800000` 未到，且报错是中语义 abort，不是 timeout），也别归因到后台 subagent（最晚一个 01:53:44 就结束了，之后仍空转 22.7 分钟）。
- 这条"卡死"的诊断签名是：**同一批的工具结果时间戳彼此只差毫秒、却比 toolCall 时刻晚几十分钟，且其中一条是 cancelled** —— 看到它就说明是批次解锁，不是人手动操作。
