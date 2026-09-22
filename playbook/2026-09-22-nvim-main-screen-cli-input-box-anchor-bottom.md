---
id: nvim-main-screen-cli-input-box-anchor-bottom
type: playbook
status: validated
scope: global
domain: nvim-tooling
tags: [nvim, terminal, cud, sidekick, claude-code, tui]
triggers:
  - "nvim 主屏模式下跑 CLI agent，输入框停在屏幕中间而不是底部"
  - "想让终端里的 CLI 从最后一行开始画，避免 UI 悬在半空"
  - "sidekick 的 cmd 包装该怎么写才能让 claude 的 UI 锚底"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:inbox/capture-2026-09-18-09-48-43-536-c65x
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [nvim-terminal-alt-screen-kills-scrollback]
---

# nvim 主屏模式下让 CLI 输入框锚底：包一层 `printf "\033[999B"` 再 exec

**主张**：CLI 从**当前光标行**开始画，主屏模式下光标若停在中间，UI 就悬在中间。
在 `sidekick` 的 cmd 外再包一层 `sh -c 'printf "\033[999B"; exec claude'`（CUD 把光标压到屏底，
首帧触发滚动）即可让 UI 贴底 —— 实测 29 行窗口里 UI 落在 20..28 行。

## 为什么

没有清屏的程序（主屏模式）以光标当前位置为原点；把光标先推到屏底，原点自然到底。
这是「不修改被测程序」的纯包装解法。

## 证据（本会话实测）

- 包装后 29 行窗口：UI 落在第 20..28 行。
- 对照：pi 的 `regular` 模式**不行** —— 它首帧硬发 `\e[2J\e[H\e[3J`（`pi-tui` 的
  `tui-main-screen.js` `fullRender`），且无开关，只能等输出填满屏。

## 边界 / 反例

- 对「首帧自己清屏」的程序无效（pi regular 即反例）——那不是光标定位问题。
- `999B` 依赖终端支持 CUD 且不 clamp 到窗口外；绝大多数终端把超界 CUD 夹到底行，但未逐一验证。
