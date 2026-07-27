---
id: native-posix-freertos-preview-before-mcu
type: lesson
status: validated
scope: global
domain: embedded
tags: [freertos, native-posix, host-target, mcu, portability, debuggability]
triggers:
  - "FreeRTOS/RTOS 嵌入式项目，需要先把多任务流水线在 PC 上验证再上 MCU"
  - "直接在 MCU 上调多任务流水线，烧录/断点周期长、定位困难"
  - "需要在 host(离线PC) 与 embedded(真实MCU) 目标之间切换构建"
  - "C 核心想零第三方、但要在 POSIX 上预演 RTOS 调度行为"
  - "算法逻辑 bug 直到上 MCU 才暴露，反馈环太慢"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:d6f040ef-58b7-479b-b7b1-828357cd275f
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# FreeRTOS 嵌入式流水线：先用 native-POSIX host target 在 PC 上跑通预演，再上 MCU

## 主张
嵌入式 FreeRTOS 项目不要一上来就在 MCU 上调多任务流水线。应先用 **native-POSIX（host target）** 把同一套任务/调度在 PC 上跑成一个可调试的"预演（preview）"：能正常断点、能注入真实采集数据全量回放、能在秒级重建/重跑。PC 预演跑通 + 与参考路径逐字节一致后，再切到 embedded（MCU + toolchain）目标。这把"调度逻辑/任务间接线/数据通路"的正确性验证从 MCU 的长反馈环（烧录/串口/有限断点）前移到 PC 的短反馈环。

## 为什么
MCU 调试成本高、反馈慢；而 FreeRTOS 的任务划分、消息流、数据通路在 POSIX 上的语义可高度复现。让"算什么 + 怎么调度"先在 PC 上被验证为对，MCU 侧就只剩"硬件/外设/时序适配"这一层窄风险面。本项目正是用 `BUILD_TARGET: host | embedded` 双目标 + `BUILD_FREERTOS_PREVIEW` 开关支撑了这条链路：host 预演目录（`host/freertos_preview`）与真实 MCU 目录（`platform/freertos`）解耦，共享同一 C 核心。

## 证据（本会话命令 ↔ 结果，切片硬证据）
- 根 `CMakeLists.txt`：`BUILD_TARGET: host(离线PC开发/测试) | embedded(真实MCU,需配合 cmake/toolchains/` —— 双目标构建是一等设计，host 明确标注"离线PC开发/测试"。
- `find ... freertos` → 同时存在 `./host/freertos_preview`（PC 预演）与 `./platform/freertos`（真实 MCU）两个目标目录，预演与真机解耦。
- `host/freertos_preview/{CMakeLists.txt,main.c}` 存在 —— 预演有独立入口，非临时脚本。
- `build/CMakeCache.txt:18: BUILD_FREERTOS_PREVIEW:BOOL=ON` —— 预演目标在构建配置里显式开启。
- `cmake --build build -j8 --target freertos_preview offline_runner` → 成功（`freertos_kernel / host_config / freertos_preview` 等 built），native-POSIX 上可独立构建运行。
- `freertos_preview: 调度器结束` + 真实 `20Km_h` 采集存在并全量注入跑通 —— 预演不是空跑，是真实数据端到端。

## 边界 / 反例
- POSIX 预演**无法复现**真机时序、中断抖动、DMA/外设、缓存命中差异——这些只能在 MCU 上验。预演验的是"逻辑/调度/数据通路"，不是"实时性/外设"。
- 任务若重度依赖具体硬件外设驱动，预演需要桩（stub）/回放层；桩与真机行为不一致会制造假阳性或假阴性。
- 预演路径与真机路径必须共享同一份核心计算代码（本项目即"C 核心零第三方"），否则预演通过的逻辑对真机无意义。

## 失败信号（未来命中即该想起本条）
- 一个 FreeRTOS/RTOS 多任务流水线 bug，只能在 MCU 上复现、PC 上无从下手。
- 项目只有 embedded 目标、没有 host/preview 目标，每次改调度都要烧录验证。
- host 预演与 MCU 真机各维护一套计算代码，预演结果无法背书真机。
