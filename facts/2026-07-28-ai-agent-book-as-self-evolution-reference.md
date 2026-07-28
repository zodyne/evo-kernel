---
id: ai-agent-book-as-self-evolution-reference
type: fact
status: validated
scope: global
domain: reference
tags: [reference, self-evolution, agent-memory, eval-harness, evo-kernel]
triggers:
  - 找 Agent 自进化 / 经验学习 / 记忆系统的对照系或参考实现
  - 需要一个离线可跑、不花 API 费的自进化评估 harness
  - 复核 Evo-Kernel 设计，想对照业界独立总结的工程共识
  - 要给经验库的检索/治理方案找文献出处或反例
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
related: [injection-precision-must-split-recall-vs-adoption, file-based-kb-needs-explicit-cross-links, approval-gate-written-only-in-prompt-is-not-enforceable]
---
# `~/Desktop/ai-agent-book` 第八章是 Evo-Kernel 最贴近的公开对照系（含离线可跑的评估 harness）

## 事实
李博杰《大模型与 Agent 开发实战》开源仓库 `github.com/bojieli/ai-agent-book`，本地已 clone 至 `~/Desktop/ai-agent-book`（536 MB，`book/` 正文 + `chapter1`~`chapter10` 配套代码）。其中与 Evo-Kernel 直接同源的部分：

| 位置 | 内容 | 对 Evo-Kernel 的用途 |
|---|---|---|
| `book/chapter8.md` | 持续进化闭环全文：轨迹评价 → 四种更新载体 → 双循环 → 安全边界 → 睡眠学习 | 架构对照系；表8-3 四分层指标 |
| `chapter8/self-evolution-eval/` | **完全离线、无需 API Key** 的四阶段纵向评估 harness（学习/迁移/规则变化/保持），含 `evolving`/`append_only`/`static` 三参考 Agent | 现成的效果测量框架，可套自建回归任务集 |
| `chapter8/gaia-experience/` | 跨轨迹经验文档提炼 + 三组对照（无经验 / 单轨迹摘要 / 跨轨迹文档），含负迁移率计算 | 注入收益的实验模板 |
| `chapter8/trajectory-verifier/` | 三层轨迹验证器（环境结果 / 过程规则 / LLM Rubric） | 学习信号的分层设计参考 |
| `book/chapter3.md` | 记忆三分类（情景/语义/程序）、文件系统范式、知识库时效与治理 | 分区设计与治理机制的对照 |

## 为什么值得记
这本书是**独立于 agent-evo 调研**得出的工程总结，与 Evo-Kernel v4 的重合面很大——三类认知记忆对应 facts/episodes/playbook、记录与整理解耦、候选区与正式区隔离、证据与指令隔离、ACE 增量 delta、纯文本+git 而非专用数据库，都各自独立成立。这种重合本身是设计验证：v4 不是孤例。

更实际的价值在 `self-evolution-eval/`：它是目前找到的唯一一个**离线、零成本、且能区分"只追加"与"能淘汰旧规则"**的评估框架，正好对应 Evo-Kernel 用 `superseded_by`/`demote` 想证明的能力。这是把"价值主张可证伪但未测"（见 `agent-system-deployability-falsifiable-value-claim`）推进到真正测量的现成抓手。

## 边界
- 书里大量建议**不适用于单用户单机**：参数层更新/LoRA、灰度发布与 canary、多租户权限过滤，无对应物。
- 向量库 / RAPTOR / GraphRAG 在 56 条规模上是过早优化——v4 的判据驱动（M2 门槛 500 条）比书的默认建议更克制，不要因为读了书就提前迁移。
- gaia-experience 的"≥2 条非失败轨迹才升正式知识"门槛假设的是批量跑轨迹（GAIA 规模）；个人系统每天 1~2 个 session，硬套会把库饿死。可迁移的是记录来源/反驳轨迹列表，不是准入门槛。
- 仓库 536 MB 且含多语言副本；只有上表几个目录有用，不必全量索引。
