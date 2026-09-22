---
id: major-change-research-must-check-unmerged-branches
type: playbook
status: validated
scope: global
domain: research-methodology
tags: [research, upstream, branches, release-notes, emacs, igc]
triggers:
  - "被问『某项目/软件最近有没有重大或革命性变化』，手上只有发布版 NEWS、发布公告或新闻稿"
  - "发布版 NEWS/公告里 grep 不到某特性，准备下结论『没有变化』（失败信号）"
  - "怀疑某项能力仍在上游 feature 分支开发、尚未进任何发布版，要核实其存在与活跃度"
  - "结论需要区分『已发布的能力』与『已开发未发布的方向』"
  - "调研对象存在长期 feature 分支（如 Emacs 的 feature/igc3）"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bf4c-dbdb-75a1-a035-327aea85cb14
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [gitea-selfhosted-forge-release-api, milestone-status-claims-conflict-in-repo, github-wrong-owner-path-silent-not-found]
---

# 判断「最近有没有重大变化」不能只看发布版 NEWS：同时枚举远端分支并读分支内材料

**主张**：发布版 `etc/NEWS` 只覆盖已发布内容；回答「某项目最近有没有重大/革命性变化」时，
必须同时枚举远端分支（`git ls-remote --heads <upstream> | grep -i <关键词>`，或 forge 的分支 API）
并读取分支内的 NEWS/提交，才能把「已在开发但未发布」与「确实没有」分开。
本会话正是靠分支查询发现 Emacs 的 **feature/igc3** 分支仍在活跃提交，
从而把「已发布版 31.1 的渐进更新」与「未发布的原生 GC 方向」分开写结论。

**为什么**：上游的重大方向常长期停在 feature 分支上（不 rebase 到 master、不进 release notes），
只看发布材料会系统性低估变化；分支名单能给出方向，分支内的 NEWS 与提交时间能给出「是否仍在推进」。

**证据**（本会话切片，命令 ↔ 结果）：
- `git ls-remote --heads https://git.savannah.gnu.org/git/emacs.git | grep -i 'igc|mps'`
  → `=== canonical branches with igc/mps === 07b35c82b7dfc9d0c044dc54dcc65675f49de87e refs/heads/feature/igc3 ...`。
- GitHub API 查含 igc 的分支 → `feature/igc3`；`recent commits mentioning igc (search API) === total: 4 2026-05...`。
- `feature/igc3` 最新提交（GitHub API）→ `2026-08-06T11:57:52Z Move 'read_commit_limit' to sysdep.c`、`2026-08-05T07:54:39Z On Li...`（分支仍在 2026-08 活跃）。
- 分支内 NEWS（经 `cdn.jsdelivr.net/gh/emacs-mirror/emacs@feature/igc3/etc/NEWS` 取得）→ 有可读内容（`** The transition variable 'current-time-l...`），说明分支自带 NEWS 增量。
- 对照：同时拉了发布版 `emacs-31.1` 与 `master` 的 NEWS（`4274 NEWS31.txt`、`600 NEWSmaster.txt`）做关键词扫描。

**边界 / 反例**：
- 分支存在且活跃 ≠ 该特性会进下一个发布版；本会话没有核实 IGC 的合并时间表，只证明它当时不在已发布面内。
- `git ls-remote --heads` 依赖镜像/上游当时可访问；GitHub API 的分支搜索可能只给出部分结果，两者交叉更稳。
- 判断「已发布版没有某特性」仍需在对应 tag 的 NEWS/代码里验证，不能只凭分支存在反推。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含最小复现（本机 2026-09-22 实跑通过；需网络）：

# 1) 远端确有分支，发布材料里却找不到它
curl -sS "https://api.github.com/repos/emacs-mirror/emacs/branches?per_page=100" | grep -o '"name": "[^"]*igc[^"]*"'
#   -> "name": "feature/igc3"
git ls-remote --heads https://github.com/emacs-mirror/emacs.git | grep -iE 'igc|mps'
#   -> f5209268c0b1f46aeda55fa8b64e954ff29584b8	refs/heads/feature/igc3
#   -> 49f279dada262aa4b28b151b9650a38479ff4e40	refs/heads/scratch/igc/weak-undo-list

# 2) 已发布版与 master 的 NEWS 全都不提它（0 命中）
curl -sSL https://raw.githubusercontent.com/emacs-mirror/emacs/emacs-31.1/etc/NEWS | grep -ic igc   # -> 0  (wc -l = 4274)
curl -sSL https://raw.githubusercontent.com/emacs-mirror/emacs/master/etc/NEWS   | grep -ic igc   # -> 0  (wc -l = 600)

# 3) 分支仍在推进（快照，随时变）
curl -sS "https://api.github.com/repos/emacs-mirror/emacs/commits?sha=feature/igc3&per_page=1" | grep -o '"date": "[^"]*"' | head -1
#   -> "date": "2026-09-21T13:14:09Z"

注：git ls-remote 在本机沙箱内需放开网络；条目所写的 git.savannah.gnu.org 地址本机 git 协议下超时不可达，emacs-mirror 的 GitHub 镜像可用。另：`git ls-remote … | grep -i 'igc|mps'`（条目原文，BRE）输出为空，`grep -iE 'igc|mps'` 才行。
```

**审核给出的修改意见（要点）**：核心主张（答「最近有没有重大变化」不能只看发布版 NEWS，须同时枚举远端分支并读分支内材料）成立且是稳定方法学，留在 playbook；但三处要改：  1) 证据第 1 条：把 `grep -i 'igc|mps'` 改成 `grep -iE 'igc|mps'`——前者是 BRE，`|` 为字面量，实测输出为空，照抄跑不出结果。同时说明 savannah 的 git ls-remote 在本机不可达、可换 `https://github.com/emacs-mirror/emacs.git` 镜像；分支头 hash（原文 07b35c82…）是快照，现已推进为 f5209268…，建议不再写死 hash。  2) 证据第 4 条：删去「说明分支自带 NEWS 增量」或收窄为「会话当时分支 etc/NEWS 与 master 不同（该行位于分支第 239 行、master 第 456 行），现分支已合并 master、两者同 blob（f86deace…, 22765 B）」。理由：切片只证「有可读内容」，未做 master 对比；该断言现在为假，属快照。  3) 「为什么」段的两句一般化——「上游的重大方向常长期停在 feature 分支上（不 rebase 到 master、不进 release notes）」——是单一案例（Emacs igc3）升格，切片里没有该分析；建议

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 说明分支自带 NEWS 增量（切片仅证「有可读内容」，未与 master 对比；且现在分支 etc/NEWS 与 master 同 blob sha f86deace…，该断言当前为假）
- 上游的重大方向常长期停在 feature 分支上（不 rebase 到 master、不进 release notes）（单一案例 Emacs feature/igc3 升格成一般律，且不出现在切片里）

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=high · 复核时本机可复跑=true
