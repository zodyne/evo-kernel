---
id: converge-task-inventory-first
type: lesson
status: candidate
scope: global
domain: task-planning
tags: [convergence, inventory, planning, governance, adr, delegation]
triggers:
  - "用户下达『构建一个 X 平台/系统』『收敛到 X』类任务，听起来像要新写代码"
  - "项目处于里程碑间隙、多个开放方向待拍板，用户选定其中一个方向"
  - "准备按 greenfield 动手前，还没盘点过现有代码离目标形态差多少"
  - "仓库已迭代多轮且有 ADR/阶段计划，新任务与已有裁决可能重叠或冲突"
created: 2026-08-02
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fc28c-b27f-7ef1-a2dc-4882a3c48ba7
last_verified: 2026-08-02
superseded_by: null
schema_version: 1
related: [design-review-cross-check-implementation, doc-selfreported-counts-drift]
---

**主张**：接到「构建/收敛一个平台或能力」的任务，**先盘点现状再规划，不要按任务字面当 greenfield 动手**。目标形态常常已在代码层达成（本会话约 90%），真正的缺口是「扶正」——角色定义、文档定位、命名、方向裁决（ADR）。按「要新建」动手会写出重复实现，或无意中推翻已有架构裁决。

**证据**（algommw，2026-08-02）：用户要求「构建纯 PC 毫米波离线算法验证平台，FreeRTOS 基座 + 多任务多缓存」。planner 盘点发现 `pipeline.c`（ADR 0003）已是 5 任务 + 3 深缓冲池 + 零拷贝 + 双域背压的完整实现，且过 byte-identical 闸门。最终实际工作 = 新增 ADR 0004 + `freertos_preview` 改名 `pipeline_runner` + 文档收敛 + arm 路径标注 deferred：**`git diff` 对 `core/` 与 `pipeline.c` 零改动**，17/17 测试绿、B1 MD5 锚不变。若按字面「构建」动手，极可能重写流水线或物理删除 arm 路径——后者会推翻 ADR 0003「pipeline.c 与 arm 固件共编」的核心裁决。

**做法**：盘点产出物不是直接开工，而是**决策点清单**（每个给选项+建议）交人拍板——本会话 D1–D5（runner 角色 / arm 去留 / 是否建新 ADR / 缓冲架构 / 改名），人确认后才派 worker 执行。盘点还能顺带暴露文档漂移（CLAUDE.md 写「9 个测试」实测 17）。

**边界**：适用于已迭代多轮、有明确阶段计划/ADR 的仓库；真 greenfield 或目标与现状确实无交集时不适用。与 `design-review-cross-check-implementation`（评审设计文档要交叉核对实现）互补：本条是**接任务**时的盘点，那条是**评审文档**时的核对。
