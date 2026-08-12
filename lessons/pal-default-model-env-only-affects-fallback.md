---
id: pal-default-model-env-only-affects-fallback
type: lesson
status: candidate
scope: project:pal-mcp-server
domain: config
tags: [pal, mcp, default-model, env-config, kimi]
triggers:
  - "想改 pal-mcp-server 的默认模型（不传 model 参数时用哪个）"
  - "担心改了 DEFAULT_MODEL 会导致其他模型（glm/k3 等）不能再显式指定"
  - "pal 的 MCP 握手提示文本里写的默认模型和实际想用的不一致"
  - "不确定 pal 的默认模型配置在代码里还是 .env 里，grep 定位配置入口"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:b78d3e85-eb00-4f1c-82d9-d12ac9e1fbc7
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [listmodels-display-omits-provider]
---

**主张**：`pal-mcp-server` 的默认模型由 `.env` 里的 `DEFAULT_MODEL` 控制（不在代码里写死）；改它只影响两处——调用方不传 `model` 参数时的兜底模型，以及 MCP 工具描述/握手提示里"不指定模型就用哪个"的文案——**不会限制显式指定其他已配置模型**。所以把默认从 `glm-5.2` 换成 `k3` 这类操作是安全的纯兜底变更，不用怕锁死模型选择。

**证据**：`grep -n "DEFAULT_MODEL" server.py` 命中 3 处——`47` 行从 config 导入、`805` 行 `model_name = arguments.get("model") or DEFAULT_MODEL`（显式参数优先，DEFAULT_MODEL 仅作 or 兜底）、`1123` 行 resolve 有效模型；`grep` 工具描述文案命中 `server.py:1502`（"When no model is mentioned, first use the `listmodels` tool..."一段）。实际编辑 `.env:14` 把 `DEFAULT_MODEL` 从 `glm-5.2` 改为 `k3`，无其他文件需要联动修改。

**边界**：这是 pal-mcp-server 当前版本的代码事实——`.env` 由 `utils/env.py`（dotenv）加载、经 `config.py` 暴露给 server.py；若上游重构了模型 resolve 逻辑（805/1123 行附近），"只影响兜底"的结论要复验。另外改的是**已在跑的 MCP server 的环境配置**，常驻进程需重启才会读到新值（参见 `long-running-process-needs-restart-after-pip-install` 同一坑型）。
