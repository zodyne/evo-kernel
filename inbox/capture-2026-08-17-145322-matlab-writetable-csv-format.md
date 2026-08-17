---
id: capture-2026-08-17-145322-matlab-writetable-csv-format
type: fact
status: inbox
scope: global
domain: matlab-python-migration
tags: [matlab, csv, byte-exact, writetable]
triggers:
  - "MATLAB writetable CSV 格式"
  - "字节级对齐 MATLAB 输出 CSV"
  - "%.15g 数值格式复刻"
  - "CSV 输出与 golden 对比"
created: 2026-08-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:hermes-afm761-matlab-to-python-migration
last_verified: 2026-08-17
superseded_by: null
schema_version: 1
related: [bytes-exact-oracle-gate-for-pipeline-port]
---

MATLAB `writetable` 的 CSV 格式可被 Python 字节级复刻：数值用 `%.15g`（15 位有效数字，`5.09458751022913`、`1e+29` 式；**-0.0 输出 "-0"**，0 输出 "0"）；Inf/NaN 大写为 `Inf`/`NaN`；字符串仅含分隔符/引号时加引号（即 csv QUOTE_MINIMAL）。Python 对应写法：`f"{float(v):.15g}"`（inf/nan 手动替换大小写）+ `csv.writer(..., quoting=csv.QUOTE_MINIMAL, lineterminator="\n")`。实测 format_check 小表（整数/小数/-0/1e-7/1e29/字符串）与 MATLAB 产物**字节级一致**。注意：`.15g` 只保证 15 位有效数字——跨实现浮点噪声（~1e-13 相对）会落在第 15 位，因此真实数据的 CSV 对比应按字段容差（1e-9 相对）而非字节比对；字节比对只适用于格式校准（无噪声的固定值表）。字符串列名（如文件名）两侧必须精确一致。
