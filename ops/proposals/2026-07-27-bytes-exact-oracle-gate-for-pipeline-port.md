---
id: bytes-exact-oracle-gate-for-pipeline-port
type: lesson
status: candidate
scope: global
domain: verification
tags: [oracle, regression, byte-exact, signal-pipeline, freertos, refactor]
triggers:
  - "把现有可信数据流水线（信号处理/测角/点云/航迹）移植到新框架或换调度模型"
  - "FreeRTOS/RTOS 多任务流水线重构，担心输出与原离线路径不一致"
  - "新路径只做了功能跑通，没和参考实现做逐字节/逐帧比对"
  - "重构后偶现数值漂移/帧错位/点云偏移，却无参考路径可对照"
  - "需要给一条已有 golden/oracle 输出的流水线加自动化正确性闸门"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:d6f040ef-58b7-479b-b7b1-828357cd275f
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# 把可信数据流水线移植到新框架，必须用"与参考 oracle 逐字节一致"做正确性闸门，而不能只看"跑通了/结果合理"

## 主张
当一条**已经有可信参考输出**的数据流水线（如离线 PC 上的信号处理/测角/点云/航迹路径）被移植/重构到新框架（如 FreeRTOS 多任务、换调度模型、换内存布局）时，正确性验证的硬闸门应当是：新路径的输出与参考路径（oracle / golden）**逐字节（或逐帧逐点）完全一致**，而不是"调度器跑完没崩""点云看起来有值""量纲大致合理"这类软判断。逐字节一致把"数值正确"从主观断言降级为机器可判定的二值校验，能挡住重构引入的隐蔽回归（任务间内存别名、浮点重排、缓冲对齐、丢帧、字节序）。

## 为什么
重构只换"如何调度/如何组织"，不换"算什么"。既然算的东西不变，输出就**必须**与原路径位级相同；任何差异都是 bug。本会话正是把这套用在了 FreeRTOS 五任务流水线对齐离线参考路径上——构建同时产出被测路径与参考路径，再在 gate 里强制比对。

## 证据（本会话命令 ↔ 结果，切片硬证据）
- `tests/freertos_gate/CMakeLists.txt` 内容：`stage④-a 闸门:FreeRTOS 5 任务流水线 == 同步 oracle 逐字节(` —— 把逐字节一致显式固化为 gate 阶段目标。
- `cmake --build build -j8 --target freertos_preview offline_runner` —— 同一次构建里同时产出被测路径（freertos_preview）与参考离线路径（offline_runner），二者可同台比对。
- `find ... freertos` 同时存在 `host/freertos_preview`（被测预演）与离线 runner，提供 oracle 来源。
- 末条 assistant 总结明确 `✅ 与同步 oracle 逐字节一致` 作为四项验收之一（其余为跑通/全量注入/可视化）——逐字节一致被当作与"功能跑通"并列甚至更硬的独立验收项。

## 边界 / 反例
- 仅当**存在可信参考路径**时成立。绿地算法（无 oracle）只能退化为"量纲合理 + 可视化 + 单元属性测试"等软闸门——但软闸门不等于本条的逐字节闸门，二者不要混淆。
- 逐字节一致要求新路径**有意保持**与旧路径相同的浮点求值顺序/精度；若重构目标本身包含"改精度/换算法"的合法变更，应改用"误差有界（tolerance）"而非逐字节。
- gate 比对的是端到端输出；若流水线含非确定性来源（如真实传感器抖动），oracle 应取**固定回放数据**而非实时采集。

## 失败信号（未来命中即该想起本条）
- 重构/移植后只报"跑通了 N 帧 / 输出文件非空"，没有与参考路径做逐字节/逐帧 diff。
- 新路径点云/航迹与旧路径"看起来差不多"，但没有可重复的自动比对脚本。
- 重构后偶发数值漂移或帧错位，现场却找不到参考输出来定位是"重构引入"还是"数据问题"。
