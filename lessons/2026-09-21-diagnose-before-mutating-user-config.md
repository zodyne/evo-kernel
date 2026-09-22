---
id: diagnose-before-mutating-user-config
type: lesson
status: candidate
scope: global
domain: agent-ops
tags: [troubleshooting, config, evidence, process, baseline]
triggers:
  - "用户报告配置/连接故障，要在动手前决定先取证还是先修"
  - "已经先改了用户全局配置文件，之后才被要求『先探查』（失败信号：现场基线被自己的改动覆盖）"
  - "排查 ~/.claude、~/.pi 这类全局配置问题时会顺手加环境变量 / 改默认值"
  - "事故报告需要归因，但无法区分现象来自原始故障还是自己刚做的改动"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0c1f4-ba46-7370-8301-baf14cc85c89
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [stamp-baseline-before-review, claude-settings-json-bak-forensics, claude-file-history-snapshot-diff]
---

# 用户报故障时先固化现场再改配置；抢跑改动会让原始故障与自己的改动无法区分

**主张**：用户报告配置/连接故障时，顺序必须是：先读现场（当前配置、备份、mtime、文件历史）并保留基线，再动手改配置。
本会话在用户说「先探查」之前就改了两个文件（`~/.claude/settings.json`，在其中加了 `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`），
导致后续无法直接判定现象来自原始故障还是这次干预，只能靠 file-history / `.bak.*` 反推现场，并在报告里先自曝改动。

**为什么**：配置事故的因果证据就是「改动前的文件状态」。一旦先改，同一份文件既是故障对象又是处置手段，
之后任何观察都没有干净基线；补救成本（读备份、diff 快照、向用户交代）远高于先做一次只读取证。
取证动作本身很轻：`stat` 取 mtime、打印备份、读 file-history 快照即可。

**证据**（本会话切片）：
- 「写/改文件」清单：`/Users/zodyne/.claude/settings.json`、`/Users/zodyne/.claude/claude-router/README.md`。
- 末条 assistant：「探查完成。以下是完整现场 —— 包括我**已经做过的改动**（在你说"先探查"之前做的，先如实交代）」。
- `python3 -m json.tool ~/.claude/settings.json` 状态输出里可见 `13: "CLAUDE_CODE_SUBAGENT_MODEL_FORCE": "1",`，文件 mtime `11:18:39`（改动确实已落盘）。

**边界 / 反例**：
- 「先探查」指令本身在切片里只由末条 assistant 转述，未直接看到用户原话；证据链依赖该转述。
- 若用户明确要求「边查边修」或故障正在造成损失，抢修优先级可以高于固化现场，但应把改动单独记录、可回滚。
