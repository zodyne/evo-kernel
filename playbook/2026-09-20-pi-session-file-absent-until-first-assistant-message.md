---
id: pi-session-file-absent-until-first-assistant-message
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, session-manager, getsessionfile, sentinel, registration, telemetry]
triggers:
  - "在 pi 的 session_shutdown / 退出钩子里用 ctx.sessionManager.getSessionFile() 非空来判断『本次会话值得登记』"
  - "登记表/台账里持续出现 transcript 为 '?' 或指向不存在文件的哨兵行（失败信号）"
  - "刚修完 --no-session 自登记污染，就认为哨兵行来源已清零"
  - "会话在首条 assistant 消息前结束（模型报错、用户立刻退出），登记/埋点却断言『没有会话』"
  - "治理指标的分母被不可回溯的 '?' 行抬高，需要区分『文件未落盘』与『文件不存在』"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bc84-d38b-76aa-9257-83bbda1ace9a
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [self-registration-hook-self-pollution-loop, register-at-first-event-not-lifecycle-end]
---

# pi 的 getSessionFile() 在文件落盘前就返回非空路径：`if (!file) return` 挡不住哨兵登记

## 主张

pi 的 `ctx.sessionManager.getSessionFile()` 在会话创建后就返回**路径字符串**，
但 pi 只在**第一条 assistant 消息**落盘时才真正创建该文件
（`SessionManager._persist`：`hasAssistant` 判 false 时只标记未 flush 并 return，
创建文件的 `openSync(sessionFile, "wx")` 在其之后）。
所以 shutdown 钩子里 `if (!file) return` 只能挡 `--no-session`（那种情况下 sessionFile 为空串），
挡不住"发了 prompt、模型在首条 assistant 消息前报错/用户立刻退出"的会话——
扩展照常登记出 `transcript: '?'` 的哨兵行，而对应文件**从头到尾没被创建过**。
判据应换成"文件真实存在"（`fs.existsSync(file)`），并显式区分"未落盘"与"文件不存在"；
测试/smoke 会话则应另行排除。

## 为什么

`--no-session` 与"会话未落盘"是两种不同的空：
前者 `getSessionFile()` 返回 `""`（`SessionManager.inMemory(cwd, "", …)`），
后者返回一个**语法合法、但磁盘上不存在**的路径。
`if (!file) return` 只覆盖前者，于是"修完 `--no-session` 就不会再有哨兵"是个错误的收敛判断——
实测修复后仍残留 47 条 pi 哨兵，且逐条查磁盘 **47/47 无文件**。
这些行会污染 doctor 的 transcript 时效项（420/709 不可用，59%）与队列/节律判据的分母。

## 证据（本会话命令 ↔ 结果）

- 哨兵清单 + 磁盘比对（排除 `zz-*` smoke 夹具后）：
  `排除 zz-*（smoke 夹具）后的 pi 哨兵: 47` / `文件仍在磁盘的: 0  找不到文件的: 47`；
  其中 `出现在 recall.jsonl 的: 2 / 47`（说明扩展确在这些会话里跑过 → 会话真实存在过，只是文件从未落盘）。
- 另一条命令显示 **22/47** 在哨兵时刻 ±2min 内有兄弟会话文件（`goal-smoke`、测试会话等），即测试夹具也进了台账。
- pi 源码（`dist/core/session-manager.js`）：
  `getSessionFile() { return this.sessionFile; }`；
  `_persist(entry)` 内 `if (!this.persist || !this.sessionFile) return;`
  → `const hasAssistant = this.fileEntries.some((e) => e.type === "message" && e.message.role === "assistant");`
  → `if (!hasAssistant) { if (this.flushed) appendFileSync(...); else this.flushed = false; return; }`
  → 其后的 `openSync(this.sessionFile, "wx")` 才创建文件。
- `SessionManager.inMemory(cwd = process.cwd(), options, entries)` → `new SessionManager(cwd, "", …)`，即 `--no-session` 只是 `sessionFile === ""` 这一种情形。
- 扩展侧判据：`const file = ctx.sessionManager.getSessionFile(); … if (!file) return;`，注释把它当作 `--no-session` 哨兵的完整防护。
- 后果实测：`evo doctor` 第 15 项 `[WARN] transcript 时效  420/709 不可用（哨兵或文件已不在）(59%)`。

## 边界 / 反例

- 未做"发一条 prompt 后立刻退出"的端到端复现；机制是"读 `_persist` 源码 + 47/47 无文件"推出的。
- 47 条里可能混有其它来源（例如测试脚本直接调 `hook-session-end` 造桩），未逐条归因；±2min 兄弟文件只覆盖了 22 条。
- 只统计 pi 侧（claude/hermes 的 transcript 由各自 harness 管理，`getSessionFile` 语义不同）。
- "该用 existsSync 判"只是判据修正方向；`existsSync` 仍有 TOCTOU 与"登记时刻文件刚被删"的窗口，不是绝对可靠。
