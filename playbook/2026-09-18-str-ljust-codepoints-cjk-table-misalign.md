---
id: str-ljust-codepoints-cjk-table-misalign
type: lesson
status: validated
scope: global
domain: cli-output
tags: [python, cjk, terminal-table, display-width, formatting]
triggers:
  - "用 f\"{s:<58}\" / str.ljust 给人类可读的终端表格对齐"
  - "表格里混有中文表头或中文文件名，某几列整体错位（失败信号）"
  - "ASCII 数据行是齐的，带中文的行不齐、右边缘对不上"
  - "给 CLI 写 scan / list / frame 这类人类可读表格输出"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a80b-0eeb-7719-ba82-31f86fbaeaa7
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# `str.ljust` 按码位补空格，CJK 占 2 显示列：终端表格按字符数对齐必然错位

**主张**：`str.ljust` / `f"{s:<N}"` 按**码位（code point）**补空格，而终端里 CJK 字符占 **2** 个显示列——单元格里只要含中文，补出来的宽度就比预期窄/宽，整张表格的后续列错位。要给终端表格对齐，必须按"显示宽度"补：先算 `width = sum(2 if is_wide(ch) else 1 for ch in text)`，再补 `" " * max(0, N - width)`。

**证据（同一 CLI 修前 / 修后，会话 01a0a80b）**：
- 修前 `frame` 表头与数据（原样）：

  `波束      最大目标位置 ...`
  `远波束     r#3(20b) 3.344m ...`

  表头"波束"（2 码位）补 6 空格 = **10 显示列**，"远波束"（3 码位）补 5 空格 = **11 显示列**，第二列起点差 1 列。
- 修后同一条命令：`波束    最大目标位置 ...` / `远波束  r#3(20b) 3.344m ...`，两者都以 8 显示列起第二列。
- 落地实现（`spc865/tools/cli.py`）：`_is_wide(ch)` 枚举全角码点区间（`0x1100–0x115F`、`0x2E80–0xA4CF`、`0xAC00–0xD7A3`、`0xF900–0xFAFF`、`0xFE30–0xFE6F`、`0xFF00–0xFF60`、`0xFFE0–0xFFE6`），`_display_width()` 累加，`_pad(text, width)` 按差值补空格；该文件的 docstring 把"仓库里真实存在中文数据集目录名"记为动机。

**边界 / 反例**：手写码点区间覆盖不了 emoji、变体选择符、ZWJ 组合序列，这些在不同终端的列宽另有规则；更稳的是 `unicodedata.east_asian_width(ch) in ("W", "F")` 或 `wcwidth`。这条只在**等宽终端**下有意义——终端/字体不等宽时补空格救不了。

**失败信号（未来命中即该想起本条）**：数据行与表头右边缘不齐，且错位量随该行中文个数变化。
