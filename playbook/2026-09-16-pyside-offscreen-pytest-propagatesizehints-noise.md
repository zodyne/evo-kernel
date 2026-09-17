---
id: pyside-offscreen-pytest-propagatesizehints-noise
type: lesson
status: validated
scope: global
domain: pyside6
tags: [pytest, offscreen, qt, log-noise]
triggers:
  - "PySide6 离屏跑 pytest，输出被 propagateSizeHints 日志刷屏，看不到真实断言结果"
  - "Qt offscreen 模式下每次 resize 打印大量 propagateSizeHints 到 stderr 污染测试输出"
  - "pytest 通过但 stdout 被 Qt 平台日志淹没，分不清哪些是断言失败"
  - "想干净地看 PySide6 offscreen 测试的 PASS/FAIL 行而不是被 Qt 噪音打断"
  - "跑 GUI 冒烟测试，结果里满是 qt.qpa 日志而非测试结论"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a851-cb59-7719-ba82-320642646fd4
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [cocoa-platform-verify-gl-render-errors, 2026-07-27-qt-offscreen-opengl-context-warnings-nonfatal]
---

PySide6 在 `QT_QPA_PLATFORM=offscreen` 下跑 pytest 时，Qt 会反复打印 `propagateSizeHints to ...` 到 stderr 刷屏、淹没真实断言/失败行；用 `2>&1 | grep -v propagateSizeHints` 过滤后就能看到干净的 PASS/FAIL 结论。

SPC865 工作台改造中，offscreen 跑 `python3 -m pytest tests/python/test_ui_smoke.py -q` 时输出被 `propagateSizeHints` 刷屏，看不到断言结果；改成 `2>&1 | grep -v propagateSizeHints | tail` 后稳定看到 `................ [100%]` 与 16 passed 的真实结论，反复用了 6+ 次均奏效。

反例/边界：过滤时保留非零退出码，不要把 `grep -v` 接到末尾导致退出码被 grep 吞掉（用 `set -o pipefail` 或让 grep 在中段而非结尾）；除 propagateSizeHints 外还有 `qt.qpa.fonts` 字体别名告警这类噪音，但 propagateSizeHints 是最高频、最遮断断言结果的源头。
