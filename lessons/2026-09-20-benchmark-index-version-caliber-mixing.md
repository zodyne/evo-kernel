---
id: benchmark-index-version-caliber-mixing
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [benchmark, versioning, artificialanalysis, model-comparison, rework]
triggers:
  - "引用第三方榜单分数（AA Intelligence Index 等）给模型排名、选型或做对比结论"
  - "同一轮调研里同一个模型能查出两个不同的分数（失败信号：旧版指标与当前版并存）"
  - "跨轮次拼接分数：这一轮算出的数和上一轮说的数对不上（失败信号：60/57 vs 45/42）"
  - "报告要写『A 比 B 强 N 分』，却没有交代分数取自哪个版本的指标"
  - "重算后排名结论翻转，准备解释成『模型被重新评测了』"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0b965-0941-75eb-8af3-647a9ae53e12
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [aa-leaderboard-scores-in-embedded-json, upstream-caliber-migration-tests-drift-green-revert-to-baseline]
---

# 第三方评测指标是版本化的：旧版 index 的分数与当前版不可混比，混了要整段重算

**主张**：第三方榜单指标带版本号（本次为 AA Intelligence Index **v4.3**），同一模型在不同版本口径下是不同的数（本次对照：旧版 index 口径 60/57，当前 v4.3 官方口径 45/42）。把旧版分数与当前版分数放进同一张对比表、或跨轮次拼接，会得出错误的排名结论，代价是整份对比分析返工。引用前先锁定「当前榜单版本」，一张表只用同一版本、同一页面的数据，并在表头写明版本号。

**为什么**：版本号和分数在页面上不总是并排出现，Agent 很容易沿用上一轮引用过的（通常更漂亮的）旧分数，而没注意榜单已改版；一旦混比，「谁更强、差多少」这类结论可能直接反转，事后只能整段重算。

**证据**（本会话切片，末条 assistant 原文）：

> 数据齐了。**必须先用同一版本口径重算**——上一轮我引用的 60/57 分是 AA 旧版 index，当前榜单（Intelligence Index **v4.3**）的官方口径是 45/42，两者不可混比。以下全部取自 AA 同页面同版本数据：
> ## 推理能力（AA Intelligence Index v4.3，越高越强）

即同一个会话里，前一轮已给出过基于旧版分数的内容，后一轮被迫按 v4.3 换掉全部数字重算。

**边界 / 反例**：

- `verified_by: human` ——「60/57 属旧版」这一判断来自会话内的模型判断，切片里没有并排展示两个版本分数的命令输出，只有这条结论性陈述。
- 45/42 只是当时 v4.3 口径下的取值，不是长期真值；榜单更新后要重新确认版本号，不要把本条的数字当常量引用。
- 本条不否定引用旧版数据做趋势对比 —— 只要同一张表内版本一致、并在文中写明版本号，旧版数据仍可用。

## 2026-09-22 独立复核增补

**复核给不出最小复现**（见下）。


**审核给出的修改意见（要点）**：三处改：(1) 把「为什么」里的机制从断言降为假设，并补上被忽略的替代解释——切片里没有任何旧版分数，60/57 也可能只是上一轮的错误数字或取自另一指标，而非旧版 index；现在的写法把一种可能当成唯一原因。(2) 把『第三方评测指标是版本化的』收窄为『AA Intelligence Index 这类版本化榜单』，别把单样本升格成普适律。(3) verified_by 从 human 改为 none（或明确标为『会话内模型判断，未经 command/test 校验』）——核心主张只有模型自述，SCHEMA 里 verified_by 是硬反馈等级，标 human 会抬高注入权重。可选补一条独立佐证（现已复跑确认）：curl -sL https://artificialanalysis.ai/leaderboards/models -H 'user-agent: Mozilla/5.0' | grep -o 'Updated to Intelligence Index v4.3[^,]*' 输出含 'Updated to Intelligence Index v4.3: AutomationBench-AA joins the index, 𝜏³-Banking is removed, and Terminal-Bench moves to 4.0' —— 直接证明该指标确实版

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 机制解释无据：『版本号和分数在页面上不总是并排出现，Agent 很容易沿用上一轮引用过的（通常更漂亮的）旧分数，而没注意榜单已改版』——切片里没有任何关于页面布局或 agent 复用旧分数的观察，属会话内推断被写成事实。
- 由单样本升格为一般律：仅凭 AA 一次观测，主张就写成『第三方评测指标是版本化的』（对全部第三方榜单成立）。
- 把 60/57→45/42 的落差直接归因为『旧版 index』，未列替代解释：切片里根本没有旧版分数的痕迹，60/57 也可能只是上一轮的错误数字或取自另一指标，而非版本差异。

**判定**：keep-with-fix · 拟 keep-lessons · 原证据快照风险=high · 复核时本机可复跑=false
