---
id: pal-custom-provider-models-json-registry
type: lesson
status: candidate
scope: global
domain: mcp
tags: [pal-mcp, custom-provider, model-registry, glm]
triggers:
  - "给 pal-mcp-server 的 Custom provider 接入新模型（如 glm-5.2）"
  - "模型名 resolve 失败或被回退，Custom provider 不认这个新模型（失败信号）"
  - "改 conf/custom_models.json"
  - "base.py resolve 逻辑在 model_configs 里查模型名"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:96b324ab-2f30-42f6-a16c-69d99d52c26c
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [pal-new-provider-must-join-priority-order, fix-api-config-via-local-harness-reference]
---

**主张**：pal-mcp-server 的 Custom provider 只认 `conf/custom_models.json`（`model_configs`）里登记过的模型名；接入新模型（如 glm-5.2）的第一步是把它登记进这个 JSON，而不是只在请求里传模型名。

**证据**：`providers/base.py` 的 resolve 逻辑先查 `model_configs`（`if model_name in model_configs: return model_name`，再做大小写不敏感匹配）；会话 commit `3c84a71` "config: register glm-5.2 in Custom provider model registry"（custom_models.json +18 行）；登记后 `Initializing Custom provider with endpoint: https://open.bigmodel.cn/...` 的生成测试成功返回内容。

**边界**：这是 pal 代码库特定的注册点，与 provider 级的 `PROVIDER_PRIORITY_ORDER` 是两个独立清单——模型级登记在 custom_models.json，provider 级登记在 registry.py，接新模型/新 provider 时两处都要核对。
