---
id: claude-live-session-detection
type: playbook
status: validated
scope: global
domain: claude-code
tags: [claude-code, concurrency, session, forensics, ps, find]
triggers:
  - "~/.claude 下配置/文件被并发改写，要判断是不是另一个 Claude Code 会话在动它"
  - "同一台机器开着多个 claude 会话，出现互相覆盖 / 配置漂移（失败信号：自己没改，文件却变了）"
  - "要根据 PID 找到对应的 Claude Code 会话及其最近活动"
  - "怀疑还有别的会话在跑或在写文件，需要活的证据而不是猜测"
  - "排查完发现改动没有一个明确的归属会话，想补齐并发会话清单"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0c1f4-ba46-7370-8301-baf14cc85c89
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [forensic-grep-self-hit-current-session, claude-file-history-snapshot-diff, parallel-lane-boundary-proof-by-mtime]
---

# 判断是否另有一个 Claude Code 会话在写 ~/.claude：find -newermt + sessions/<pid>.json + ps 三信号交叉

**主张**：怀疑 `~/.claude` 的配置/文件被并发会话改写时，用三条互补信号定位活着的会话，而不是猜：
① `find ~/.claude -maxdepth 2 -type f -newermt '-3 min'` 列出最近被写的文件；
② `ls -lat ~/.claude/sessions/` 看 `<pid>.json` 状态文件的 mtime（每个活会话一个文件，mtime 即最近写入）；
③ `ps aux | rg -i claude` / `ps -p <pid> -o pid,ppid,lstart,args` 拿进程、启动时间与对应路径。
三者交叉可把一次文件改动归因到具体会话/进程，也能区分「本会话改的」与「别的会话改的」。

**为什么**：文件 mtime 只说明「变了」，不说明是谁；会话状态文件给 PID，进程表给启动时间与路径，
三者拼起来才是可复核的归因链。`find -newermt` 是唯一直接回答「最近 3 分钟还有谁在写」的信号。

**证据**（本会话切片，命令 ↔ 结果）：
- `find ~/.claude -maxdepth 2 -type f -newermt '-3 min'`（命令注释：判断另一会话是否在活动）
  → `/Users/zodyne/.claude/claude-router/README.md`（11:18 时刻确有别的写者在动该文件）。
- `ls -lat ~/.claude/sessions/ | head -6` → `-rw-r--r--@ 1 zodyne staff 592 Sep 21 11:17 65492.json`。
- `ps aux | rg -i 'claude'` → `88022 11:15AM /opt/homebrew/bin/node /Users/zodyne/.claude/claude-router/router.mjs`、`68505 10:29A...`；
  `ps -p 65029,65492,68505 -o pid,ppid,lstart,args` 给出各进程启动时间。

**边界 / 反例**：
- `find -newermt` 只看 mtime，会把「读文件导致 atime 变化」排除在外，但也会漏掉只读不写的会话。
- 本会话只观察到三信号各 1 次，未覆盖会话退出后 `sessions/<pid>.json` 的清理行为。
- 搜索会话目录时注意 `forensic-grep-self-hit-current-session`：当前正在写入的会话本身会造成自命中。
