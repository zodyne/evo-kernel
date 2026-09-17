---
id: matplotlib-cjk-font-order-first-silences-missing-glyph
type: lesson
status: validated
scope: global
domain: visualization
tags: [matplotlib, cjk, chinese-font, macos, visualization, font-order]
triggers:
  - "matplotlib 画中文图报 Glyph ... missing from font 缺字警告"
  - "设了 CJK 字体但仍有缺字警告/方块"
  - "matplotlib 缺字 UserWarning 刷屏（失败信号）"
  - "想让 matplotlib 默认优先用 CJK 字体而非回退"
  - "macOS 上 matplotlib 中文标注图有缺字警告"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a4ee-6d56-777c-a410-3236022192ef
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [matplotlib-cjk-verify-font-before-plot]
---

# matplotlib 中文缺字警告：把 CJK 字体族放到 font list 最前即清零

## 主张

matplotlib 出中文图时冒 `UserWarning: Glyph X missing from font(s) Helvetica Neue`，根因不是「没装 CJK 字体」，而是默认字体族（Helvetica Neue 等）不含 CJK、被排在列表最前先试。把 CJK 字体族（本机实测 `Noto Sans CJK`）放到 `font.sans-serif` 列表**最前**，缺字警告从多条直接清零。

## 证据

- `font_manager` 枚举到 326 个可用字体族后，仍先按默认栈 Helvetica Neue 试字 → 报 `Glyph 36895 (速) missing from font(s) Helvetica Neue`。
- 把 CJK 字体放最前后：`CJK 在前 → 缺字警告 0 条 | 栈 ['Noto Sans CJK ...']`。

## 边界

- 与 [[matplotlib-cjk-verify-font-before-plot]] 相邻但不同：那条讲「出图前验证字体是否存在/可枚举」，本条讲「字体已存在但排序靠后仍会缺字警告」。
- 只针对缺字**警告**；若字体真的未安装，仍需先走验证那条。
