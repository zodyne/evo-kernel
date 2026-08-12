---
id: overturned-capture-must-be-rewritten
type: lesson
status: candidate
scope: global
domain: experience-engineering
tags:
- capture
- inbox
- distill
- data-hygiene
- root-cause
triggers:
- 根因查明，推翻了当天早些时候写下的初步归因
- inbox 里躺着一条基于已被推翻结论的 capture（失败信号）
- 同一 session 里出现两条互相矛盾的 capture/记录
- 用 evo capture 先记了初步判断，调查还在继续
- 蒸馏原料里混入了已知为错的记录，怕产出伪经验
created: 2026-07-29
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: session:b6cf7fd7-73c7-4cef-b538-5428b694a71b
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related:
- kimi-api-latency-streaming-thinking
- proposal-independent-review-before-curate
---

# 结论被推翻后，必须同步删除/改写基于旧结论的 capture——错误记录是蒸馏的原料

## 主张

capture 通道（inbox）是后续蒸馏的**直接原料**。初步归因被后续实测推翻时，
纠正动作不能只停在得出新结论上：必须回头**删除或改写**那条基于旧结论的 capture，
并在新 capture 里显式标注「推翻了哪条旧判断」。否则错误记录会以一手证据的身份
进入蒸馏，产出伪经验——而且它写得早、措辞肯定，比模糊记忆更有迷惑性。

## 为什么

2026-07-29 本会话实操：08:41 先 capture 了「pi -p 对大任务一律挂死」（归因提供侧/
任务体量）；09:39 直连 API 实测推翻该归因后，第一步就是 `rm` 掉旧 capture，
再写入新 capture，并在正文首句标注「根因是看门狗短于任务耗时，不是提供侧故障
（**推翻同日早先的错误判断**）」。两条记录若同时留在 inbox，蒸馏器看到的就是
相互矛盾的一手证据，裁决成本与出错概率都翻倍。

## 反例 / 边界

- 不是禁止记初步判断——capture 的价值就是低摩擦先记下来；关键是「推翻即改」，
  不是「没把握别记」。
- 已被 curate 入库的错误条目不能 rm，要走 demote/supersede 流程；
  本条只适用于 inbox 未审区。
- 改写要留痕：新 capture 标注被推翻的旧判断，让蒸馏能看到完整归因链，
  而非凭空替换。

## 证据

- `rm -f inbox/capture-2026-07-29-08-41-53-989-3g5k.md` 后
  `evo capture "…（推翻同日早先的错误判断）…"` →
  输出「已重写 → inbox/capture-2026-07-29-09-39-12-538-yqix.md」。
