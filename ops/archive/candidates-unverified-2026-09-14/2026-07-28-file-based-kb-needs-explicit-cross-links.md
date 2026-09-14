---
id: file-based-kb-needs-explicit-cross-links
type: lesson
status: candidate
scope: global
domain: knowledge-base
tags: [retrieval, markdown, knowledge-organization, evo-kernel, graph-navigation]
triggers:
  - 用纯文本/Markdown 文件目录做知识库或经验库
  - 条目数上去后检索开始漏召回，出现"多跳"性质的空命中
  - 写入新知识条目的提示词/skill，正在定义写入时要做哪些动作
  - 在考虑上向量库或 GraphRAG 来解决条目间关联问题
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
related: [injection-precision-must-split-recall-vs-adoption]
---
# 文件式知识库必须显式建横向链接，且必须写死在写入提示词里——模型不会自发做

## 主张
把知识库组织成"一个条目一个 Markdown 文件"时，**纵向的层次摘要（标题/triggers/索引）不能替代横向的条目间链接**。没有交叉引用的目录，Agent 除了全文扫描或向量检索之外无从在相关条目间导航，条目越多越难检索。而且这件事**不能指望模型自觉**：能力强的模型写新条目时会自发回指已有条目，多数模型只会孤立地追加文件——所以"新增条目必须先检索并链接到相关的已有条目"必须写进负责写入的提示词里，而不是当作默认行为。

## 为什么
Evo-Kernel 正是这种文件式范式（56 条 Markdown + git），而当前状态是零结构化链接：条目之间只在**正文散文**里互相提及（如某条写"与 design-review-cross-check-implementation 互补"），frontmatter 没有任何链接字段，recall 也就无法沿链扩展一跳。

代价已经在判据表里显形：reflect 的 `P4 空命中关系型特征` 记到 43 个空命中，观察的就是"真实多跳需求"。而 P4 规划的解法是上 LightRAG 独立 MCP——书里指出，轻量文件链接就能拿到实体关系图谱的**一部分导航能力**，成本比图数据库低两个数量级。在 56 条规模上，先做链接再谈图库才是判据驱动的顺序。

出处：《大模型与 Agent 开发实战》ch3「文件系统范式：用目录结构组织知识」（OpenViking 案例）。原文："如果只是把知识拆成一堆各自独立的文本文件平铺在目录里、彼此之间没有任何交叉引用……知识越多，这堆零散文件反而越难检索"；"不同模型主动建立这类链接的意愿与能力并不相同……因此在负责写入知识的提示词里必须把要求写明确"。

## 证据（本会话命令 ↔ 结果）
- `grep -rn 'related\|see_also\|links' playbook facts episodes principles --include='*.md'` → **无输出**（零个结构化链接字段）
- `grep -rl 'playbook/\|\[\[' playbook facts episodes principles` → 4 个文件，逐一查看均为正文散文提及，非可解析链接
- `evo reflect` → `| P4 空命中关系型特征 | 43 个空命中 | 真实多跳需求 | 观察 |`
- 本提案自身带 `related:` 字段，是该字段的首次实证；curate 只校验 id/type/status/triggers，新增可选字段不破坏现有解析（loadEntries 容错）

## 边界 / 反例
- 链接的收益随条目数增长，**小库上近乎为零**：几十条时全量扫描本就召回充分，此时建链是纯开销。真正的判据应是"空命中里关系型需求的占比"，不是条目总数。
- 链接会腐烂：被链条目一旦 `superseded_by` 或 demote 到 archive，悬挂链接比没链接更误导。加字段的同时必须让 audit 检查悬挂引用，否则是拿一个新的治理债换一个检索问题。
- 本条只验证了"现状是零链接"（command），**"建链会提升召回"这一主张在本库尚未测量**——verified_by 因此标 none，不要当成已验证收益。

## 失败信号（未来命中即该想起本条）
- 空命中任务里反复出现需要串起两条已有条目才能回答的问题。
- 明明库里有相关条目，recall 却因为措辞不同一条都没召回。
- 讨论"要不要上向量库/图库"时，发现现有条目之间连最基本的引用关系都没记录。
