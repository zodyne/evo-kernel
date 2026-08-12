---
id: matplotlib-cjk-verify-font-before-plot
type: lesson
status: candidate
scope: global
domain: visualization
tags: [matplotlib, cjk, chinese-font, macos, visualization, verification]
triggers:
  - "macOS 上用 matplotlib 画带中文标注的图"
  - "matplotlib 图里中文变成方块/豆腐块（失败信号）"
  - "设置了中文字体但不确定 matplotlib 是否真认到了"
  - "写绘图脚本前要先确认系统有哪些 CJK 字体可用"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fab6b-29cf-7267-a6a6-ec475346f32c
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: []
---
# macOS matplotlib 出中文图：先两级验证字体可见性 + 最小测试图，再跑主脚本

## 主张

在 macOS 上用 matplotlib 出中文标注图，**不要直接在主脚本里设个字体名就画**。按三级走：① `ls` 确认字体文件在系统里（如 `/System/Library/Fonts/PingFang.ttc`、`/System/Library/Fonts/Supplemental/Arial Unicode.ttf`）；② 用 `matplotlib.font_manager` 枚举 **matplotlib 实际可见的字体名**（`set(f.name for f in fm.fontManager.ttflist)`），文件存在 ≠ matplotlib 枚举得到；③ 先渲染一张最小中文测试图（如 /tmp/cjk_test.png）确认渲染正常，再跑主脚本，产物用 PIL 打开复核。

## 证据（session 内命令序列）

- `ls -la /System/Library/Fonts/PingFang.ttc .../Arial\ Unicode.ttf` —— 文件系统级确认。
- `python3 -c "import matplotlib.font_manager as fm; names = set(f.name for f in ...)"` —— matplotlib 可见名字枚举（会话中执行了两次）。
- 单独渲染过 `/tmp/cjk_test.png` 最小测试图；最终 `figures/` 产物生成后用 `PIL.Image.open` 复核。
- 全流程在 `matplotlib.use('Agg')` 后端下做无头验证（多次 `python3 -c` 带 Agg 的测试渲染）。

## 边界

- 本条只覆盖"出图前验证"的工作流；会话切片中各命令的具体输出被截断，未记录到具体哪个字体名最终被采用。
- Linux/Windows 字体路径不同，但"文件存在 ≠ font_manager 可见"的两级验证思路通用。
