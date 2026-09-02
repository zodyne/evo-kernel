---
id: hermes-fallback-providers-turn-scoped-auto-restore
type: lesson
status: validated
scope: global
domain: hermes
tags: [hermes, fallback, deepseek, glm, reliability, config, gateway]
triggers:
  - "hermes 主模型（如 deepseek-v4-pro）反复连接失败/503，只能手动切模型续会话"
  - "想让 hermes 在主模型挂掉时自动切备用模型，恢复后自动切回主模型"
  - "hermes fallback_providers 该填什么、切回主模型要不要自己再切一次"
  - "errors.log 报 Broken pipe / EmptyStreamError / Server Overloaded（自定义 provider 经代理中转）"
created: 2026-09-02
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:69873e4a-d307-4ff5-b06a-b44acb4ccd1c
last_verified: 2026-09-02
superseded_by: null
schema_version: 1
related: [hermes-config-set-cannot-write-list-dict, hermes-cron-model-drift-fail-closed]
---
Hermes 内置 turn-scoped 自动故障转移，不需要自己写监控脚本：config.yaml 顶层加 `fallback_providers: [{provider: <providers字典里的裸key>, model: <model>}]` 并 `hermes gateway restart` 后，主模型报连接错误/5xx/空流/重试耗尽/安全拒答时会自动切到链上第一个可用 provider；且 `restore_primary_runtime()`（agent_runtime_helpers.py）在**每个新 turn 开头**都会先尝试换回主模型——不需要用户手动切回，除非这次失败被分类为 rate_limit/billing，那样会有独立的指数退避冷却（60s→2m→4m→…→4h 封顶）延迟切回尝试。

**为什么会踩这个坑**：`fallback_providers` 默认是空列表（`config_defaults.py`），即使代码里 `_try_activate_fallback()`（conversation_loop.py）在每次错误时都会被调用，链空了也切不了，turn 直接 `status=error` 扔回用户——看起来像是"没有自动恢复能力"，实际只是没配置。2026-09-02 14:00-14:10 deepseek-v4-pro（经自建代理中转）反复故障期间，两个并发 session 对照鲜明：一个被用户手动 `switch_model()`（和自动切换是同一个底层函数）救回，另一个没人管，卡死在 error 状态。

**修法**：
```yaml
fallback_providers:
  - provider: glm-coding   # providers: 字典里定义好 base_url/key_env/transport 的裸 key，不带 custom: 前缀
    model: glm-5.3-flash
```
改完必须 `hermes gateway restart`（graceful drain + launchd 重启；drain 超时会打印 "forcing launchd restart" 但仍会成功）——光改文件不重启不生效（watchdog 会警告 "config 改于 gateway 启动后未重启生效"）。**验证要到解析层** `hermes fallback list`，会打印 Primary/Fallback chain，不能只看文件内容有没有这段 YAML。

**边界**：这条只覆盖连接错误/5xx/空流/安全拒答这类"临时挂了"场景；rate_limit/billing 类失败走独立的指数退避冷却逻辑，不受这条"每 turn 自动切回"覆盖。

**证据**：追进 `agent/conversation_loop.py::_try_activate_fallback()`、`agent/agent_runtime_helpers.py::restore_primary_runtime()` 源码确认机制存在且未配置；加 `fallback_providers` 后 `hermes gateway restart` + `hermes fallback list` 现场验证生效（`Primary: deepseek-v4-pro` / `Fallback chain: glm-5.3-flash via glm-coding`）。
