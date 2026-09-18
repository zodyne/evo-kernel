---
id: adversarial-review-separate-evidence-from-impact-attribution
type: lesson
status: candidate
scope: global
domain: code-review
tags: [code-review, adversarial, verification, attribution, impact]
triggers:
  - "对抗式验证一条审查发现，发现同时有『证据』(代码行为) 和『why』(谁受害/影响面归因) 两块"
  - "复核发现时发现 its 'why' 声称的消费方/下游与代码实况对不上"
  - "发现的代码行为可复现，但它归因的受害方查无实据（失败信号：想据此整个推翻）"
  - "验证发现时不确定一个错的影响面归因是否该连带推翻成立的核心证据"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a6a9-7d3f-7353-8a3d-42d9bff20726
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [adversarial-review-repro-as-written]
---

对抗式验证一条审查发现时，把「证据主张（代码行为是否属实）」与「影响面/消费方归因（why：谁受害、怎么受害）」拆成两条独立断言分别核验。证据可复现就判成立；归因错了只修正影响面描述，不连带推翻成立的核心证据。

## 为什么

本例发现标题「空的 track_vr/track_spd 写成 (0,3) 而不是契约里的 (0,)」——证据部分完全属实：`pipeline.py:451-452` 对 1-D 列 `track_vr`/`track_spd` 用了 `EMPTY3 = np.zeros((0,3))`，独立 repro（构造 1 帧有检出、0 航迹的 SaveWorker）打印出 `track_vr (0,3) / track_spd (0,3)` 而 `track_frame (0,) / track_id (0,)`，契约 `docs/view_tracks_3d_flow.md:596` 写的是 `(T,)/(T,)`。但发现的 why 声称「F7 的 afm761_walk_metrics 类消费方按点索引这两列」是错的：全仓 `grep np.load` 无命中，`afm761_walk_metrics.py` 文档串明写「直链 ChainSession 逐帧跑,不落盘」。正确裁决是 refuted=false（证据成立）+ 只软化 support detail（危害在外部/跨采集消费者，而非仓内 reader），而不是因为 why 张冠李戴就把整条发现推翻。

## 边界 / 反例

- 与 adversarial-review-repro-as-written 互补但不重叠：那条管「复现发现方声称的 repro 命令」，本条管「证据与归因分开判，归因错不推翻证据」。
- 归因核验要落到消费方实况：`grep` 消费键/加载入口，而不是只读发现的 why 就采信或驳斥。
- 反过来也成立：归因对而证据错，同样只推翻证据部分，不因为归因「听起来合理」就放过证据核验。
- severity 可能与归因挂钩（本例外无仓内 reader，medium 仍站得住因为契约违约是客观事实）——修正归因后要重新掂量 severity 是否还成立，而不是机械保留原评级。
