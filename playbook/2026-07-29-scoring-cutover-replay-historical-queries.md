---
id: scoring-cutover-replay-historical-queries
type: lesson
status: validated
scope: global
domain: retrieval
tags: [cutover, replay, regression-gate, scoring, recall]
triggers:
  - "准备替换/调优检索、召回、评分后端（权重、阈值、算法）"
  - "新后端离线指标看着更好，想直接切成默认（失败信号）"
  - "评估一次后端变更会不会造成回归"
  - "给检索系统加 EVO_SCORING 这类实验开关，犹豫要不要翻默认"
  - "旧查询曾经召回的条目在新后端不见了"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [rerank-channel-design]
---

# 换检索/评分后端前用真实历史查询回放对账：丢失的旧命中逐条人审，裁决不了就不切默认

## 主张

替换或调优检索/评分后端时，离线基准变好不够——必须用真实历史查询日志回放，diff 新旧后端的注入集；新后端丢失的旧命中要逐条人审"是改进还是回归"。裁决不了就保持旧默认，实验路径做成开关默认 off。

## 为什么

离线基准的查询集小且分布偏，真实历史查询才是注入行为的分布内样本。本次给 evo-kernel 加评分变体开关 EVO_SCORING（v0–v3）+ 阈值扫描后，回放 recall.jsonl 全部 132 条去重历史查询：两侧均空 37、注入集完全一致仅 11，**新后端丢失的旧命中高达 189 条**（Top 丢失：episode-agent-evo-research 35 次、seed-failure-lessons-as-templates 25 次）。无法逐条裁决这些丢失是改进还是回归，于是结论是不改默认（v0）、行为零变更——`npm test` 93/0、bench 与基线逐格一致后提交 `2ec04db`。"不改"本身就是这次实验最有价值的产出。

## 反例/边界

- 新后端是全新场景（无历史日志可回放）时不适用，只能加观测期灰度。
- 回放对账给出的是"注入集差异清单"，不是自动判决——189 条丢失若逐条审完确认都是噪声被正确过滤，同样可以切；门的作用是强制人审，不是禁止变更。
- 开关默认 off + 单测锁住默认行为，是实验期不污染生产的配套动作。

## 证据

- 命令：`EVO_SCORING=v0..v3 node test/retrieval-bench/bench.js`、`EVO_RELEVANCE_MIN=0.25..0.10` 扫描、`node /tmp/replay.js`（回放 132 条历史查询，输出"丢失 189 条须逐条人审"）、`node /tmp/agg.js`（丢失 Top12 聚合）。
- 提交：`2ec04db feat(recall): 评分变体开关 EVO_SCORING（默认 v0，行为零变更）`。
