---
id: pi-status-area-widget-multi-source-attribution
type: lesson
status: candidate
scope: global
domain: pi-harness
tags: [pi, tui, widget, extension, attribution, working-line, false-success]
triggers:
  - "pi 编辑器下方某块显示想隐藏，改了一个扩展的开关后它还在（失败信号：界面仍有残留）"
  - "把『UI 没变化』直接当成配置没生效、准备再翻一遍配置文件"
  - "要判定某块 TUI 显示（工作行 / agent 列表 / 标题行）由哪个扩展渲染，手上只有界面上的字形或文案"
  - "同时装了多个改 UI 的 pi 扩展，状态区出现重复或多余的显示块"
  - "子代理相关的几块显示（列表 / 工作行 `✻ <Verb>… (Ns · ↑ N tokens)` / 标题行）分不清各自归属与开关"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a54c-0512-72e6-8ba8-9e7627321f17
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

**主张**：pi 编辑器下方那片「多 agent / 子代理状态」不是单一来源，而是多个扩展各自渲染的 widget 叠在一起；把其中一个扩展的开关关掉后界面仍有残留时，先判残留属于哪一块，**不要**当成「开关没生效 / 配置文件没被读进去」。

**证据（本会话命令 ↔ 结果）**

- 本会话只改了一处配置：写 `~/.pi/agent/subagents.json` = `{"fleetView": false}`（随后 `cat` 回读 + `node -e JSON.parse` 校验 → `JSON ok`），目标是隐藏截图里子代理的派发状态显示。
- 结果没达成，且被判定为「两块互相独立的 widget」：末条 assistant「明白了——那你要的东西**没被关掉**。你截图里其实是两块**互相独立的** widget，我上一轮只关了下面那块」，并把界面逐行标注 —— 转录行 / `✻ Cerebrating… (2842s · ↑ 24k tokens)`（判为 cc-extensions 的 working message）/ `● Age…`。
- 归属用的手法是「界面上的独有字形/文案 → 去候选源码里反查」：`rg -n "∴" src/`（pi-subagents）**0 命中**；`rg -n "⎿|heading|Agents \(" src/ui/agent-widget.ts` → `434: headingColor = hasActive ? "accent" : "dim"`、`435: headingIcon = hasActive ? "●" : "○"`；`rg -n "for agents|to manage|esc to interrupt" src/` → `src/cross-extension-rpc.ts:57`、`src/index.ts:273`（这些是 pi-subagents 自己的块，不是工作行那块）。

**边界（重要）**

- 那次**具体归属在切片里没有命令输出佐证**：把 `✻ …` 工作行归给「cc-extensions」只出现在末条 assistant 的结论里；切片中与 `✻` 相关的检索只在 pi-subagents 里得到 0 命中，扩展/harness 侧的检索输出（`=== cc-extensions ===` 之后）没有留下来。**本条不背书该归属**，只背书「状态区是多来源、要分块定位」这条方法。
- 反向不成立：某个字形在 A 包里 0 命中，只说明 A 不渲染它，不能直接推出 B 就是渲染者；落地归属要在 B 源码里拿到命中，或拿到开关两态的 A/B 对照。
- 本条不断言任何具体扩展的开关名；只改一个扩展的开关不会整体生效，这一点是本会话实测到的返工起点。

**判定等级**：`verified_by: human` —— 「两块互相独立」是会话末的判断（基于读源码），切片里没有一条命令输出直接证明两块分属不同扩展。
