---
id: metric-must-be-computable-from-logs
type: lesson
status: candidate
scope: global
domain: metrics-design
tags: [metrics, observability, acceptance-criteria, logging]
triggers:
  - "验收判据写完了但算不出来"
  - "日志只记注入不记效果"
  - "helpful/harmful 永远是 0"
  - "度量指标数据结构不支持"
created: 2026-07-24
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:ebd9ff4c
last_verified: 2026-07-24
superseded_by: null
schema_version: 1
---

**主张**：写验收/度量判据前，先验证它在现有日志数据结构上是**可计算**的。实测反例：判据「注入精度连续 2 周期 <50%」结构性不可测——recall.jsonl 只记注入了什么（ts/session/task/ids/chars）、无 outcome 字段；唯一对错信号是条目级累计的 helpful/harmful，不带时间戳、不绑定 recall 事件，无法切分周期；且全库 13 条有计数条目 harmful 全为 0——号称双向计数，运行两天从未产生一个负样本。

**为什么**：判据不可测比判据缺失更糟——它给出「有闸门」的错觉。发现渠道是把判据逐字段对到实际日志 schema 上实测一遍，而不是读设计文档自查。

**边界**：修法是补数据通路（recall 事件绑定后续反馈、计数带时间戳），而不是放宽判据假装能算；计数长期全零本身应作为「反馈通路断了」的告警信号。

**证据**：2026-07-24 evo-kernel blueprint-v3 评审会话（grilling），M1 判据证据链全部实测。
