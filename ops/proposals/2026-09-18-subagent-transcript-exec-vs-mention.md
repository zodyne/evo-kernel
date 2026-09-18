---
id: subagent-transcript-exec-vs-mention
type: lesson
status: candidate
scope: global
domain: agent-harness
tags: [pi, jsonl, transcript, audit, grep, false-positive, compliance]
triggers:
  - "在会话 transcript / jsonl 里核对某个命令或进程到底有没有真的被执行"
  - "审计子 agent 是否遵守『不要执行 X / 不要启动 X』类约束"
  - "对 transcript 全文 grep 命令名就下『执行过』结论（失败信号）"
  - "read 工具回灌的源码/配置正文里出现同名调用，被误当成执行（假阳性）"
  - "想区分『工具真的跑了』与『正文/思考里提到了』"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e522-725c-a75a-f97a33010dba
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [substring-matcher-cannot-tell-exec-from-mention, pi-jsonl-toolresult-toolcallid-pairing]
---

**主张**：在会话 transcript 里判定「某命令/进程是否被执行过」，只在**工具调用的结构字段**上匹配（bash 工具调用的 `command` 字符串），**不要对 transcript 全文 grep 命令名**。全文命中里混着两类非执行文本：(a) `read` 工具回灌的源码/配置正文；(b) assistant 的 thinking/text 讨论。两者都会把「文中出现」升级成「执行过」。

**为什么**：被审计的会话审的是 nvim 配置，`read` 把 `lua/configs/*.lua` 原文写进了 transcript，正文里本来就有 `vim.fn.system(...)`、`vim.lsp.rpc.start(...)`、`uv.spawn` 这类调用字样；对整份 jsonl grep `spawn`/`system`/`nvim` 必然命中，而这些命中不是该会话执行过的命令。结论方向会被直接反转——把守约会话判成违约，或反过来放过真违约。

**证据（本会话命令 ↔ 结果，切片逐字）**：
- 先按 bash 命令粗扫：`=== all bash commands containing nvim as a command === 1:ls -la /Users/zodyne/.config/nvim/ ...`（切片截断）。
- 再**只扫 toolCall 的 command**，拿到唯一一次真实执行：`=== strict nvim invocation scan in bash toolCalls === 17:nvim --version 2>/dev/null | head -3; ls -d /opt/homebrew/Cella…`。
- 反向自查「正文里的调用」：`=== jobstart / vim.fn.system / vim.system / writefile inside the audit's tool results (config file contents) ===` → **无输出**（配置正文里的这些名字没有被算成执行）。
- 同名符号确实存在于讨论文本：`=== spawn/uv/job/writefile/reload in thinking+text === 75:11. 'lspconfig.lua': 'clangd_start' uses 'vim.lsp.rpc.start(ar…` —— thinking/text 命中 ≠ 执行。
- transcript 里确实回灌过含此类调用的文件：`[read] {"path":"/Users/zodyne/.config/nvim/lua/configs/lspconfig.lua"}`。

**边界/反例**：本条与其说是新机理，不如说是 [[substring-matcher-cannot-tell-exec-from-mention]] 在**取证/对账侧**的落地——那条讲拦截规则（block 前复核误报率），本条讲审计 transcript（判合规前只扫 command 字段）。切片只覆盖 pi 的 jsonl 结构，Claude / Hermes transcript 的字段形状不同（见 related），未复验。反向漏判未在切片中出现：命令被拼进 shell 变量、heredoc 或 `bash -c "..."` 字符串时，扫 command 字段也可能把执行读成「提及」——本会话无此反例。切片按行截断，上引命令的后半段不可见。
