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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
命令（2026-09-22 15:16 CST 本机实跑）：\nstat -f '%Sm  %N' -t '%Y-%m-%d %H:%M:%S' ~/.claude/settings.json ~/.claude/settings.json.bak* 2>/dev/null\n期望输出（7 份备份 + 当前文件，mtime 升序可见）：\n2026-07-05 15:10:56  /Users/zodyne/.claude/settings.json.bak.20260705151056\n2026-08-12 09:31:40  /Users/zodyne/.claude/settings.json.bak.20260812093140\n2026-08-13 08:50:33  /Users/zodyne/.claude/settings.json.bak-20260813-085033\n2026-09-21 10:10:40  /Users/zodyne/.claude/settings.json.bak.mixdeepseek\n2026-09-21 10:54:03  /Users/zodyne/.claude/settings.json.bak.20260921105403\n2026-09-22 10:33:23  /Users/zodyne/.claude/settings.json.bak-20260922-103323-preclaudehooks\n2026-09-22 10:34:17  /Users/zodyne/.claude/settings.json\n（注：连字符形态 .bak-router / .bak-2026... 只有用 `.bak*` 通配才被纳入；`.bak.*` 会漏掉 3 份。内容取证：cd ~/.claude && for f in settings.json.bak*; do python3 -c \"import json,sys;print(sys.argv[1], json.load(open(sys.argv[1])).get('model'))\" \"$f\"; done → .bak-router=opus / .bak.mixdeepseek=sonnet / .bak.20260921105403=sonnet）
```

**审核给出的修改意见（要点）**：改后留，四处：(1) 【功能缺陷】把主张里推荐的 `~/.claude/settings.json.bak.*` 换成 `~/.claude/settings.json.bak*`（去点）——本机实测 `.bak.*` 静默漏掉连字符命名备份（`.bak-router`、`.bak-20260813-085033`、`.bak-20260922-103323-preclaudehooks`，7 份漏 3 份，含最新一份及 entry 自己点名的 `.bak-router`）；照原命令跑会得到不完整时间线。(2) 【换证据】证据第 1 条依赖切片里被截断的 for 循环（`-t ...` 与循环体缺失），不能照抄重跑；替换为可直接复跑的 `for f in ~/.claude/settings.json.bak*; do stat -f '%Sm %N' -t '%Y-%m-%d %H:%M:%S' "$f"; done` + 逐份打印 model/env，并用 minimalRepro 里 2026-09-22 的实跑输出作新证据。(3) 【收窄】「谁在什么时间改的」→「什么时候改的」：mtime 只给时间不给施动者；who 需配 `claude-file-history-snapshot-diff` / session jsonl 才能定。(4) 【收窄】删「唯一」：「旧基线」不

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- mtime 精确到秒可以把「谁在什么时间改的」与其它事件（会话切换、进程重启）对齐。
- 备份文件是不同时间点的完整快照，是配置漂移事故里唯一的旧基线。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
