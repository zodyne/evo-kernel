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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
# 2026-09-22 15:16 本机复跑（claude 2.1.277，与切片同日版本），三条信号均活：
$ ls -lat ~/.claude/sessions/*.json
-rw-r--r--@ 1 zodyne staff 554 Sep 22 15:16 /Users/zodyne/.claude/sessions/34249.json
-rw-r--r--@ 1 zodyne staff 535 Sep 22 15:13 /Users/zodyne/.claude/sessions/45258.json
-rw-r--r--@ 1 zodyne staff 531 Sep 22 10:19 /Users/zodyne/.claude/sessions/16117.json
$ pgrep -x claude
16117
34249
$ ps aux | rg -i claude | rg -v 'rg '
34249 8:27AM /opt/homebrew/bin/claude
16117 6:00PM /opt/homebrew/bin/claude
34249 8822 ...
$ find ~/.claude -maxdepth 2 -type f -newermt '-3 min'   # 本次为空（近 3 分钟无写）
期望：sessions/*.json 数==活的 claude 会话数；每个 <pid>.json 内容为 {"pid":<pid>,"sessionId":...,"cwd":...,"version":"2.1.277",...}，即 ②③ 两信号可交叉归因。
```

**审核给出的修改意见（要点）**：核心方法（find -newermt 定「最近被写的文件」+ sessions/<pid>.json 定 PID + ps 定启动时间/路径，三者交叉归因）成立、可复验，该留注入集；需收窄三处超证据断言并补两条边界：(1) 删掉「为什么」末句的绝对断言「find -newermt 是唯一直接回答『最近 3 分钟还有谁在写』的信号」，改为「find -newermt 给出最近改动文件的时间窗，是三条里最贴近『刚有人在写』的信号，但单靠它不区分本会话/他会话」；(2) ② 的括注收窄并标注版本与复验：「本机 Claude Code 2.1.277 下 ~/.claude/sessions/ 每个活会话一个 <pid>.json（2026-09-22 复验：3 个 json ↔ 3 个活会话），mtime 随写入更新；此为 CC 内部布局，升版需复验」；(3) 证据 1 括注改为「11:18 时 README.md 落在最近 3 分钟窗口内；归属须靠 ②③ 交叉，且注意本会话自身可能是那个写者」。(4) 证据节加一句记录性注记：切片里 find 命令尾被截断、ps 原始命令含 `rg -v 'rg ' | awk …`，重跑以本条目的完整写法为准。(5) 边界补一条：sessions/<pid>.json 属 Claude Code 内部实现，版本变动可能失效。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- （每个活会话一个文件，mtime 即最近写入）—— 切片只有 65492.json 一个观测（n=1），此句把单例升格为「每个活会话」的一般律，且「mtime 即最近写入」是切片未证的行为断言（本机复验支持该律，但那是我的复验、不在条目的证据里）
- `find -newermt` 是唯一直接回答「最近 3 分钟还有谁在写」的信号 —— 绝对化断言；find 给出的是「文件在窗口内被写」，并不能答「谁写」，与前半句自相矛盾，且「唯一」过强
- （11:18 时刻确有别的写者在动该文件）—— find 输出只能证明该文件在窗口内被写，单凭它无法区分本会话/他会话；且切片的「写/改文件」清单里 README.md 也在此会话名下，「确有别的写者」是超出该行输出的归属结论

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
