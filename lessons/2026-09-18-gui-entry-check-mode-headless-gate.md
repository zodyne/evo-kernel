---
id: gui-entry-check-mode-headless-gate
type: lesson
status: candidate
scope: global
domain: qt-gui
tags: [pyside6, cli-entry, headless, acceptance-gate, dry-run]
triggers:
  - "交付 PySide6/Qt GUI 入口（app.py / main 窗口），环境没有显示器或不想起真实窗口"
  - "GUI 车道收尾，验收只剩『人工起界面看一眼』一条路（失败信号：没有可脚本化的入口门禁）"
  - "GUI 进程起了就挂住、要人手关，脚本化验收卡在事件循环上（失败信号）"
  - "新写/改 CLI 入口后，要证明数据扫描与参数校验链路跑通而不进 Qt 事件循环"
  - "离屏 pytest 只覆盖了面板/视图，入口链路（数据集扫描、--file、参数校验）仍无验收项"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a819-f111-7719-ba82-31ff3af877d7
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [untested-tool-config-bugs-stay-invisible, pyside-offscreen-pytest-propagatesizehints-noise]
---
# GUI 入口留一个不建窗口的 `--check` 干跑分支，作为无显示器环境下的入口验收

**主张**：交付带 GUI 的入口模块（`app.py` / `main()`）时，让入口支持 `--check`（干跑）分支：只做数据集扫描、参数校验、依赖探测并打印**实测盘点**，**不构造窗口、不进事件循环**。无显示器环境下的入口验收就靠 `--check` + 离屏测试，而不是"起界面看一眼"。

**为什么**：GUI 入口的失败大多发生在窗口出现**之前**（数据目录扫不到、`--file` 指向的文件不存在、配置项缺失），而这些错误在"起界面看一眼"的验收方式下只能靠人肉发现；窗口一旦起来就进事件循环，脚本无法判定成败。干跑分支把入口链路变成一条可脚本化、可看退出码的命令，人不在场也能跑。本会话还顺带用它取到真实盘点（默认数据集 = 7 个采集件 / 700 帧），比文档里的自述数字可信（对照 `doc-selfreported-counts-drift`）。

**证据（本会话命令 ↔ 结果，session:01a0a819）**
- 进程内调用：`time python3 -c "from spc865.ui import app; rc = app.main(['--check']); print('rc =', rc)"` → 打印 `[check] 数据集 /Users/zodyne/Dev/SPC865/20251009_865单板暗箱角反AD数据采集 · 7 个采集件 · 700 帧`，入口函数可进程内调用并返回 rc，便于塞进自动验收。
- 模块入口：`python3 -m spc865.ui.app --check` → 同样打印 `[check] 数据集 … 7 个采集件 · 700 帧`（与上一条一致）。
- 指定数据件分支：先用 `ls` 取真实文件名，再 `python3 -m spc865.ui.app --check --file "MatlabSpc865/20260610/100M/<bin>"` → 走通 `--file` 分支。
- 同一车道的门禁是全离屏的：`QT_QPA_PLATFORM=offscreen python3 -m pytest tests/python/test_ui_smoke.py -q` → `.......  [100%]`（7 条，重复两次一致）。

**边界 / 反例**
- `--check` 只覆盖"入口链路 + 数据/参数校验"，**不证明窗口渲染正确**；渲染层仍需离屏抓图或真机核验（见 `cocoa-platform-verify-gl-render-errors`）。
- 它是补充不是替代：语法门（`py_compile`）、静态检查、离屏 pytest 各覆盖不同层；只跑 `--check` 会重蹈"语法/浅层检查当验收"的坑（见 `untested-tool-config-bugs-stay-invisible`）。
- 本会话切片里 `--check` **全是跑通记录，没有一次抓到失败的实例**——"它能抓 bug"这点本次无证据；把它当门禁的理由是"可自动化 + 不进事件循环 + 打印实测盘点"，不是"它抓到过什么"。
- 退出码必须真的反映校验结果（有坏数据件就非零），否则只是把"看一眼"换成了"跑一下"，门禁依旧形同虚设。
