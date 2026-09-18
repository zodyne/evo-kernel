---
id: pi-subagents-fleetview-toggle-in-subagents-json
type: lesson
status: candidate
scope: global
domain: pi-harness
tags: [pi, pi-subagents, fleetview, config-location, editor-widget, ui]
triggers:
  - "想隐藏/关掉 pi 编辑器下方那一列主会话 + 各子代理的状态列表（pi-subagents / FleetView）"
  - "在 ~/.pi/agent/extensions/ 或 ~/.pi/agent/settings.json 里翻 pi-subagents 的开关，翻不到"
  - "改了配置但编辑器下方的 agent 列表没有变化，拿不准设置文件到底是哪一份（失败信号）"
  - "要改 pi-subagents 的全局默认（fleetView / defaultMaxTurns / graceTurns 这类字段）"
  - "怀疑 ~/.pi/agent/subagents.json 有没有被真的读进去（失败信号：文件不存在时静默走默认值、不报错）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a54c-0512-72e6-8ba8-9e7627321f17
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

**主张**：pi-subagents（`@tintinweb/pi-subagents`）的操作设置落在全局 `~/.pi/agent/subagents.json` —— 既不在 `~/.pi/agent/extensions/` 的扩展目录里，也不是 `~/.pi/agent/settings.json`；「编辑器下方那条 main + 每个 running subagent 的可导航列表」这块 UI 的开关就是该文件里的 `fleetView` 布尔字段（本会话写入的就是 `{ "fleetView": false }`）。

**为什么（本会话命令 ↔ 结果）**

- 源码自述落点：读 `src/settings.ts` 头部 → `// Persistence for pi-subagents operational settings. // - Global:  ~/.pi/agent/subagents.json (via getAgentDir())`；同文件后续段落逐个校验并解析 `defaultMaxTurns`（number）、`graceTurns`（integer），说明这份 json 是这批字段的共同落点。
- 本会话唯一写过的文件就是它（切片「写/改文件」只有 `/Users/zodyne/.pi/agent/subagents.json`）：`cat ~/.pi/agent/subagents.json` → `{ "fleetView": false }`，并用 `node -e "…JSON.parse…"` 校验 → `JSON ok: {"fleetView":false}`（写入后可解析、没写坏）。
- 这个字段管的是哪块 UI：`rg -n "Fleet|fleetView" README.md` → 第 18 行 `**FleetView** — Claude Code-style navigable list of main + every running subagent rendered below the editor`。
- 项目级那份本机不存在：`ls -la /Users/zodyne/.pi/subagents.json` → `(无项目级 subagents.json)`，`Command exited with code 1`（未创建，本轮没有用到）。

**反例 / 边界**

- 关掉 `fleetView` 只影响 pi-subagents 自己渲染的那一块：本会话改完后，用户要隐藏的状态显示**并没有全部消失**（末条 assistant：「明白了——那你要的东西**没被关掉**。你截图里其实是两块**互相独立的** widget，我上一轮只关了下面那块」）。别把 `fleetView: false` 当成「隐藏所有子代理相关显示」的总开关。
- 本条只锚定「设置文件路径 + `fleetView` 字段名 + 生效对象是编辑器下方那块列表」；**未验证**写入后是否需要重启 pi 才生效（切片里没有写入前后重开的对照）。
- 版本锚：本次读的是 pi-subagents `0.19.0`（`cat package.json` → `"version": "0.19.0"`）；升版后字段名与文件位置可能变，复用时按当前版本重跑 `rg` 核对。
- 文件不存在时不报错、静默走默认值（本会话开始时该文件 `ls` 直接失败），所以「没报错」不能当作「配置已生效」的证据。
