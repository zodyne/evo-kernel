---
id: hermes-session-project-attribution-via-turn-context-file-refs
type: lesson
status: candidate
scope: global
domain: hermes
tags: [hermes, logs, debugging, session, project, cwd]
triggers:
  - "想知道某个 hermes agent_session_id 是在哪个项目/cwd 下跑的"
  - "hermes agent.log / errors.log 里只有 session id，看不出对应哪个仓库"
  - "projects.db / spawn-trees 里查不到某 session 的 cwd 映射"
  - "要核实一次 hermes 故障/恢复到底发生在哪个项目会话里"
created: 2026-09-02
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:69873e4a-d307-4ff5-b06a-b44acb4ccd1c
last_verified: 2026-09-02
superseded_by: null
schema_version: 1
related: []
---
Hermes 的 `agent.log`/`errors.log`/`sessions/*.json` 都不直接记录 session 的 cwd 或所属项目（`projects.db` 的 `project_folders` 表和 `spawn-trees/` 也不一定能查到这层映射——本次两处都查了，没查到）。要把一个 `session_id` 归属到具体项目，得用间接推断：`grep -n "<session_id>" agent.log | grep "turn_context: conversation turn"`，读 `msg=` 字段里用户提到的 `@文件路径`（如 `@docs/dbf_filter_spec.tex`），再 `find`/`ls` 反查这些文件真实落在哪个项目目录下。

**为什么**：诊断"这次故障影响的是不是用户正在关心的那个项目"，前提是先确认 session 归属——但日志结构里没有现成的 cwd 字段，凭 session id 本身（如 `20260902_112432_d74033`）看不出来。

**修法**：两步都要做才算归属确认，不要只凭消息内容里提到的项目名字（可能是随口一提，不是真实 cwd）——(1) 从 `turn_context` 的 `msg=` 里拿到具体文件引用/关键词；(2) `find <候选项目目录> -iname "*关键词*"` 或直接 `ls` 目标绝对路径，确认文件真实存在于该项目下。

**边界**：这只是间接推断，不是权威归属；如果一个 turn 里用户没提任何文件路径/项目相关关键词，这条方法失效，需要换手段（比如直接问用户，或深挖 `tui_gateway.server` 的 `ui_session` 关联表——本次未验证这条路是否可行）。

**证据**：2026-09-02，用这个方法把 session `20260902_112432_d74033` 归属到 `~/Dev/ucm221-pointcloud-2.0`（凭 `docs/dbf_filter_spec.tex` / `docs/dbf_algorithm_design.tex` 引用，`find`/`ls` 确认文件真实存在于该项目 `docs/` 目录下）。
