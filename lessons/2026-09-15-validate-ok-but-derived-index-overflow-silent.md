---
id: validate-ok-but-derived-index-overflow-silent
type: lesson
status: candidate
scope: global
domain: verification
tags: [validate, return-code, overflow, ddm, verification]
triggers:
  - "init/validate 返回 eOk（0）但下游计算结果静默错，怀疑校验只查了配置维度"
  - "eWaveformValidate / eChainInit 类函数返回成功，但 fold 表等派生数据结构的索引值回绕或越界"
  - "只有打开某个特性开关（如 doppler_cfar）才报 eStatus 错，关掉就静默跑通（失败信号）"
  - "对账要读实际计算值（fold 表内容、doppler 输出）而非只看 validate/init 返回码"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a6b9-89c5-7353-8a3d-42e7d5d82a48
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [diagnose-by-measured-output-not-proxy-status-word, validation-params-readable-from-artifact]
---

主张：init/validate 返回 `eOk`（0）只表示「配置维度合法」，不校验派生数据结构的容量、也不代表下游数值正确；对账必须读实际计算值（fold 表内容、doppler 输出），不能只看返回码。

为什么：algommw `eWaveformValidate(subbands=384, chirps=768, perSub=2)` 返回 0（eOk），`eChainInit` 在 doppler_cfar=off 时也返回 OK，但全链跑出来的 `xFold[100][0] = 0`（真实 256）、xDoppler=+0.000 m/s 静默错值。校验只检查了配置维度（subbands/chirps/perSub 是否合法），没检查「派生 fold 表能否容纳 fold 索引值域」。

反例/边界：与 `validation-params-readable-from-artifact`（参数没到产物、配置不一致）不同——这里参数确实到了、配置确实合法，错在派生索引回绕；与 `diagnose-by-measured-output-not-proxy-status-word`（组件失效诊断）也不同——这里是「返回码绿 ≠ 数值对」。关键证据：doppler_cfar=on 时 `eChainInit failed: eStatus=2` 才拦住，off 时静默跑通——同一溢出在不同特性开关下「有时报错有时静默」，只测默认配置会漏。

证据链接：`/tmp/slice.txt` 行 20（`eWaveformValidate(...)=0 (0=eOk)`）、行 59（doppler_cfar=on → `eChainInit failed: eStatus=2`，off → OK）、行 69（`xFold[100][0]=0` 真实 256 → `xDoppler=+0.000 m/s`）、行 87-88（`radar.h:65` `uint8_t xFold`；`waveform.c:73` DDM 分支只查 subband…）。
