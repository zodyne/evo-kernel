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
这些行会污染 doctor 的 transcript 时效项（420/709 不可用，59%）与 reflect「蒸馏节律」行的分母。**注意不含队列**——`evo queue` 明确 `if (!j.transcript || j.transcript === '?') continue;`，哨兵行根本进不了队列（2026-09-22 独立复核按代码纠正了本条原来的「与队列/节律判据的分母」）。

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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
本机实测通过（本机 pi 0.86.1，与切片时 0.85.1 源码同构）。写 /tmp 下任一 .mjs：

ʼʼʼjs
import { SessionManager } from "/opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent/dist/core/session-manager.js";
import fs from "node:fs";
const dir = "/tmp/pi-sess-repro"; fs.rmSync(dir,{recursive:true,force:true}); fs.mkdirSync(dir,{recursive:true});
const sm = SessionManager.create("/tmp", dir);
console.log("1) getSessionFile ->", JSON.stringify(sm.getSessionFile()), "exists ->", fs.existsSync(sm.getSessionFile()));
const t = new Date().toISOString();
sm._appendEntry({type:"message",id:"u1",parentId:null,timestamp:t,message:{role:"user",content:"hi"}});
console.log("2) after user msg: exists ->", fs.existsSync(sm.getSessionFile()));
sm._appendEntry({type:"message",id:"a1",parentId:"u1",timestamp:t,message:{role:"assistant",content:"yo"}});
console.log("3) after assistant msg: exists ->", fs.existsSync(sm.getSessionFile()));
ʼʼʼ

实测输出（证明「路径已给、文件未落盘」）：
1) getSessionFile -> "/private/tmp/.../pi-repro-sessions/2026-09-22T07-16-40-972Z_01a0c7f9-538b-73f9-b35f-0db88396be07.jsonl"   exists -> false
2) after user msg: exists -> false
3) after assistant msg: exists -> true

辅证（同口径、但依赖仓库当时状态，非自包含）：把 session-refs.jsonl 里 harness=pi、transcript 为空或 '?'、排除 zz-* 的行，去 ~/.pi/agent/sessions 树按 <session>.jsonl 找 → 今日 67/67 无文件；出现在 recall.jsonl 的 2 条。
```

**审核给出的修改意见（要点）**：核心主张成立且我已在本机独立复现（自带最小复现，见 minimalRepro），故留注入集；但注入前要改三处：  (1) 换证据。证据节里 4 条引用（getSessionFile/_persist 源码、inMemory、扩展侧 `if (!file) return`、doctor 420/709）在切片里都找不到 —— 对它们的命令要么被切片截断（源码那条断在半截），要么根本没跑过（扩展源码、doctor 第 15 项被 head -60 截掉）。把这几条换成「可自包含重跑」的证据：即 minimalRepro 的 SessionManager 复现 + 三行源码定位（session-manager.js:736-738 / 740-756 / 1274）。注意：这不是说主张是假的 —— 上述引用我今日 live 逐条核对全部一致，只是「证据记录」不可复跑。  (2) 收窄一般律。删掉「与队列/节律判据的分母」里的**队列**：bin/evo:918 的 queue 明确 `if (!j.transcript || j.transcript === '?') continue;`，doctor 的待蒸馏计数(:1272) 同样跳过 '?' —— 哨兵行根本进不了队列，说它污染队列分母与代码相反。真正被污染的只有两处：doctor 第 15 项与 reflect 的「蒸馏节律」行

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 这些行会污染 doctor 的 transcript 时效项（420/709 不可用，59%）与队列/节律判据的分母。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
