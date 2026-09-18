---
id: rejected-proposals-are-invisible-to-dedup-base
type: lesson
status: candidate
scope: project:evo-kernel
domain: evo-kernel
tags: [dedup, catalog, reject, pipeline-gap, distillation]
triggers:
  - "给经验库设计拒绝/丢弃路径，决定被拒条目是否留痕"
  - "同一话题反复以新提案形式出现（怀疑查重看不见历史否决）"
  - "审查 evo catalog 的覆盖范围：它包含什么、不包含什么"
  - "蒸馏器查重放过一个明显被否决过的话题（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b1aa-8483-73b1-bdd8-c2cc6d20a4c5
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [proposal-independent-review-before-curate]
---

# 被拒绝的提案不留痕，于是查重基准看不见「这个话题已被否决」

## 主张

`evo catalog`（蒸馏器落笔前的查重基准，覆盖**已入库条目 + `ops/proposals/` 待审提案**）**不包含被拒绝的提案**。因此丢弃一条提案后，那条主张就从查重基准里消失了：同一个话题再被某次会话触及时，蒸馏器与后续审核者都看不到"它已经被否决过"。

## 为什么

2026-09-18 的 triage 批次丢弃了 4 条提案（复现失败或证据不足）。事后核对 catalog：

```
macos-bsd-cut-illegal-byte-sequence                 catalog 命中 0
ui-param-label-passthrough-drops-tooltip            catalog 命中 0
singbox-1-12-route-needs-default-domain-resolver    catalog 命中 0
```

三条都是 0 —— 拒绝动作在数据上等同于「从未存在过」。而同一批里 id 相同的 `pyqtgraph-imageitem-maptodata-transposed-coords` 之所以在 catalog 里可见（命中 1），只是因为它**恰好被重新提案了一次**、新的提案文件在待审区，与"拒绝留痕"无关。

代价是不对称的：入库（curate）与待审（proposals）都有持久记录，唯独**拒绝没有**；而拒绝恰恰是唯一一种「已经花过审核成本、结论是不该进库」的状态，最不该被遗忘。

## 反例 / 边界

- 直接危害有限：拒绝后主张不在注入集，不会污染召回；危害是**重复审核成本**，以及下次审核者若独立复核更弱时，同一条被证伪的主张可能通过。
- **不要**把本条读成「被证伪的主张会自动长回来」——这个断言我验证不了。实测到的只是「同一 id/话题可以再次出现」，而新提案的主张可能与被拒的那条**并不相同**（本条素材里 pyqtgraph 那条就是：旧的被证伪、新的是另一条更谨慎的主张）。想要证实"同一主张重复出现"，需要把被拒主张原文留存、再与新提案做主张级比对——那正是本条建议的修法。
- 修法方向（未实施）：把拒绝记录写进一份**跟踪在库**的清单（id + 一句话理由 + 日期），让 `catalog` 一并覆盖；蒸馏器查重时会自然命中并跳过，或标注「曾被否决，除非有新证据」。
- 边界：拒绝记录若混入"理由随口写"的条目，会把查重基准污染成噪声源——理由必须是一句话可核的判据（如"复现失败：X"），不是"感觉不对"。
