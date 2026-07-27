---
id: evo-kernel-concurrency-empirical-fact
type: lesson
status: candidate
scope: project:evo-kernel
domain: concurrency
tags: [concurrency, multi-harness, file-io, ops, atomic-write]
triggers:
  - 写入或追加 recall.jsonl / manual-feedback.jsonl 等 ops 共享文件
  - 设计 Evo-Kernel 存储层或任何写入路径
  - 怀疑多 harness 并发访问只是理论风险、想跳过并发安全
  - 实现文件追加/写入，需要决定是否加锁 / 原子 rename / append-only
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:ebd9ff4c-dc42-41f5-8b67-f59bd29483ee
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---

主张：Evo-Kernel 的共享状态（`ops/log/recall.jsonl`、`manual-feedback.jsonl` 等 ops 文件）会被**多个 harness（Pi + Claude Code）并发访问**——这不是理论风险，是已测量的既成事实；任何写入路径都要按并发安全设计。

为什么（硬证据）：解析 `ops/log/recall.jsonl` 得到 37 次调用、28 个独立 session，其中 **4 对 session 时间重叠**；且重叠双方 session id 格式不同——`019f8a68` / `019f8dcd` 是 Pi 格式，`99247a2b` / `95d881b1` / `d6f040ef` 是 Claude UUID——**重叠的正是双 harness 交叉**（4/28 ≈ 14%）。这正是双 harness 并发写入同一份 ops 文件的真实场景。

含义（给未来写入/存储任务）：对共享 ops 文件的 append/write 不能假设串行，必须并发安全——append-only 追加、原子 rename、文件锁，或单写者序列化。

反例 / 边界：该测量是单时间点快照，具体比例随用量变化；但「多 harness 并发存在」这一模式稳定。设计文档（final-architecture / blueprint）已把双 harness 列为核心场景，本条用实测数据**确认**而非首次提出它——价值在于让未来实现任务在 recall 命中时被提醒，而非依赖通读设计文档。
