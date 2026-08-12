---
id: design-review-deployment-readiness-four-gaps
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [design-review, deployment-readiness, data-safety, acceptance-gate]
triggers:
  - "评审一份设计文档是否达到'可以照着部署'的完成度"
  - "设计把 git 版本化当数据安全的全部（失败信号：无灾备章节）"
  - "多阶段迁移只给第一阶段定义了验收门"
  - "评估系统设计，不知道按什么维度查缺口"
created: 2026-07-24
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:64181609
last_verified: 2026-07-24
superseded_by: null
schema_version: 1
related: [independent-design-review, design-review-cross-check-implementation]
---

# 评审"部署就绪"设计文档的四个结构性缺口维度

**主张**：判断设计文档能否照着部署，按四个维度查结构性缺口（不是实施细节）：① **数据安全与存续**——git 解决版本化不解决备份，单机单仓磁盘故障即资产全灭，须有 remote/异地副本 + 恢复演练入验收；② **验收门覆盖所有行为变更阶段**——好模式（如双实现对账 cutover 门）不能只给 M0，M1/M2 换检索后端同样改变行为，要复制同一套对账+回退模式；③ **测量定义**——核心判据（如"注入精度"）要有操作性定义与日志通道，否则判据不可执行；④ **运维故事**——降级事件、并发写竞争、输入保鲜期（transcript 保留期 vs 蒸馏周期错配）要成文。

**边界**：评审时把"文档声称的基线"与实装逐项核对（条目数、调用量常一天就漂移）；另有两条易漏：蒸馏原料可能含指令样文本（入库=持久化提示注入载体），以及"remote ≠ 多机同步"须明说。

**证据**：session 64181609，evo-kernel blueprint-v3→v4 评审，四门缺口 + 第二轮自查 7 项全部修入设计。
