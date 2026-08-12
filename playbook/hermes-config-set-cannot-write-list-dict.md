---
id: hermes-config-set-cannot-write-list-dict
type: bullet
status: validated
scope: global
domain: hermes
tags: [hermes, config, yaml, fail-closed, provider]
triggers:
  - "想用 hermes config set 写 JSON 数组/对象"
  - "/model 列表丢失全部自定义 provider"
  - "errors.log 报 Unknown provider 或 should be a dict ... got str"
  - "custom_providers / fallback_model 配置莫名失效"
created: 2026-08-12
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:capture-2026-08-12-01-09-40-611-3769
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [hermes-cron-model-drift-fail-closed]
---
`hermes config set` 不能写 list/dict：值只做 bool/int/float 强转，传 JSON 数组/对象会原样存成字符串，且 hermes v12+ 解析器对非标量配置 fail-closed。

**后果链**：custom_providers 非 list → `get_compatible_custom_providers` 返回空 → /model 列表丢全部自定义 provider；fallback_model 非 dict → fallback 链失效。失败信号：picker 缺 provider、errors.log 报 `Unknown provider` / `should be a dict ... got str`。
**修法**：结构化值用 hermes_cli 的 `utils.atomic_yaml_write` 写真 list/dict（v12+ 正确形态是 providers: dict，字段 api/key_env/default_model/models/transport），或索引路径逐个 set。验证必须到解析层（`get_compatible_custom_providers` / `list_authenticated_providers`），不能只看文件内容。
**证据**：2026-08-12 事故——修复其他问题时用 config set 写 JSON 字符串，把 4 家 provider 配置覆盖成字符串。
