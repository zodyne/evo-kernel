---
id: dup-key-overwrite-severity-by-payload-identity
type: lesson
status: candidate
scope: global
domain: verification
tags: [dedup, dict-key, payload-hash, severity, data-loss]
triggers:
  - "对抗式验证『重复 ID/帧号当字典键导致丢数据』类发现，要定 severity"
  - "以传感器帧号/记录 ID 当去重键或落盘键，评估覆盖是否真丢信息"
  - "已数出重复键/丢帧条数，但被覆盖的两条内容是否相同还没验（失败信号）"
  - "想直接拿『记录数变少』把严重度定成 medium（失败信号）"
  - "重复项整帧 payload 已证明完全相同，仍按丢数据定级（失败信号：应降级）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a704-a6d5-7353-8a3d-430094cc0f9e
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [usframeidx-duplicate-drops-frames, adversarial-review-separate-evidence-from-impact-attribution]
---

# 重复键覆盖的严重度取决于被覆盖内容是否等价：先做整帧 payload 哈希比对

## 主张
判定「以非唯一 ID/帧号为键会丢数据」的实际损失时，键值重复只证明**键冲突**，不证明**信息丢失**。必须先对重复项做整帧 payload 哈希（或字节）比对：若重复项内容完全等价，覆盖是无损的，发现应判 not refuted 但 severity 降级；只有内容不等价的覆盖才是真正的数据丢失。

## 为什么（本会话命令对照）
- 全量扫描该批 SR61 `.bin`（帧长 393224）数重复键：`total 1200 unique 1180`（20 帧帧号重复）——键冲突真实存在。
- 对重复帧号成对做**整帧 payload 哈希**比对：`dup pairs: 20 identical payloads: 20 distinct: 0`——20 对重复帧全部完全相同，0 对不同。
- 最终裁决与此一致：末条判定为 `Verdict: not refuted, but severity corrected medium → low`；机制（`python/radar_viz/pipeline.py:417-418` 以 `item.fi` 为字典键赋值）属实，影响面按上一步证据降级。

## 为什么这是定级的硬判据
「帧数/条数变少」是覆盖的**现象**，不是损失的**量级**。字典覆盖的代价 = 被覆盖内容与保留内容的差：重复采集/重传导致的重复帧 payload 相同 → 覆盖是幂等的，下游读到的数据与未覆盖时完全一致；只有同号不同内容时，覆盖才是不可恢复的丢失。把「键重复计数」直接当作「丢数据量」会高估（本例 medium 被高估）或低估 severity。

## 边界 / 反例
- 不豁免键选择本身的问题：即使本例无损，用自报帧号当键仍不可取（覆盖顺序不可控、跨批次不保证），见 related `usframeidx-duplicate-drops-frames`。
- 哈希必须覆盖**整条记录**（整帧 payload）；只比对帧号或单个字段会重蹈「键重复即丢数据」的误判。
- 适用前提是重复键确实触发覆盖（字典赋值 / 去重落盘）；仅追加写不覆盖时无此问题。
- 本条管「损失是否真实、如何定级」；「证据主张与 why/消费方归因分开核验」是互补的另一条（related `adversarial-review-separate-evidence-from-impact-attribution`）。
