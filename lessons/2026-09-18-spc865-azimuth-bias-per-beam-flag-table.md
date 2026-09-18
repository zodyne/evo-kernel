---
id: spc865-azimuth-bias-per-beam-flag-table
type: lesson
status: candidate
scope: project:spc865
domain: radar-doa
tags: [spc865, doa, 方位零偏, beam-flag, 移植]
triggers:
  - "给 SPC865 移植/实现方位测角，处理方位零偏标定"
  - "SPC865 个别波束测角有固定角度残差、其他波束正常（失败信号）"
  - "想用单个全局 azimuth_bias_deg 标量替代逐波束零偏表"
  - "在 spc865_tools.py 里找 def calibrate_angle_bias（不存在，失败信号）"
  - "把 SPC865 Python 测角与 MatlabSpc865 参考实现对拍"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a80b-0e7a-7719-ba82-31f4af5174d2
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# SPC865 方位零偏是按 beam flag 查表，不是全局标量

**主张**：SPC865 参考实现的方位零偏按 beam flag 查表（`AZIMUTH_BIAS_DEG[cfg["flag"]]`，`MatlabSpc865/spc865_field_report.py:285`），各波束表值不同；而 Python 侧 `spc865/config.py` 只有单个标量 `azimuth_bias_deg: float = 0.0`（:223，:323 同值）。移植/实现 DOA 时若默认「一个全局标量够了」，非零波束会留下固定角度残差，零偏为 0 的波束却表现正常——属于静默偏差。

**证据（本会话命令 ↔ 结果）**
- `rg -n "bias" MatlabSpc865/*.py` → `spc865_field_report.py:285: bias = AZIMUTH_BIAS_DEG[cfg["flag"]]`（按 flag 取表，不是单值）。
- `rg -n "AZIMUTH_BIAS_DEG|azimuth_bias|0.963355789" -g '!*.bin' .` → `./spc865/config.py:223: azimuth_bias_deg: float = 0.0`、`./spc865/config.py:323: azimuth_bias_deg=0.0`（Python 侧无按波束的表）。
- 探针（`sys.path` 指向 `MatlabSpc865`，导入 `spc865_field_report`）逐 flag 打印 raw/+bias/−bias：`0x1111 r 2 d 32 E 136.859 raw 0.25 +bias 0.25 -bias 0.25 centroid 0.4892 0x2222 r 5 d 32 E 140.378 raw 0.75 +bias 1.75 -…` → 0x1111 表值为 0（±bias 与 raw 相同），0x2222 表值为 +1.0°（0.75 → 1.75）。
- `rg -n -B5 -A25 "def calibrate_angle_bias|def .*angle_bias" MatlabSpc865/spc865_tools.py` → 无输出：不要按这个函数名找标定入口；标定输出走的是 CLI 参数 `--output spc865_100m_angle_bias_calibration.csv`（`spc865_tools.py:528`）。
- Matlab 侧同段配置另有按波束字段 `azimuthBiasDegByBeam`（`MatlabSpc865/matlab/view_spc865_continuous_adc.m`，该段还含 `doaModeName: PDF_ARRAY_DBF`、`angleGridDeg: -70:0.5:70`）。

**边界 / 反例**
- 本次只实测了 0x1111 / 0x2222 两个 flag 的表值，未穷尽全部 `AZIMUTH_BIAS_DEG` 内容。
- 本条只锁定「参考实现是 per-flag 表、Python config 是单标量」；若 `spc865/doa.py` 内部另有 per-beam 补偿，应以代码为准。
- 零偏为 0 的波束无法用「加/减 bias 结果不同」检出——校验要挑一个表值非零的 flag。

**失败信号**：对拍时只有部分波束存在固定角度偏移（约 1° 量级），且偏移波束的 flag 对应 `AZIMUTH_BIAS_DEG` 非零项。
