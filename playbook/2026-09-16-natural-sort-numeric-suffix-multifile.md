---
id: natural-sort-numeric-suffix-multifile
type: lesson
status: validated
scope: global
domain: data-loading
tags: [multi-file, sorting, numeric-suffix, radar-data]
triggers:
  - "批量加载文件名带数字后缀的多个数据文件（_0/_1/.../_10）"
  - "多文件合并成一个全局帧/样本索引，发现 _10 排在 _2 前面"
  - "用 sorted() 对带数字的文件名排序，帧序或时序错乱（失败信号）"
  - "全局帧索引映射到 (文件, 帧) 时出现跳变或顺序错误"
  - "给多文件雷达 .bin 数据做帧导航/回放，序列对不上"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a897-7169-7719-ba82-320dc0372fe4
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: []
---

批量加载文件名带数字后缀的多个数据文件时（如 `..._0.bin`、`..._1.bin`、`..._10.bin`），必须按自然序（natural sort）排序，不能直接用字典序 `sorted()`，否则 `_10` 会排在 `_2` 前面，跨文件的全局帧/样本索引映射错乱。

**为什么**：雷达采集数据常按 `_0/_1/_2/.../_99` 数字后缀命名并切成多个 .bin 文件。字典序逐字符比较会把 `_10` 排在 `_2` 前（首字符 `1` < `2`），导致多文件合并后的帧序列错位。SPC865 工作台的帧导航模型把 13 个文件（各 100 帧）合并成 1300 帧的全局索引，用前缀和 offsets（0,100,200,...）做 g→(文件,帧) 映射，文件顺序必须自然序才能保证映射正确。

**边界**：固定宽度补零（`_000/_001`）时字典序与自然序一致，可不用额外处理；单文件无排序问题；natsort 库或自定义 `key=用正则提取数字 int()` 均可实现。

**证据**：session 中用户需求「可以观察数据文件的命名是有顺序的，多文件直接加载」；新增测试 `test_natural_order_drives_file_sequence`（tests/python/test_ui_smoke.py）并通过（pytest 29 passed）；探针脚本输出 `文件数 13 全局帧数 1300 offsets 前3 (0, 100, 200) g=99 -> 文件 0 帧 99`，佐证自然序驱动的多文件帧映射正确。
