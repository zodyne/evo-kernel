---
id: recall-self-hit-injects-the-material-under-discussion
type: lesson
status: candidate
scope: global
domain: agent-ops
tags: [recall, self-hit, injection, token-cost, knowledge-base, circularity]
triggers:
  - "一次注入里的条目，好几条正是当前正在编辑的那几个文件"
  - "任务文本里出现了知识库条目的 id（如工作流完成通知、审计清单）"
  - "盘算一次注入的实际信息量，想知道有多少是重复的"
  - "会话的工作对象就是知识库自身（审计/改写/复盘库里的条目）"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:2a5c9cfe-7ff2-46f2-800e-c160ffe842a5
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [forensic-grep-self-hit-current-session, recall-failure-empty-vs-noise-taxonomy, entry-id-grep-hits-bench-labels]
---

# 一次观测（样本 1）：任务文本里出现了条目 id ⇒ 召回把「正在改的那几条」注入回来

**主张**：本次观测到一次注入，9 条里 **6 条正是该会话正在审计与改写的条目**。
可复现的触发条件比「会话主题就是库」**窄得多**：那次注入由一条**工作流完成通知**触发，
而通知正文里**字面含被审条目的 id**——词法召回命中的是这些 id。
所以值得记住的判据是：**任务文本里出现库条目 id 时，召回会把那些条目注入回来**；
在「审计条目 X」这类泛措辞下是否同样命中，本条未观测，不要外推。

## 证据（2026-09-22，命令 ↔ 结果）

- 本次唯一一次非空注入（`evo slice` 的 `injected:` 行）：共 **9** 条，其中 **6** 条
  （`latex-detokenize-*`、`mcp-server-delegation-*`、`tmux-kill-window-*`、
  `nvim-terminal-alt-screen-*`、`headless-claude-ultracode-*`、`claude-auto-classifier-*`）
  **正是该会话正在审计与改写的条目**（含 1 条已改名的旧 id）。
- 另 2 条（`pi-ts-net-gateway-http-proxy-sing-box`、`claude-code-nanoradar-gateway-settings`）
  与本次任务无关；1 条原则（`verify-external-references`）相关但未用。
- 对账落盘：7 `relevant-unused` + 2 `irrelevant`（`ops/log/reconcile.jsonl`，session `2a5c9cfe-…`）
  —— 两次词法命中为空（另外两个提示词的 `recall.jsonl` 行 `hits: 0`）。

## 边界 / 反例

- **样本量 1**，且判「注入的是不是当前工作对象」要靠语义比对（所以标 `human` 候选、不进注入集）。
  要升级需再攒几次同类会话。
- 「零信息增益」是**语义判断**，产物只证明「这 9 条被判 unused/irrelevant（`judged_by: reflector`，
  同 session 自评）」——不能证明增益的量。
- 本次注入**不是纯重复**：同一次里另有 **2 条** state=`irrelevant`（噪声），
  所以它既不是 `recall-failure-empty-vs-noise-taxonomy` 说的空命中、也不只是「重复」，是**混合**。
- 不主张「这是检索当前工作对象的**固有循环**」——那是从 n=1 补出的机制，本条不写。
  可写的只有：这次的触发条件是什么、命中了哪些。
- 不主张「该给这种注入加去重」：内核看不到 harness 的上下文，判不了「是否已在上下文里」。
