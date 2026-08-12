---
id: fact-ucm221-repo-restructured-2026-07-29
type: fact
status: validated
scope: project:ucm221
domain: project-layout
tags:
- ucm221
- repo-structure
- git
- workspace
triggers:
- 在 ~/Dev/ucm221 仓库里找某个算法/脚本/历史迭代
- 要确认 ucm221 仓库的目录结构与当前任务分支
- 找 UCM221 关联仓库（ucm221-cal / ucm221-pointcloud-2.0 / libucm221）
- 找 2026-07-29 清理重组之前的 ucm221 文件快照
created: 2026-08-12
evidence:
  helpful: 0
  harmful: 0
verified_by: human
source: 人工（整理 inbox/capture-2026-07-29-02-23-18-583-b2gk.md）
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related:
- episode-ucm221-project-overview
---
# UCM221 主仓库 2026-07-29 清理重组后的结构

`~/Dev/ucm221` 自 2026-07-29 起为 git 仓库，任务分支 `task/array-layout-doa-perf`。结构：

- `core/`：`robust_doa_estimation.m`、`Radar_Calibration_DOA_Integration.py`（2035 行主参考）、`scheme_b_final.py`（当前最优测角法）
- `analysis/`：阵列布局测角性能任务工作区
- `archive/`：scheme-b 迭代 / 质量过滤 / FPGA 验证 / 早期 DOA / C 移植 / 生成输出，六个专题
- `data` 与 `20260508暗室角度采集` 在 .gitignore 中，不入库

清理前快照在 main 分支首个提交。关联仓库：`ucm221-cal`（质量过滤）、`ucm221-pointcloud-2.0`（主研究库）、`libucm221`（C 库）。

**证据**：capture-2026-07-29-02-23-18-583-b2gk（重组当日记录）。
