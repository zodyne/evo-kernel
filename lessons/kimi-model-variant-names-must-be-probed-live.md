---
id: kimi-model-variant-names-must-be-probed-live
type: lesson
status: candidate
scope: global
domain: llm-api
tags: [kimi, moonshot, model-name, api-config]
triggers:
  - "给工具/MCP server 配置 kimi（Moonshot）模型名"
  - "kimi API 报 model not found / 404，不确定该写 k3 还是 kimi-k3"
  - "从文档或记忆抄 kimi 模型变体名（k3 / k3-256k / kimi-for-coding / kimi-for-coding-highspeed）"
  - "同一厂商存在多个模型变体名，不确定哪个真实可用（失败信号：写死的模型名从未实测调通过）"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:5f8dee58-e3b6-4552-a0bf-8df757d08d5c
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [verify-external-references, untested-tool-config-bugs-stay-invisible]
---
kimi（Moonshot）的模型变体名有坑：`k3` / `kimi-k3` / `k3-256k` / `kimi-for-coding` / `kimi-for-coding-highspeed` 并存，凭文档或记忆写配置极易写错；**每个要写进配置的变体名都必须用真实 API key 发一次最小请求实测**（拿到 200 + 正常 content 才算数），实测通过的清单再写进 SKILL.md/配置注释。

证据：graph-lab multi_model_mcp.py 配置会话中，`k3-256k` 与 `kimi-for-coding-highspeed` 均经 curl 级真实 POST 返回 200 验证；验证后的变体名清单被固化进 `skills/delegate-multimodel/SKILL.md`（第 104/107 行）。

边界：变体可用性随套餐/时间变化，实测清单要标注日期；此模式同样适用于其他变体名混乱的厂商。
