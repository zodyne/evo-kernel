---
id: restructure-request-diagnose-load-bearing-first
type: lesson
status: candidate
scope: global
domain: repo-governance
tags: [restructure, directory, consolidation, framing, load-bearing, adr]
triggers:
  - "用户要求『收拢/合并/简化目录结构』『目录太散，整理一下』"
  - "看某个跨目录 include / 跨层共编觉得反常，想搬文件消除它"
  - "重构冲动上来，准备大规模 git mv 之前"
  - "评审一个『目录优化』方案，判断哪些移动值得做"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fc28c-b27f-7ef1-a2dc-4882a3c48ba7
last_verified: 2026-08-03
superseded_by: null
schema_version: 1
related: [converge-task-inventory-first, doc-drift-fix-grep-by-concept, bytes-exact-oracle-gate-for-pipeline-port]
---

**主张**：收到「收拢/简化目录结构」类诉求，先把每一处「散」归类为三种性质再动手——**①承重的有意分层**（背后有设计裁决/约束支撑，不能动）、**②偶然的过度切分**（单文件子目录、只装一个文件的顶层目录，可收）、**③感知层问题**（命名误导、framing 偏差、文档漂移，与结构无关）。实践中「散」的大头常是③，解药是**正名 + 文档治理**而不是搬文件；为消掉一个被裁决过的跨层引用而新增顶层目录是负收益。

**证据**（algommw dir-consolidation，2026-08-03）：用户要求收拢目录。逐点核查发现顶层 10 个目录已无冗余——最扎眼的「`host/pipeline_runner` 跨目录共编 `platform/freertos/tasks/pipeline.c`」是 ADR 0003 的有意裁决（host 与 arm 固件共编唯一生产 driver；pipeline.c 用 FreeRTOS API 不能进 core/，放 host/ 会让 arm 反向依赖 host 违反分层铁律），`platform/` 只是被误读为「embedded 专区」（实为共享平台胶水层）。最终方案 B 只动了②类：`tasks/` 单文件子目录 flatten、`cmake/`（仅 1 个 toolchain 文件）并入 `platform/`，加 `platform/README.md` 正名 + 归档 8 篇历史设计档；明确否决了「pipeline.c 提为顶层 `rtos/`」（+1 顶层目录、改 4+ 处 CMake、byte-identical 风险最高，只为消一个裁决过的共编关系）。结果：17/17 测试绿、B1 MD5 锚（`cb6afb…`/`0160e2…`）逐字符不变。

**做法**：候选方案按「保守=纯文档正名 / 中度=只动②类 / 激进=动①类」梯度组织，用「顶层目录数变化 × CMake 改动面 × 回归锚风险」三维对比——动①类的方案通常三维全输。判断是不是①类的捷径：查 ADR/架构文档里有没有针对该结构的裁决记录，有则只能「正名」不能「搬」。

**边界**：与 `converge-task-inventory-first`（「构建 X」先盘点）同族互补：那条管「功能已存在」，本条管「结构是承重的」。若仓库确实处于早期无序生长阶段、无裁决记录，①类可能真的不存在，此时大刀阔斧是对的——先确认有没有承重墙再下锤。
