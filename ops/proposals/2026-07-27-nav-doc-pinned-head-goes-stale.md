---
id: nav-doc-pinned-head-goes-stale
type: lesson
status: candidate
scope: global
domain: session-handoff
tags: [compass, context-doc, git, head, handoff, navigation]
triggers:
  - "续接/接手任务时翻 COMPASS.md / CONTEXT.md 的「当前状态/HEAD」章节"
  - "里程碑提交后又跟了清理类提交（删冗余分支、作废 golden 数据、rebase、整理提交）"
  - "导航文档里写的 HEAD 与 `git rev-parse HEAD` 对不上"
  - "维护手写的「当前状态 → HEAD X」指针"
  - "下一次会话照旧 HEAD 找代码却对不上 checkout 出来的树"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:95d881b1-df57-45b6-95d2-8fadcef18b18
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
手写的导航/状态文档（COMPASS.md、CONTEXT.md 等）里**硬钉的「当前状态 → HEAD <sha>」指针会被里程碑之后的清理类提交悄悄推前**：里程碑提交（如 ADR 落地）本身往往有人记得去同步文档，但紧跟其后的「删冗余分支 / 作废 golden 数据 / 收敛主线」这类整理提交没人回头更新文档，指针就此漂移。下次会话照旧 sha 导航时要么找不到、要么指向已被改写的树。

**做法**：续接会话第一步先用 `git rev-parse --short HEAD` 取真实 HEAD，再 grep 文档里钉的 sha 做对账；不一致就以一个独立的 `docs(nav):` 提交把文档 sha 同步到当前 HEAD（commit message 写清漂移成因，便于审计）。做清理类提交时，把「是否需要同步状态文档」列入该提交的 checklist。

**证据**：algommw 续接会话中 `git rev-parse --short HEAD` → `43fde1a`，而 `COMPASS.md`「当前状态」仍写旧 `6496061`（ADR 0003 提交后又跟了「清理冗余 main 分支 + 删除 golden 数据」的 `43fde1a`，文档未跟上）；随即以提交 `9d063bd`（`docs(COMPASS): 同步当前状态 HEAD 至 43fde1a`，1 file changed）修复，commit message 自述「ADR 0003 已提交并后续清理冗余 main 分支 + 删除 golden 数据，原『当前状态』仍写旧 HEAD 6496061」。

**边界**：本条针对**手写、长寿命、续接时被当导航源**的 sha 指针；临时笔记或会被 CI 自动生成/覆盖的状态块不在此列。根治方案是状态文档不硬钉 sha（改引里程碑标签/分支名），但在仍钉 sha 的项目里，对账是不可省的续接步骤。
