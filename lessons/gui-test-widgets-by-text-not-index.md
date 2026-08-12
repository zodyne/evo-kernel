---
id: gui-test-widgets-by-text-not-index
type: lesson
status: candidate
scope: global
domain: gui-testing
tags: [pyside, qt, gui-test, regression]
triggers:
  - "Qt 自动化测试 findChildren 按索引取控件"
  - "GUI 测试全部通过但功能没测到"
  - "界面加了新控件后旧测试假通过"
  - "QComboBox/QCheckBox 索引选取"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:6f9c92c5
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---

**主张**：Qt/PySide 自动化测试里用 `findChildren(QCheckBox)[0]`、`QComboBox[1]` 这类**索引**取控件是静默炸弹：界面新增任何控件都会让索引整体后移，测试不报错但测的是错的控件——会出现「15 组组合全部通过」实际一次都没切到目标控件的假通过。应按可见文本或 objectName 选取。

**为什么**：实测中参数卡片加了 `n_grid` 下拉后，`cycle_combos` 的索引选取整体错位一位；`findChildren(QCheckBox)[0]` 取到的是新加的「逐帧自适应阈值」而非「全量累积」。两处都是测试脚本自身缺陷，被测程序无锅。

**边界**：文本选取注意 i18n/改文案同步更新；关键路径建议给控件显式 setObjectName 后按名取，最稳。

**证据**：2026-07-27 ucm221 viewer_filtered.py 累积功能测试会话，两次索引失效均被实测复盘抓出。
