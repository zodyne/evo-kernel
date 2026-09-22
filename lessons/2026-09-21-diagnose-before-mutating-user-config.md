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

## 2026-09-22 独立复核增补

**复核给不出最小复现**（见下）。


**审核给出的修改意见（要点）**：改后留候选（不进注入集）。四点： (1) 证据 #3 改写：`python3 -m json.tool … > /dev/null` 的输出被丢弃，不能当来源；改引实际输出行（并注明该复合命令尾部截断、不能照抄重跑）。同仓同会话的 settings-json-bak-forensics / file-history-snapshot-diff 两条已做过同类「换证据 + 标注截断」修订，照办。 (2) 主张/标题去掉「在用户说先探查之前就改了两个文件」的时序与对象断言，收窄为「本会话改过这两个文件」；把「先探查」明确标为仅 assistant 转述。README 是否算「抢跑」改动切片无据，应从例子里移出。 (3) 删掉「导致后续无法直接判定…」「补救成本…远高于…」两处无据的后果/成本断言，或降级为「一般性推论」。本会话症状（Connection refused，router 侧）与 settings.json 改动不同源，拿这次诊断当「改动污染基线」的实例并不成立——方法论本身可留，但别挂在一次未受影响的诊断上。 (4) 可选：与 playbook 的 stamp-baseline-before-review（同属「先钉基线」族）互加 related。 不建议 promote：主张是一般方法、真值稳定（snapshotRisk=low），但「先取证再动配置」是规范性顺序律，给不

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 「导致后续无法直接判定现象来自原始故障还是这次干预（只能靠 file-history / `.bak.*` 反推现场）」——切片里报的故障是 router 侧「Connection refused」，与 settings.json 加 env 不同源；切片反而显示 agent 用 .bak/file-history 顺利还原出完整时间线，没有任何观察显示诊断被阻断。因果后果属无据推断。
- 「本会话在用户说「先探查」之前就改了两个文件」——「在…之前」只来自末条 assistant 自述；README 的编辑发生在 11:16（会话进行中，见切片第 59-61 行 diff），它早于「先探查」与否在切片里无据。
- 「补救成本（读备份、diff 快照、向用户交代）远高于先做一次只读取证」——成本量级断言，切片无任何代价度量支持。

**判定**：keep-with-fix · 拟 keep-lessons · 原证据快照风险=low · 复核时本机可复跑=false
