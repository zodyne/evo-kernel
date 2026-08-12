---
id: listmodels-display-omits-provider
type: lesson
status: candidate
scope: project:pal-mcp-server
domain: debugging-methodology
tags: [pal, mcp, listmodels, provider-registry]
triggers:
  - "pal 的 listmodels 输出里看不到某个 provider（如 Kimi/k3）"
  - "怀疑某模型没配置 API key，但 .env 里其实已经填了"
  - "工具的‘展示列表’和‘是否已注册/可用’对不上"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:b78d3e85-eb00-4f1c-82d9-d12ac9e1fbc7
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [local-proxy-env-blocks-api-client]
---

**主张**：`pal-mcp-server` 的 `listmodels` 工具（`tools/listmodels.py:100-106`）里 `provider_info` 表是手写的 provider 白名单（Google/OpenAI/Azure/XAI/DIAL + 单独硬编码的 OpenRouter/Custom 分支），**没有把 Kimi provider 列进去**——所以即使 `KIMI_API_KEY` 已配置、provider 已注册、模型确实可用，`listmodels` 的人类可读输出里也永远不会出现 Kimi/k3 的段落。`listmodels` 展示"未列出"≠"未配置"，遇到这种情况要去读展示代码本身的分支覆盖，而不是默认相信输出完整。

**证据**：`.env` 里 `KIMI_API_KEY` 已填好非占位符的真实 key（`grep -n KIMI .env` 命中），`server.py:466-531` 里 Kimi provider 的注册条件（key 非空且非占位符）满足会被注册进 `ModelProviderRegistry`；但 `mcp__pal__listmodels` 的输出只有 Google/OpenAI/Azure/XAI/DIAL/OpenRouter/Custom 七段，完全没有 Kimi 段落。读 `tools/listmodels.py` 源码确认 `provider_info` dict（100-106 行）里没有 `ProviderType.KIMI` 这一项，是展示代码的遗漏，不是运行时判断的结果。

**边界**：这条是 `pal-mcp-server` 这个具体仓库的代码缺陷（provider 白名单没跟上新增 provider），不是通用规律；但背后的方法论可以泛化——**任何"展示/清单类"工具的输出都只是它自己实现覆盖到的子集，怀疑某项"未配置"时应优先直接尝试调用而非只看清单**。若之后有人修了 `listmodels.py` 补上 Kimi 分支，这条证据会过期，需要复验。
