---
id: offline-radar-datapath-derived-params-reconcile
type: fact
status: candidate
scope: project:sr61
domain: radar-config
tags: [sr61, radar, chirp, config, mmwave-calculator, reconciliation]
triggers:
  - "核对雷达波形配置是否与 mmwave_Calculator.m / MATLAB 计算器参数一致"
  - "在离线 datapath 仓库里搜 startFreq / freqSlope / idleTime 找不到（失败信号，不代表缺失）"
  - "SR61/UCM221 配置参数对账"
  - "判断离线处理仓库要不要改波形配置"
  - "找 SR61 仓库的 config（不在顶层，在 src/config，含 default.yaml / datapathconfig.c）"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:019fab6b-29cf-7267-a6a6-ec475346f32c
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: []
---
# SR61 离线 datapath 仓库存的是派生量不是原始 chirp profile——对账前先换算再比

## 主张

SR61_datapath 这类**离线处理仓库本身不存原始 chirp profile**（startFreq / freqSlope / idleTime 是雷达固件采集时用的参数），只存**派生量**（每 chirp 采样数、chirp 数、RF_RX_NUM 等）。所以核对"MATLAB 计算器参数 vs 仓库配置"时，**先把计算器的原始输入换算成派生量，再逐项对账**；直接按原始字段名去仓库里搜，搜不到会误判成"缺失/不一致"。

## 证据（session 内调查实录）

- 顶层 `ls config/` 不存在（exit 1）；实际配置在 `src/config/`：`config.h / datapathconfig.c / default.yaml / radar_config_manager.c / sr61_config.c`。
- `diff src/config/datapathconfig.c include/config/datapathconfig.c` 无输出——两份拷贝当前一致。
- `grep -rn RF_RX_NUM` → `src/utils/getdata/readDataFromFile.h:20: #define RF_RX_NUM 4`。
- 结论（换算成派生量逐项对账后）：仓库当前波形配置与 `mmwave_Calculator.m` 的参数完全一致，**无需修改**。

## 边界

- 结论基于该次对账时的仓库状态；固件或 MATLAB 计算器输入变更后需重新换算对账。
- verified_by 标 human：仓库结构由命令佐证，但"参数完全一致"是分析性判断，非单条命令可证。
