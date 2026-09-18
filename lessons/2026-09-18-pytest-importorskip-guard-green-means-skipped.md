---
id: pytest-importorskip-guard-green-means-skipped
type: lesson
status: candidate
scope: global
domain: python-testing
tags: [pytest, importorskip, pyside6, headless, acceptance-gate]
triggers:
  - "pytest 全绿就宣布 GUI / 可选依赖测试已覆盖（失败信号：套件里是 pytest.importorskip 守卫）"
  - "在没装 PySide6/PyQt 的机器上跑 Qt 测试套件，结果全绿、零失败、零跳过数字被忽略"
  - "验收 PySide6 无头（QT_QPA_PLATFORM=offscreen）套件，想知道 UI 断言有没有真跑过"
  - "接手用 pytest.importorskip('PySide6.QtCore') 守卫测试模块的仓库（如 spc865-adc 的 tests/test_ui_smoke.py）"
  - "要『绿=跑过』的硬证据时应核对 skipped / collected 计数，而不是只看 passed 行（失败信号：pass 行里没有一条 UI 用例名）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a97a-5057-77c1-a593-51a710b621fb
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [cocoa-platform-verify-gl-render-errors, pyside-offscreen-pytest-propagatesizehints-noise, mutation-testing-verifies-tests-catch-bugs]
---

**主张**：测试模块用模块级 `pytest.importorskip("PySide6.QtCore")` 之类的守卫时，依赖缺失会让**整个模块被跳过**，pytest 依然全绿——所以「全绿」不能当作 GUI/可选依赖测试跑过的验收证据；验证时要么先确认依赖在位，要么读 skipped / collected 计数。

**为什么**：`importorskip` 在模块导入期执行，缺包时抛 skip，pytest 直接跳过该模块的收集——passed 与 failed 都不变，只有 skipped 计数变化；而 `-q` 摘要行里 skipped 很容易被人眼略过。GUI 测试又偏偏常用这种守卫，于是「没装 PySide6 的机器上跑出一片绿」与「UI 断言一条都没执行」可以同时成立。

**证据（本 session slice 命令 ↔ 结果）**：
- `sed -n '1,40p' tests/test_ui_smoke.py | tail -5` → 输出末尾三行是 `import numpy as np` / `import pytest` / `QtCore = pytest.importorskip("PySide6.QtCore")`——`tests/` 下的 UI 测试确实在模块级用 importorskip 守卫 PySide6。
- `head -80 tests/test_ui_smoke.py` → 模块 docstring 自述是「工作台（`spc865.ui.workbench` / `spc865.ui.app`）的**无头冒烟契约**」，并给出运行方式 `QT_QPA_PLATFORM=offscreen python3 -m pytest tests/pyth…`（切片截断）。
- 本 session 15 条命令全是只读测绘（`ls` / `head` / `sed` / `grep` / `wc`），**没有跑过 pytest**，因此没有观测到 skip 实例；「缺依赖 ⇒ 整模块跳过」是对 importorskip 语义的推断，故 `verified_by: human` 而非 command。

**反例 / 边界**：
- 依赖在位时绿色是真的，本条不主张「绿一定假」。判断依赖在不在：`python3 -c 'import PySide6'`；要看跳没跳：`pytest -q -rs` 读 skipped 行，或对比 collected 数与 `def test_` 数。
- `importorskip` 的本意是让缺依赖的机器（无头开发机/CI）不硬红，本条不主张删守卫，只主张**别把它产生的绿当验收证据**。
- 本 session 只读了 `tests/` 下文件，docstring 里的运行路径被截断（`tests/pyth…`），引用确切命令前要按仓库实际布局核对（同名会话记录里出现过 `tests/python/` 与 `tests/` 两种形态）。
- 本 session 未复现「因 importorskip 静默跳过而误判验收通过」的实例；本条是在测绘中发现该守卫模式后归纳的潜在坑，需后续会话用 `pytest -rs` 实例补硬证据。
