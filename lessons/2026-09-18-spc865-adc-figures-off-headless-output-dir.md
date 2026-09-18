---
id: spc865-adc-figures-off-headless-output-dir
type: fact
status: candidate
scope: project:spc865
domain: radar-analysis
tags: [spc865, matlab, headless, env-var, 产物路径, adc]
triggers:
  - "在无显示器 / agent 会话里跑 SPC865 的 MATLAB ADC 分析脚本，不想弹图窗阻塞"
  - "跑完 awr294x_spc865_v1.m 后找不到生成的分析图，不知道产物落在哪个目录"
  - "要批处理/回归跑 SPC865 ADC 分析并收集产物文件"
  - "想知道 SPC865 ADC 脚本的环境变量开关（如 SPC865_ADC_SHOW_FIGURES）怎么用"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a819-cfaa-7485-9b7c-35a2cf425d94
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [spc865-top-level-shadow-copies, macos-matlab-app-bundle-not-in-path]
---

**主张**：SPC865 的 ADC 分析脚本可以用环境变量 `SPC865_ADC_SHOW_FIGURES=0` 关掉图形显示做无头批处理，图像产物写在仓库的 `output/adc_analysis/` 目录下。

## 为什么（本会话实证）

- 调用：`cd /Users/zodyne/Dev/SPC865 && mkdir -p output/adc_analysis && rm -f output/adc_analysis/* 2>/dev/null; time SPC865_ADC_SHOW_FIGURES=0 SPC865_ADC_SAVE…`（切片里该行被截断，`SPC865_ADC_SAVE…` 之后不可见）
- 该次运行输出 `Elapsed time is …`，随后 `ls -la output/adc_analysis/` 显示目录在运行时刻（Sep 16 10:46）被写入，内含一个 `-rw-r--` 产物文件。
- 同切片的收尾结论为 `已跑通`。

## 怎么做

1. 无头跑：先 `mkdir -p output/adc_analysis`（并清旧产物），再加前缀环境变量 `SPC865_ADC_SHOW_FIGURES=0` 调 MATLAB（本机路径 `/Applications/MATLAB_R2024a.app/bin/matlab`，配 `-batch`）。
2. 取产物：直接读 `output/adc_analysis/` 下的文件，不必依赖 stdout。
3. 需要保留旧产物时别照抄 `rm -f output/adc_analysis/*`——那是本次为了干净复跑才做的。

## 边界

- 本会话只确证了 `SPC865_ADC_SHOW_FIGURES=0` 这个开关名与产物目录；其余 `SPC865_ADC_SAVE…` 之类变量在切片里被截断，其确切名字/取值语义**未核实**，下次用前先 `grep -n "SPC865_ADC" awr294x_spc865_v1.m` 看脚本自己怎么读。
- 产物目录是仓库工作区内的 `output/adc_analysis/`（属于可再生产物，注意 .gitignore 口径）。
- 顶层 `awr294x_spc865_v1.m` 与 `MatlabSpc865/` 下可能有同名影子副本，改/跑之前先确认跑的是哪一份（见 related）。
