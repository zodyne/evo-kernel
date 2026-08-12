---
id: criterion-without-data-path-never-fills
type: lesson
status: candidate
scope: global
domain: metric-design
tags:
- metrics
- criteria
- judge-agreement
- reconcile
- evo-kernel
triggers:
- 设计文档里写了判定/复核类判据，要检查它能否被填上
- 指标行长期挂着'(待人工复核)'占位符从没变过（失败信号）
- 两个裁判 0% 分歧，想据此宣布口径清晰
- 给对账/评审系统设计人工复核或第二裁判通道
created: 2026-08-12
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: 人工（整理 inbox/capture-2026-07-28-12-27-16-760-r1c9.md）
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related:
- injection-precision-must-split-recall-vs-adoption
---
# 判据没有数据落盘路径就永远填不满；0% 分歧 ≠ 口径清晰

**主张**：机制写在设计里但没有数据路径（没有落盘位置、没有产生该数据的通道），对应判据**不可能被填**。另外，**0% 的判定者分歧不等于口径清晰**——也可能是两个裁判碰巧共用了同一种未言明的解读。

**为什么（实测）**：evo-kernel blueprint §7.1 的"判定者分歧率"硬编码为"(待人工抽≥10例复核)"，但库里没有任何地方存放复核结果：`reconcile.jsonl` 的 `judged_by` 只出现过 `reflector`（39/39），没有 human 复核通道、没有第二裁判通道。2026-07-28 实测：让 pi（不同模型家族）独立对同两条注入判四态，与本方判定完全一致（0/2 分歧），但 pi 主动标注"不确定"恰好落在 relevant-unused 与 irrelevant 的边界上——说明口径并未真正对齐，"相关"定在主题层还是功能层是两个裁判都没言明的自由变量。

**要真填这一行，需要**：①一个复核结果的落盘位置（reconcile.jsonl 或独立文件，含 judged_by: human/second-judge）；②§7.1 给"相关"加一条主题层/功能层的判准。二者均属设计口径变更，待人审。

**反例/边界**：不是说低分歧没价值——它至少排除"口径明显冲突"；但要把 0% 分歧读成"口径清晰"，必须先确认裁判们各自言明了判准。

**证据**：capture-2026-07-28-12-27-16-760-r1c9；`judged_by` 分布统计（reflector 39/39）与 pi 对照判定记录。
