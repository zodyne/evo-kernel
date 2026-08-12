---
id: untested-tool-config-bugs-stay-invisible
type: lesson
status: candidate
scope: global
domain: tooling
tags: [mcp, api-config, e2e-test, acceptance]
triggers:
  - "写完一个调用外部 API 的工具/MCP server，准备宣布完成"
  - "工具配置里写死了 endpoint/协议/模型名，但从未真实调通过一次"
  - "smoke 只做了 py_compile/语法检查就当验收（失败信号）"
  - "某个-provider 从来没人用过，默认它是好的"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:0fe7c2be-cdd2-41a5-be17-e2cd31fe1740
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [fix-api-config-via-local-harness-reference, verify-external-references]
---

**主张**：从未被真实端到端调用过的工具，其配置错误（错误端点 + 错误协议）是完全隐形的——语法检查、单元跑通都发现不了，只有真实调一次才暴露。

**证据**：graph-lab `tools/multi_model_mcp.py` 的 kimi provider 配了错误端点 + 错误协议，一直打不通，但无人察觉，因为 `ask_external_model`/`poll_models` 从没被真正调用测试过。本次会话 curl 裸打两个候选端点对比（旧端点 401 `Invalid Authentication`；正确端点返回正常 anthropic message JSON），改正配置后端到端测试通过。`py_compile` 的 "SYNTAX OK" 对这类 bug 毫无检出力。

**边界**：不是"每个工具都要写测试"的重主张；最低标准是交付前**手动真实调用一次**每个 provider/分支，亲眼看到预期响应。
