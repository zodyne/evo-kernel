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
verified_by: human
source: capture:inbox/capture-2026-09-18-09-48-43-536-c65x
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [nvim-terminal-alt-screen-kills-scrollback]
---

# nvim 主屏模式下让 CLI 输入框锚底：包一层 `printf "\033[999B"` 再 exec

**主张**：本次实测对象是 **Claude Code**，它从当前光标行开始画；主屏模式下光标停在中间，UI 就悬在中间。
在 `sidekick` 的 cmd 外再包一层 `sh -c 'printf "\033[999B"; exec claude'`（CUD 把光标压到屏底）
即可让 UI 贴底 —— 实测 29 行窗口里 UI 落在 **20..28** 行。

## 证据

- 包装后 29 行窗口：UI 落在第 20..28 行。
- 对照（同一次记录）：pi 的 `regular` 模式**不行** —— 它首帧硬发 `\e[2J\e[H\e[3J`
  （`pi-tui` 的 `tui-main-screen.js` `fullRender`），且无开关，只能等输出填满屏。

证据等级：`verified_by: human` —— 来源是会话内的 prose 摘要（`capture:…`），无命令转录。
在 nvim 里开一个主屏 `:terminal` 跑同一条包装即可复现，跑通后可升回 `command`。

## 边界 / 反例

- 「从当前光标行开始画」只对**本次实测的程序（Claude Code）**观测到；不要泛化成「所有 CLI 都如此」。
- 已知的反例只有一个：**pi 的 `regular` 模式**（理由见上：首帧自己清屏）。
  「凡首帧自己清屏的程序都无效」是**由这个反例引出的猜测**，本次没有测第二个此类程序。
- 包装本身有两个未验证的前提：终端支持 CUD，且超界的 `999B` 不会被 clamp。本次没有就这两点取证——
  换终端要重新确认一次。
- 本条只给「怎么让它贴底」；**为什么**贴底有效（光标原点机制）capture 未记录，本条不解释。
