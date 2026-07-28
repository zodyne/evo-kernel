---
id: injection-precision-must-split-recall-vs-adoption
type: lesson
status: validated
scope: global
domain: agent-memory
tags: [evaluation, metrics, retrieval, evo-kernel, harness-benefit]
triggers:
  - 给记忆/经验/RAG 注入系统定义"精度"或"命中率"指标
  - 注入精度长期不动，判不出该修检索还是该修注入格式
  - 把"相关但没用上"和"被采纳"合并计入同一个成功率分子
  - 评审一个自进化系统的效果，只有一个总分可看
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
related: [agent-system-deployability-falsifiable-value-claim]
---
# 注入精度必须拆成「召回精度」与「采纳率」两个数，合成一个数会让指标对 harness-benefit 失效

## 主张
记忆/经验注入系统的效果指标里，**"召回对了但没被用上"（relevant-unused）不能和"被采纳"（adopted）一起计入成功率分子**。二者是两种独立能力的失败：前者是检索层失败（该找的没找到 / 找了无关的），后者是应用层失败（找对了但 Agent 没加载、没遵循）。合成一个数，指标就对后者完全不敏感——一个采纳率持续为 0 的系统，只要召回还算准，精度看起来依然健康。

## 为什么
Evo-Kernel blueprint-v4 §7.1 把注入精度定义为 `(adopted + relevant-unused) ÷ 已对账实例数`。实测这个口径掩盖了一次分叉：

- 合成口径：`(6+13)/36 = 53%` —— 距 M1 闸门（<50% 连续 2 周期）尚有余量，判据不触发。
- 拆开：召回精度 `(6+13)/36 = 53%`，采纳率 `6/19 = 32%` —— **召回对的里有 2/3 没被用上**。

两者要修的地方完全不同：47% 的 irrelevant 是词汇失配（须等 M1/M2 换检索后端），而 68% 的 relevant-unused 大概率是注入块本身的问题（recall 只给标题行 + triggers，不给主张正文），**不换后端就能改**。合成指标读不出这一层，等于把一个当下可改的问题藏在一个要等判据的问题后面。

这个区分在文献里有对应名字：harness-updating（更新器有没有产出有价值的持久修改）vs harness-benefit（任务 Agent 有没有在正确场景加载并遵循它）。见 Lin et al., *Harness Updating Is Not Harness Benefit*, arXiv:2605.30621；《大模型与 Agent 开发实战》表8-3 给出四分层指标（候选修改有效率 / 产物激活率 / 遵循成功率 / 留出任务增益）。

## 证据（本会话命令 ↔ 结果）
- `evo reflect` → `| M1 注入精度 | 53%（19/36） | <50% 连续2周期 | 未命中 |`
- 同一份报告对账详情 → `已对账 36 例：adopted=6 relevant-unused=13 irrelevant=17 misleading=0`
- `sed -n '316,332p' ~/Dev/agent-evo/design/blueprint-v4.md` → `注入精度 = (adopted + relevant-unused) ÷ 已对账实例数`（合成口径的出处）
- 手算分叉：`(6+13)/36 = 53%` vs `6/19 = 32%`

## 边界 / 反例
- 只适用于**注入式**记忆系统（系统主动把条目塞进上下文）。Agent 主动调工具检索的场景里，"检索了但没用"本身就是 Agent 的正常判断，不构成失败。
- 拆开呈报**不等于**采纳率越高越好：一条被采纳的错误经验（misleading）比 relevant-unused 危害更大，所以采纳率必须与 misleading 计数并列看，不能单独优化。
- 样本量小的时候两个数都不可解读——对账覆盖率 <30% 时（当前 22%）先修蒸馏纪律，不要解读任何一个比率。这一约束对拆分前后同样成立。

## 失败信号（未来命中即该想起本条）
- 效果指标长期横盘，但说不出下一步该改检索还是改注入格式。
- 有人问"经验注入到底有没有被用上"，只能给出一个混合了"相关"和"被用"的百分比。
- 判据闸门从不触发，而实际使用体感是注入的东西经常看过就算。
