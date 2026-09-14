---
name: independent-design-review
description: 完成一份架构/方案设计后
---

绿地设计完成后做独立评审性价比极高：Evo-Kernel v1 评审发现 3 处致命弱点（计数回路不可行、词汇失配致死、hook 事实错误）+ 11 项改进。
**做法**：评审意见分两类组织——「指导性」（机制性弱点，决定飞轮能否转起来）与「实施性」（事实性/工程性隐患）；裁决时逐条标 接受/修正/拒绝+理由，不要全盘照收。
**边界**：评审者需能看到设计全文但不参与设计，保持视角独立。

> 固化自经验 `independent-design-review`（playbook，helpful 3）· 2026-09-14 · 原条目归档于 ops/archive/
