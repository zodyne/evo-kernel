---
id: greenfield-rebuild-via-spec-patch
type: lesson
status: validated
scope: global
domain: research-methodology
tags: [greenfield, rewrite, spec, worker-delegation, fidelity-audit]
triggers:
  - "把一个已有实现推倒重建 / 绿地重写"
  - "派子代理或他人重新实现现有系统"
  - "设计文档不足以支撑实现，实现者只能去读旧代码"
  - "想让重写产物可被独立审计而非只能对比旧代码"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
绿地重建的可行姿势：**先补「规格补丁」，再派实施**。从旧代码逆向出命令契约、smoke 断言清单、日志/数据 schema，把这些补进设计文档，使文档单独就足以支撑实现；然后让实施者**只读文档、不读旧代码**。

**为什么**：实施者一旦读旧代码，就会把旧实现的偶然选择（idiosyncrasy）连同本质需求一起复刻，重写退化成搬运；而且没人能判断产物是"按设计实现"还是"照抄旧代码"。切断这条路径后，产物与设计的偏差成为可审计量——保真审计才有对象。

**证据**：Evo-Kernel 用此法一次性重建 21 个命令，smoke 61/0 通过。

**边界**：前提是能把旧行为**穷举成契约**（命令面、断言、schema 这类边界清晰的东西）。若系统的关键行为藏在难以枚举的隐式状态里，规格补丁会漏，此时"不读旧代码"就成了故意致盲。
