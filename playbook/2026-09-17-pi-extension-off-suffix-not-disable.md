---
id: pi-extension-off-suffix-not-disable
type: lesson
status: validated
scope: global
domain: agent-harness
tags: [pi, extension, disable, off-suffix, stale-ctx, extensions-disabled]
triggers:
  - "给 pi 扩展目录加 .off 后缀想禁用它，但它仍在加载/抛错"
  - "pi 会话报 Extension error ... ctx is stale after session，想定位是哪个扩展"
  - "禁用 pi 扩展后它还在执行 index.ts 并抛错（失败信号）"
  - "想彻底停用一个 pi 扩展，怎么移出 extensions 目录"
  - "~/.pi/agent/extensions/ 下多个 *.off 目录是否真的没被加载"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0adec-afab-764c-a77e-517351584594
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [pi-extension-command-print-json-mode-unavailable, pi-rpc-mode-headless-drive-extension-command]
---
# pi 会加载 `~/.pi/agent/extensions/` 下的所有子目录，`.off` 后缀不是禁开关——移出该目录树才真禁用

## 主张
`~/.pi/agent/extensions/` 下的每个子目录都会被 pi 当作扩展加载，目录名带 `.off` 后缀**并不能阻止
加载**：本会话里 `claude-look.off` 的 `index.ts` 仍在 smoke 时执行并抛
`Extension error (.../claude-look.off/index.ts): This extension ctx is stale after session`。
真正禁用须把目录移出 `extensions/`（如挪到平级 `extensions-disabled/`），移出后复测即 `NO EXTENSION ERRORS`。

## 为什么
「改个名加 .off 就停用」是顺手但无效的做法——pi 的扩展发现逻辑按目录扫描、不认后缀，`.off` 只是
人眼看得懂的标记，对加载器无意义。于是「已禁用的扩展」仍在后台抛 stale ctx 错，污染 smoke 输出、
误导排查方向。正确动作是物理移出 extensions 目录树，一步到位。

## 证据（本会话命令对照）
- smoke 时报错：`Extension error (/Users/zodyne/.pi/agent/extensions/claude-look.off/index.ts): This extension ctx is stale after session`
- 隔离复现：在 `/tmp/exttest/.pi/extensions/foo.off/` 放一个注册 command 的测试扩展，pi 的 commands 列表仍出现 `footest-off-dir`——`.off` 目录照样被扫描加载并注册。
- 处置：`mv ~/.pi/agent/extensions/claude-look.off ~/.pi/agent/extensions-disabled/claude-look.off` → `moved`
- 移出后复测：`pi --mode rpc ... → NO EXTENSION ERRORS`（对照移出前持续报 stale ctx 错）。

## 边界 / 反例
- 覆盖本机 pi 0.85.1 的扩展发现行为；若未来 pi 官方引入 `.off` 后缀禁用语义，本条失效。
- `custom-header.ts.off` 是单文件加 `.off`，不是目录——两者机制不同，本条专指「子目录加 .off」仍被加载。
- 移出到 `extensions-disabled/` 只是「物理上不在扫描路径内」，不能证明 pi 有官方的 disable 语义；结论是行为级实测，非官方机制背书。

## 失败信号（未来命中即该想起本条）
- pi 会话报 `Extension error ... ctx is stale after session`，且 extensions/ 下还有 `*.off` 目录。
- 给扩展目录加 .off 想停用，但它仍抛错/仍在生效。
- 想干净停用一个 pi 扩展，在「改名」和「移出目录」之间犹豫。
