---
id: pyside6-qss-ancestor-rule-hits-child-qframe
type: lesson
status: validated
scope: global
domain: pyside6
tags: [qss, qframe, qlabel, stylesheet, sizepolicy, ui]
triggers:
  - "PySide6 setStyleSheet('QFrame {...}') 命中所有子 QFrame，出现幽灵圆角框"
  - "QLabel 继承 QFrame 导致祖先 QSS 规则命中标签（失败信号）"
  - "QSS 作用域隔离要 setObjectName + QFrame#topBar"
  - "QHBoxLayout 把 chip/pill 标签拉满整条栏高"
  - "子控件自己的 QSS 覆盖不了祖先规则里未显式写的属性"
created: 2026-08-19
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-08-19-05-55-20-821-0ayq
last_verified: 2026-08-19
superseded_by: null
schema_version: 1
related: []
---

# 主张

PySide6 QSS 作用域坑：给容器设 `setStyleSheet('QFrame { border-bottom:...; border-radius:10px }')` 会命中所有子 `QFrame`——而 **`QLabel` 继承自 `QFrame`**，于是栏内每个标签都套上了这圈 border/radius，渲染出「幽灵圆角框」（子控件自己的 QSS 只覆盖它显式写的属性，未写的仍从祖先规则继承）。

修法：`setObjectName('topBar')` + `'QFrame#topBar { ... }'` 限定作用域。

# 同类坑

`QHBoxLayout` 会把默认 `Preferred` 纵向策略的 `QLabel` 拉满整条栏高——chip/pill 类标签必须 `setSizePolicy(Preferred, Fixed)`。

# 证据

afm761 workbench 顶栏/底栏，离屏 `window.grab()` 截图逐块放大发现。
