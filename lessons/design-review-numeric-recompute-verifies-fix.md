---
id: design-review-numeric-recompute-verifies-fix
type: lesson
status: candidate
scope: global
domain: design-review
tags: [design-review, verification, numeric-recompute, python, review-loop]
triggers:
  - "评审/验收修订后的设计文档，判断修复是否真实有效"
  - "修订方声称公式/参数冲突已修复，只有文字表述和 diff"
  - "设计评审要落 approve/reject 结论之前"
  - "评审意见被回复『已按建议修改』，需要复核修改内容（防纸面应付）"
created: 2026-08-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:pi-design-review.t-002
last_verified: 2026-08-11
superseded_by: null
schema_version: 1
related: [design-review-cross-check-implementation, independent-design-review]
---
# 评审"修复是否真实有效"要数值复核：用 python 重算关键公式，不只看文字表述

## 主张

设计评审的复审轮（验证上一轮 blocking finding 是否被修复）不能只读修订文字就放过。凡涉及公式、参数、阈值类主张，用 python 把关键数值重算一遍，确认修复方案在数值上成立，再写结论。文字修复可以是纸面应付，数值重算能直接证伪。

## 证据

pi-design-review.t-002 复审 .cloop/t-002/plan.md 修订版时，对两条 round-0 blocking 的修复分别做了数值复核：

1. 雷达参数链重算：`python3` 算 dr=0.24, rmax=61.44, dr_zp2=0.12, vmax=16.23, dv=0.2537，并验证 `tgt4 v=14.6 < vmax? True`。
2. MUSIC 平滑修复重算：对 s∈{0,3,5} 验证新语义 `L=8-s、子阵数=s+1、K_eff=max(1,min(K_ui,L-1))`，输出确认子阵数与 K_eff 逐档正确、噪声子空间维数不被压没。

复核通过后 round-1 verdict 才写 approve，最终结论原话：「修复方案经数值复核**真实有效**，非纸面应付」。

## 反例/边界

- 只适用于有公式/参数可重算的主张；纯结构、措辞、流程类修复没有数值可算，仍靠文本核对。
- 重算脚本要用修订后文档里的参数独立写，不要抄修订方给的"验证脚本"（可能自带偏差）。
