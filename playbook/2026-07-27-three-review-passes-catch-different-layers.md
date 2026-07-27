---
id: three-review-passes-catch-different-layers
type: lesson
status: validated
scope: global
domain: research-methodology
tags: [review, audit, self-check, fidelity, layered-verification]
triggers:
  - "一份设计/实现要不要多轮评审，还是一轮就够"
  - "评审已经过了但交付后仍暴露问题"
  - "安排评审计划，需要决定评审类型与顺序"
  - "只做了一种评审就宣布可交付"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
三类评审抓的是**不同层**的缺陷，层次不重叠，少一类就漏一层：

1. **设计评审**（外部视角）→ 结构性缺口：机制根本转不起来、关键回路缺失。
2. **自查**（作者视角，带清单）→ 隐私 / 时效 / 信任边界这类横切属性——外部评审者缺上下文，往往看不出。
3. **保真审计**（对照文档逐条核）→ 文档内部不一致：断言表漏 1 造 2、路径互相矛盾、同一数据双写双计、恒等集误纳无关项。

**为什么不能合并**：三者所需视角互斥。设计评审要求评审者不参与设计（保独立），自查要求深度上下文（外人没有），保真审计要求机械对照而非判断力（有判断力反而会"脑补合理"从而放过不一致）。想用一轮覆盖三层，实际只会得到最擅长的那一层。

**证据**：Evo-Kernel 三轮评审各自抓到上述三类缺陷，无一类被其他两轮独立发现。

**边界**：三轮是对"要长期演进、且文档本身是交付物"的系统而言。一次性脚本、文档即代码注释的小工具，做到设计评审即可，其余两轮成本大于收益。
关联 [[independent-design-review]]：那条讲单轮评审内部怎么组织意见，本条讲需要几轮、各抓什么。
