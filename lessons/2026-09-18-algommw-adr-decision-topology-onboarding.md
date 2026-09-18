---
id: onboard-via-adr-decision-topology
type: fact
status: candidate
scope: global
domain: onboarding
tags: [adr, onboarding, architecture, decision-history]
triggers:
  - "接手/评审一个多轮迭代的仓库，要判断现行架构约束再动手"
  - "想给项目引入第二驱动/hal 抽象层/RTOS 调度，觉得是新点子"
  - "只看现行目录结构反推项目演进历史"
  - "移植/扩展仓库时不确定哪些形态是被否决的（失败信号：重新造出 DO-NOT 清单里的东西）"
  - "新会话 onboarding 大仓库，读什么才能不踩已被裁决掉的路线"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0af3a-aba2-7097-91f3-80f58c344ace
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [converge-task-inventory-first]
---

## 主张

接手多轮迭代的仓库，onboarding 第一动作是通读 `docs/adr/` 重建**决策拓扑**（哪条被逆转、哪条现行），而不是从现行文件树反推历史——最终态代码布局不携带"哪些方案已被否决"的信息，不读决策史就会把被否决的形态当新点子重新引入。

## 为什么

algommw 实例（2026-09-17 会话通读 adr/0001..0008 整理）：0003（双驱动+FreeRTOS）被 0005 逆转、0004（PC canonical）被 0005 逆转、0006（拒绝 ctypes 绑定）被 0007 逆转、0001 随 dpm 模块删除失效。现行树里看不到 hal/、host/、FreeRTOS——但历史上都存在过且都有正式裁决记录。该仓库为此维护了成文的 DO-NOT 清单；不读 ADR 链的人无法理解清单里每条"never reintroduce"对应哪次返工。

## 反例/边界

- 与 `converge-task-inventory-first` 互补：那条讲新任务动手前先盘点现状与本仓差距；本条讲盘点要下探到**决策史**，现状 ≠ 历史。
- 只适用于 ADR 链维护良好的仓库；没有 ADR 的仓库退化为 git log 考古，成本更高结论更弱。
- 决策拓扑里"reversed by"是关键边：只看 accepted 的条目会漏掉"为什么当初的反方向被否"的论证（如 0006 的反方论证在 0007 里被逐条回应）。

## 证据

session 01a0af3a（algommw→algommw-plus 迁移研究）：纪要 §4 为 0001..0008 逐条一行拓扑表，含 status（superseded/reversed/accepted + 日期）；§7 DO-NOT 清单逐条可映射回 ADR 裁决。会话内 20 次只读文件访问含 docs/adr/ 全部 8 篇。
