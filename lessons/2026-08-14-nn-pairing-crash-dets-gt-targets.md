---
id: nn-pairing-crash-dets-gt-targets
type: lesson
status: candidate
scope: global
domain: signal-processing
tags: [point-cloud, data-association, nearest-neighbor, radar]
triggers:
  - "写/改点云检测-目标的最近邻配对或数据关联代码"
  - "配对/关联函数报 ValueError: min() iterable argument is empty"
  - "检测数可能多于目标数的退化场景（多检、虚警、单目标多回波）"
  - "审查关联/航迹起始算法，验证集合基数不等（dets>targets）分支"
  - "最近邻配对后配对数少于预期或直接抛异常"
created: 2026-08-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:c424c6bb-68ab-4f04-8c1a-0a16703c638b
last_verified: 2026-08-14
superseded_by: null
schema_version: 1
related: []
---

主张：最近邻配对 / 检测-目标关联代码必须显式处理「检测数 > 目标数」的退化分支，否则内层 `min()` 在空迭代器上抛 ValueError。

证据：t-002-v3 审查轮中直接 import `_pair_dets_to_targets` 喂管道式数据——1:1（检测数=目标数）时 6 对正常配对；一旦 dets>targets，立即 `ValueError: min() iterable argument is empty` 崩溃。

为什么：贪心最近邻通常对每个目标遍历剩余检测并 `min(key=distance)` 取最近者；检测被逐一耗尽后，某次 `min()` 拿到空候选列表。虚警 / 单目标多回波正是 dets>targets 的高发场景。

边界：dets<=targets 与 1:1 均正常，只有基数不等（尤其 dets>targets）触发；该次审查中 47 项测试全绿，但直接喂退化输入仍暴露崩溃，说明关联类算法仅靠既有测试绿不能排除基数不等分支的崩溃。
