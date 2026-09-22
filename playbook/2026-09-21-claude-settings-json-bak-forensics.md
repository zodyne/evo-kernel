---
id: claude-settings-json-bak-forensics
type: playbook
status: validated
scope: global
domain: claude-code
tags: [claude-code, settings.json, backup, forensics, config-drift]
triggers:
  - "排查 ~/.claude/settings.json 何时被改成什么（模型被换 / env 被注入 / 配置漂移）"
  - "怀疑某次会话或某个工具改了 Claude Code 全局配置，但只有当前文件、没有改动前基线（失败信号）"
  - "要还原 ~/.claude/settings.json 在某个时间点的内容"
  - "看见 ~/.claude/settings.json.bak.<时间戳> / .bak-<语义名>，不确定是什么、能不能当快照用"
  - "需要按时间顺序梳理同一配置文件的多份备份"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0c1f4-ba46-7370-8301-baf14cc85c89
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [mask-secrets-when-reading-config, claude-json-project-keys-are-paths, claude-file-history-snapshot-diff]
---

# ~/.claude/settings.json.bak.* 是现成的配置基线：逐个列内容 + stat 精确 mtime 即可还原改动序列

**主张**：`~/.claude/` 下留有 `settings.json` 的多份备份，命名同时有时间戳式（`settings.json.bak.20260921105403`）和语义式（`.bak.mixdeepseek`、`.bak-router`）。
排查「settings.json 何时被改成什么」时，先 `stat -f '%Sm %N' -t '%Y-%m-%d %H:%M:%S' ~/.claude/settings.json ~/.claude/settings.json.bak.*` 按 mtime 排序，
再逐个打印备份内容，就能拼出配置在时间轴上的取值（例如某时刻 model 是什么、env 里注入了哪些代理变量），不必凭空回忆。

**为什么**：当前文件只有一个状态；备份文件是不同时间点的完整快照，是配置漂移事故里唯一的旧基线。
mtime 精确到秒可以把「谁在什么时间改的」与其它事件（会话切换、进程重启）对齐。

**证据**（本会话切片，命令 ↔ 结果）：
- `cd ~/.claude; for f in settings.json.bak.20260921105403 settings.json.bak.mixdeepseek settings.json.bak-router; do echo "===== $f ($(stat -f '%Sm' -t ...))"; ...`
  → `===== settings.json.bak.20260921105403 (09-21 10:54) ===== model: sonnet   ALL_PROXY=http://<localhost>:<port>   ANTHROPIC_B...`。
- `stat -f '%Sm  %N' -t '%Y-%m-%d %H:%M:%S' ~/.claude/settings.json ~/.claude/settings.json.bak.*`
  → `2026-09-21 11:09:26 /Users/zodyne/.claude/settings.json`（其余备份时间戳在切片里被截断）。

**边界 / 反例**：
- 切片只完整展示了 1 份备份的内容；备份是谁/何时生成的（工具自动轮转还是人工复制）未验证。
- 备份内容可能含 API key / 代理口令；打印前按 `mask-secrets-when-reading-config` 处理，别把明文写进 transcript。
- 切片 `stat` 输出被截断，未能把所有备份与当前文件的先后顺序排全；mtime 排序本身可信，但「哪份对应哪次事件」仍需其它证据。
