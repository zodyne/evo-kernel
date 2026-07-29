---
id: 2026-07-28-macos-qt-cmd-key-maps-to-control-modifier
type: playbook
status: validated
scope: global
domain: qt-input
tags: [qt, pyside6, pyqt, macos, modifier, keyboard, control, meta, multiselect, cross-platform]
triggers:
  - 在 macOS 上用 Qt/PySide6/PyQt 做多选交互（点击加选 / 框选追加）
  - 跨平台 Qt 程序的 Ctrl+点击 / Cmd+点击 加选在 mac 上失效，只判 Qt.ControlModifier
  - 想知道 macOS 上物理 Ctrl 键和 ⌘(Command) 键在 Qt 里分别对应哪个修饰符
  - 多选代码在 Windows/Linux 正常、到 macOS 按 ⌘ 没反应
  - 跨平台处理"修饰键 + 鼠标点击"交互，判断该接收哪些 modifier
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:b417294c-e36b-45ac-a400-4a60f30d3453
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
---

# macOS 上 Qt 把 ⌘ 映射成 ControlModifier、物理 Ctrl 映射成 MetaModifier——多选要同时收两个

在 macOS 上做 Qt 多选（加选）交互，**必须同时接收 `Qt.ControlModifier` 和 `Qt.MetaModifier`**：Qt 在 macOS 把物理 ⌘（Command）键映射成 `ControlModifier`、把物理 Ctrl 键映射成 `MetaModifier`（与 Windows/Linux 的直觉相反）。只判 `ControlModifier` 的代码在 Windows/Linux 能用，到 macOS 上用户最自然的 ⌘+点击 加选会失效。Shift 通常不受这套映射影响，可单独保留。

## 为什么

macOS 的惯例是"⌘+点击 加选"，但 Qt 为了让跨平台代码"只判 ControlModifier 就能跑"，在 macOS 把 ⌘ 映射进了 `ControlModifier`，把物理 Ctrl 让位给 `MetaModifier`。结果：写 `if ev.modifiers() & Qt.ControlModifier` 的代码在 mac 上确实能被 ⌘ 触发——但**只用 Ctrl 键的 mac 用户会漏掉**（因为物理 Ctrl 走的是 MetaModifier）。要覆盖"⌘ 或 Ctrl 都能加选"的直觉，得把两个修饰位都收下。

## 证据

本会话做 pyqtgraph.opengl 点云查看器（`viewer_filtered.py`）的多选时，在 `viewer_filtered.py:1160` 实现了同时收 Control 与 Meta 两个修饰位；用 `test_pick.py` 端到端验证加选行为：

```
$ python3 test_pick.py 2>&1 | grep ...
  ↳ accum 9367 pts, 1 selected, tags: ['#1 · R281m']
    after ctrl+click x3, tags: ['#1 · R281m', '#2 · R237m', '#3 · R261m', '#4 · R287m']
    exit code: 0
```

连续 ctrl+click 后选中集合从 1 个增长到 4 个，加选逻辑生效。映射规则（⌘→Control、Ctrl→Meta）本身是 Qt 在 macOS 的已知行为（文档级），本会话引用它来决定收哪些修饰位，并用端到端加选测试验证了实现正确。

## 怎么做

1. 判加选修饰位时写并集：`mods & (Qt.ControlModifier | Qt.MetaModifier)`（⌘ 或 Ctrl 任一即加选），别只写 `Qt.ControlModifier`。
2. Shift 单独判：`mods & Qt.ShiftModifier`，不受这套映射影响。
3. 若需要区分"用户到底按的是 ⌘ 还是 Ctrl"（mac 上很少需要），再用 `Qt.MetaModifier` 单独位测——多数交互只要"加选"语义，不必区分。
4. 跨平台代码用同一套 `(Control | Meta)` 并集即可，Windows/Linux 上 MetaModifier 基本不触发，不会误判。

## 边界

- 这条是 Qt 在 macOS 的修饰键映射约定，针对鼠标点击事件里的 `modifiers()`；纯键盘快捷键（QShortcut / QKeySequence）的 "Ctrl+C" vs "Cmd+C" 另有平台化处理，别混。
- 证据来自 PySide6 6.11.0 + macOS；映射原理未用命令独立验证（是 Qt 文档行为），端到端加选行为有 test_pick.py 输出佐证。
- 若产品要求严格区分 ⌘ 与 Ctrl 的不同含义（而非统一当加选），需要按平台分别处理，本条不适用。
