---
id: pal-new-provider-must-join-priority-order
type: lesson
status: archived
scope: global
domain: mcp
tags:
- pal-mcp
- provider-registry
- auto-routing
- kimi
triggers:
- 给 pal-mcp-server 新增一个模型 provider（写 providers/<name>.py）
- 新 provider 代码写完、直连测试 200，但自动路由永远选不到它（失败信号）
- 改 providers/registry.py 的 PROVIDER_PRIORITY_ORDER
- pal 加新模型后端，验收前核对注册清单
created: 2026-07-30
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: session:96b324ab-2f30-42f6-a16c-69d99d52c26c
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related:
- pal-model-capabilities-declare-code-support
- pal-custom-provider-models-json-registry
- mcp-sdk-2-removed-fastmcp-pin
---

**主张**：pal-mcp-server 新增 provider，只写好 `providers/<name>.py` 类文件不够——必须把 `ProviderType.<X>` 加进 `providers/registry.py` 的 `PROVIDER_PRIORITY_ORDER`，否则 provider 自动选择逻辑永远轮不到它。

**证据**：会话 commit `6ec42f5` "fix: register Kimi in PROVIDER_PRIORITY_ORDER, stop overclaiming capabilities"（registry.py + kimi.py，33 insertions）——Kimi provider 类已实现、直连 `api.kimi.com/coding/v1/messages` 测试 200 OK 之后，仍需要这个 fix commit 补登记才完成接入。

**边界**：显式指定 provider 的调用路径是否绕开该清单，切片中无证据，不断言；自动选择路径下漏登记的症状是"静默选不到"，不报错。
