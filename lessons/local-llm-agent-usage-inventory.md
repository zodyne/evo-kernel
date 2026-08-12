---
id: local-llm-agent-usage-inventory
type: lesson
status: candidate
scope: global
domain: agent-usage-audit
tags: [llm, coding-agent, usage-stats, session-files, inventory]
triggers:
  - "盘点/审计本机装了哪些 coding agent、各自在用哪些大模型"
  - "要统计某个 agent 历史会话里的模型用量分布"
  - "用户问『我都在用什么模型和 agent』，要给出一行式汇总或报表"
  - "机器迁移/清理前想摸清本机 AI 工具全貌"
  - "凭记忆列举本机工具，漏掉 openclaw/ccman 这类不常用 CLI（失败信号）"
created: 2026-08-06
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fd501-7918-7619-aa0a-818486c62829
last_verified: 2026-08-06
superseded_by: null
schema_version: 1
related: [pi-credentials-auth-json-models-store, openclaw-config-openclaw-json, mask-secrets-when-reading-config]
---

**主张**：盘点本机 LLM/coding agent 使用情况不要凭记忆列举，按五路取证一次跑通：① `command -v` 枚举 CLI（claude / pi / codex / aider / gemini / openclaw…）；② `ls -d ~/.claude ~/.pi ~/.codex ~/.gemini ~/.openclaw …` 找配置目录；③ grep shell rc 里的 `*_API_KEY` 确认供应商通道；④ `ollama list` + manifests 查本地模型；⑤ 模型用量从各 agent 本地会话文件聚合——pi 在 `~/.pi/agent/sessions/*.jsonl`、claude 在 `~/.claude/projects/` 的 history 文件、codex 在 `~/.codex` sessions，python `collections.Counter` 统计模型字段即可。汇总报表用 openpyxl 写 xlsx。

**证据**：会话按此路径一次跑通——pi 86 个会话文件（k3 1506 / glm-5.2 1221 条消息…）、claude 720 个 history 文件（glm-5.2 12731 / claude-opus-5 7117…）、codex（gpt-5.5 5735 / gpt-5.4 1976…）均得出计数；`npm ls -g` 核实了 openclaw/ccman/grok-cli 三个陌生包的身份；最终 openpyxl 3.1.5 生成 `~/Desktop/LLM与CodingAgent使用统计.xlsx`（9.6K，4 sheet）交付。

**边界**：读含凭据的配置文件必须先过 sed/python 打码（见 related mask-secrets-when-reading-config）；不认识的 npm 全局包用 `npm ls -g <name>` + `npm view` 核实，不要凭包名猜用途；会话文件格式随 harness 版本漂移，统计脚本以当次实际字段为准。
