---
id: adversarial-review-replay-beats-static-line-number
type: lesson
status: candidate
scope: global
domain: adversarial-review
tags: [adversarial-review, replay, thread, delivery-order, verification]
triggers:
  - "对抗式验证线程/队列投递顺序类审查发现，行号与声称值有几行偏差"
  - "判 refuted/confirm 前发现静态行号对不上，不确定是否该推翻"
  - "验证消息投递/落盘顺序缺陷，需要动态证据而非静态阅读"
  - "重放线程/worker 的真实投递顺序来复现缺陷"
  - "行号基本吻合但有个别 2-3 行偏差（失败信号：想据此判 refuted）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a6a9-e1c3-7353-8a3d-42dca1682b0b
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [adversarial-review-repro-as-written, restart-discard-stale-accumulation]
---

主张：对抗式验证线程/队列消息投递顺序类审查发现时，静态行号有几行偏差（≠完全吻合）不是推翻理由——应按真实投递顺序重放 worker，用动态产物做硬判据。

为什么：本会话复核 algommw「UI与线程生命周期」发现时，发现方把 `SAVE_DISCARD` 的投递点写成 `session.py:229`，实际在 `session.py:226`（3 行偏差）。若只比对静态行号会误判发现不严谨；但按真实投递顺序重放 `SaveWorker`，得到的 npz 明确含两轮参数混合（`det x=[2,2,2,1,1,1]`、`track_id=[9,9,9,7,7,7]`），动态证据证实发现属实，最终判 `refuted=false`。

反例/边界：这不豁免「发现方声称的 repro 命令要逐字复现」（见 related `adversarial-review-repro-as-written`）；也不适用于行号大范围错乱或 repro 本身对不上的情况——那类偏差仍需怀疑。仅当动态重放能独立复现缺陷时，行号小偏差才不构成推翻理由。

证据链接：replay 命令 `python3 - <<EOF ...` 重放 SaveWorker → 落盘 `sim.npz`，读回 `det_frame=[0,1,2,3,4,5]`、`det x=[2,2,2,1,1,1]`、`track_id=[9,9,9,7,7,7]`（两轮参数混拼），与「未推翻、置信度高」的末条判定一致。
