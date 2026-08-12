---
id: eval-bench-replay-disagree-trust-replay
type: lesson
status: candidate
scope: global
domain: evaluation
tags: [benchmark, replay, overfitting, threshold-tuning, evo]
triggers:
  - "在小评测集上调阈值/改检索或过滤策略"
  - "bench 结论与生产历史回放结论相反（失败信号）"
  - "评测用例全是短查询而生产负载是长 prompt"
  - "准备把实验变体切换为默认行为前的最终判定"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:8e6bf649
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
---
# bench 与生产回放分歧时以回放为准；小 bench 上调阈值是过拟合

**主张**：评估检索/注入类策略变更时，自建 bench 必须覆盖生产负载的关键维度（如查询长度分布）；bench 与生产历史回放给出相反结论时，**以回放为准**。在个位数用例的 bench 上扫阈值取最优（如 7 例调出 0.13）属过拟合，不作数。

**为什么**：实测案例——evo recall 的 v3 归一化变体在 bench 上严格不劣，但回放 132 条真实 `recall.jsonl` 查询显示丢失 189 条注入（砍掉 63% 注入量），其中含正当命中。分歧根因：bench 的 6 个噪声用例全是短查询，而生产噪声主要发生在长 subagent prompt（一次注入 8–10 条）上——bench 在最要紧的维度上不具代表性，判不了这次变更。

**边界**：回放是观察性证据（无反事实），适合否决不适合证明收益；正确姿势是 bench 给绝对标尺 + 回放给真实分布对照，两套都要。修 bench 的方向是按生产分布补用例，不是继续调参。

**证据**：session 8e6bf649，按 §5.0「任何未审回归不 cutover」否决切换；按长度分桶印证长/短查询行为不同（长查询丢失 83/保留 49）。
