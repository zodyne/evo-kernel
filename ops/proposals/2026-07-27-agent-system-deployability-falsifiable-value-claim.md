---
id: agent-system-deployability-falsifiable-value-claim
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [design, review, deployability, falsifiability, agent-system, evaluation]
triggers:
  - 评估/评审一个 agent、记忆或经验系统是否"达到部署条件 / 可以上线"
  - 被问"这个 agent/记忆系统到底有没有用、该不该部署"，只能答出机制却拿不出收益度量
  - 设计或复核的价值主张写成无法证伪的断言（"更智能 / 更稳定"而无度量口径）
  - 复核结论停在"机制端到端可用 / smoke 绿"，却判不了"是否产生净收益"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:d6a046b4-db37-4ab3-99d8-f18aa1a38c15
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# 判 agent/记忆系统是否"可部署"：机制端到端可用只是必要条件，决定性判据是价值主张可证伪

## 主张
评估一个"价值主张是提升效率/稳定性"的 agent、记忆或经验系统是否达到部署条件时，**"机制端到端可用"（smoke 通过、hook/注入功能正常、有真实用量）只是必要不充分条件**；决定性判据是该系统的核心价值主张是否**可证伪**——即是否定义了能量化的成功/失败指标。机制可用但收益不可测 ≠ 可部署；但能把一个原本"不可证"的命题降级为"可证伪"，本身就是设计上的实质进步，应单独计为价值，而不是因"还没测出收益"就全盘否定。

## 为什么
第三轮从零复核 blueprint-v4 时，命令把机制层证实为完全可用，却没有任何一条命令/数据能证明"净收益"：
- `bash test/smoke.sh` → guard allow / guard deny / hook-guard 等全绿 → **机制端到端可用**。
- `python3` 读 `ops/log/recall.jsonl` → recall calls: 42, with-injection: 28 (66%) → **注入通道功能正常且有真实用量**。
- `grep injectedSessions bin/evo` → 命中 156/279 行的同 session 去重实现 → **工程闭环、机制真实存在**。

但全切片**无一条"效率/稳定性前后对比"的测量结果**。于是复核结论只能落到"机制端到端可用"，到不了"已产生净收益"；而 v4 的价值恰恰是把"是否提升 LLM 效率"这个原本无法验证的命题，变成了可以设计实验去验证（可证伪）。把这两件事分开回答，才能既不夸大（机制可用≠有用），也不抹杀（可证伪化本身是进步）。

## 证据（本会话命令 ↔ 结果，切片硬证据）
- `bash test/smoke.sh 2>&1 | tail -15` → `✓ guard allow ✓ guard deny ✓ hook-guard deny JSON …` —— 机制端到端可用。
- `python3` 读 recall.jsonl → `recall calls: 42, with-injection: 28 (66%)` —— 注入功能正常、有用量，但**仅机制遥测、无收益度量**。
- `grep -n "injectedSessions" bin/evo` → `156: …`、`279: … (同 session 去重)` —— 去重机制实现存在，工程闭环。
- 末条复核报告原文（切片硬输出）："现有证据只支撑到'机制端到端可用'，不支撑'已产生净收益'"、"v4 的核心价值恰恰是把这个命题从'不可证'变成了'可证伪'"。

## 边界 / 反例
- 仅针对"价值主张是提升效率/稳定性"的 agent/记忆/经验系统。纯机制性/合规性工具（价值主张本身即"功能正确"，如格式转换器）的可证伪性天然满足，不适用此区分。
- "可证伪" ≠ "已经证伪通过"——把命题变成可证伪、但尚未跑实验的设计，仍未"已产生净收益"，只是"部署评估有了抓手"；不要把"现在可测"误读成"现在已证明有效"。
- 与 `design-review-cross-check-implementation` 互补：那条讲"评审时如何核实现状（设计主张 vs 实现/测试）"，本条讲"核对完之后按什么标准判是否可部署"。

## 失败信号（未来命中即该想起本条）
- 评审/上线评审只能给出"机制跑通 / smoke 绿"，给不出"提升了多少"的度量口径。
- 被问"这个系统到底有没有用 / 该不该上"时，只能描述机制，答不出可验证的 success criteria。
- 设计文档把核心价值写成无法证伪的断言（"让 agent 更智能 / 更稳定"）而无配套度量指标。
