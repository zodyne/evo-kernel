---
id: readonly-dispatch-version-probe
type: lesson
status: candidate
scope: global
domain: system-governance
tags: [dispatch, constraint, compliance, audit, nvim, probe]
triggers:
  - "派发词写『不要启动 nvim / 不要起 X 进程』这类字面禁令"
  - "审计结论是『字面违反』，唯一证据却是 `X --version` / `--help` 探测（失败信号）"
  - "子 agent 为探测环境跑了版本命令，被记为违规"
  - "只读派发约束要不要豁免版本/帮助探测命令"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e522-725c-a75a-f97a33010dba
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: []
---

**主张**：只读派发词若写成「不要启动 nvim 进程」，子 agent 为探测环境跑的 `nvim --version` 会被审计判成**字面违规**——本会话就是这么判的。禁令应绑定到危害（**会加载用户配置、与用户正在运行的实例互相干扰的交互式启动**）并显式豁免 `--version` / `--help` 这类只读探测；否则「是否违约」取决于审计者的字面口径，而不是行为有没有害。

**为什么**：派发词的原话是「**只读，绝对不要修改任何文件**（不要 edit/write，也不要启动 nvim 进程——用户可能同时开着 nvim，跑嵌套 nvim 会互相干扰）」——理由写的是「互相干扰」，而版本探测并不建立交互会话。字面禁令与它自己给的危害理由之间有缝，缝里就长出了「字面违规」这种结论；同一份行为在另一个审计者手里可能被判合规，判据不可复现。

**证据（切片逐字）**：
- 严格扫描该会话 bash toolCall：`=== strict nvim invocation scan in bash toolCalls === 17:nvim --version 2>/dev/null | head -3; ls -d /opt/homebrew/Cella…`。
- 会话末尾核对结论：`该审计会话共 106 条 bash / 13 次 read（agent-summary 逐字：{"commands":106,"reads":13,"edits":0,"writes":0,"others":22,"failed":5,"durationMs":450218}）。**它确实违反了派发词的字面要求，启动了 1 次 nvim`（切片截断）。
- 同会话 0 edits / 0 writes（agent-summary 与切片「写/改文件」段为空一致）⇒ 违规判定只落在「启动」这一条字面口径上。

**边界/反例**：切片只证明「该命令确实被执行过 + 被审计判为字面违规」，**没有**验证 `nvim --version` 是否真会干扰用户正在跑的实例（无危害实验）。若派发者本意就是「连 `--version` 都不许」，那字面判罚是正确执行——本条要求的只是把这个口径**写进派发词**，而不是留给审计者临场解释。切片截断，无法穷举该会话是否还有其它 nvim 启动（严格扫描只看到 line 17 一处，但输出被截断）。
