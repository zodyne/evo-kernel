---
id: pi-headless-batch-pitfalls
type: lesson
status: candidate
scope: global
domain: pi-agent
tags: [pi, headless, batch, stdin, watchdog, thinking-budget]
triggers:
  - "在 while read 循环里跑 pi -p 批处理"
  - "循环首轮后剩余输入行神秘消失、rc=0 无报错（失败信号）"
  - "pi 批处理任务超时被杀（看门狗 600s）"
  - "写 pi 扩展的 pi.on 事件回调"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:de8100a7（合并 session:d2f8d5b2）
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
---
# pi headless 批处理四个坑：stdin 吞噬、回调参数缺失被吞、大包裹 max thinking、看门狗

**主张**：用 pi 做后台批处理时——① `pi -p` 会吞掉继承的 stdin，跑在 `while read` 循环里会把文件清单剩余行整段吃掉（无报错、rc=0），必须加 `< /dev/null`；② 扩展回调 `pi.on("tool_call", async (event) => ...)` 里用了未声明的 `ctx` 会被 try/catch 静默吞掉，整个 warn 分支从未生效——回调签名参数要逐个核对；③ 单包要 ≤9KB 且显式 `thinking: medium`：包体 26–100KB + thinking 落 max 时耗时是 10 分钟量级（看门狗 600s 三连超时被杀），降到 9KB+medium 后每批 13–46s，**thinking max 是耗时的主要放大器，差距非线性**；④ 蒸馏类后台驱动器要单实例锁 + 看门狗 kill + 只在输出约定哨兵（如 `DISTILL_OK`）且 rc=0 时才标记完成，否则留档重试。

**为什么**：①②都是静默失效（无报错只能从结果反推）；③说明"超时"类故障先怀疑参数放大器再怀疑工具坏了——三连超时曾误判为 pi 故障。

**边界**：参数值（9KB/900s/medium）是 2026-07 在 glm 通道上的实测，模型或负载变了要重测。hook 侧注意 `harness` 字段不传默认 `"claude"`，pi 会话会被误标。

**证据**：session de8100a7 复核 27 条入库条目 10 批全成功；session d2f8d5b2 端到端跑通两个真实会话（含一次 `Connection error.` 失败路径留档重试成功）。
