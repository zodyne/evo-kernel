---
name: evo-recall
description: 开工注入（第一道防线）：从 Evo-Kernel 经验库检索与当前任务相关的经验条目。每个非平凡任务开工前都应运行；用户说"有没有相关经验"、"之前怎么做的"、"recall"时必须使用。
---

# Evo Recall — 开工检索经验

## 何时用
- 非平凡任务开工前；接触不熟悉领域；不确定怎么做/怕踩坑时。
- hook 已自动注入时，把注入结果当起点；需要更多再手动补。

## 用法
```bash
evo recall --task "<当前任务的一句话描述>" --budget 1500
```

## 结果解读
- 每条以 `[id:xxx]` 开头，后接域/验证等级/+-计数、主张、triggers。
- `verified:test > command > human > none`（硬反馈等级，越靠前越可信）。
- 注入条目若**实际帮到你**或**误导了你**：告知用户，或跑 `evo adopt --ids <id>` / `evo reject --ids <id>`（人工兜底，主通道是收工蒸馏时的自动对账）。
- 无输出 = 库中无相关经验（宁缺毋滥，正常）。

## Agentic 两级检索（主 agent 在线时推荐）
你自己就是大模型精筛器，比 CLI 词匹配准得多：
1. `evo candidates` → 全量 validated+ 条目一行摘要（粗筛）
2. 你判断哪几条真相关
3. `evo get --ids <id1,id2>` → 拉全文细读
适合：任务中途需要深入某领域经验、hook 注入不够精准时。

## 边界
- recall 只覆盖 validated+ 条目；candidate 未验证不注入（I2）。
- 内核故障时静默无输出（fail-open），直接继续任务即可。
