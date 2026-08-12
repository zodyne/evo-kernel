---
id: pal-model-capabilities-declare-code-support
type: lesson
status: candidate
scope: global
domain: mcp
tags: [pal-mcp, model-capabilities, overclaim, adapter-layer]
triggers:
  - "在 provider 适配层填 ModelCapabilities（supports_images / function_calling 等）"
  - "照抄同族其他 provider 的能力声明当模板"
  - "generate_content 签名只收 prompt: str 却声明 supports_images=True（失败信号）"
  - "上层工具按能力声明路由，发了适配代码处理不了的载荷（失败信号）"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:96b324ab-2f30-42f6-a16c-69d99d52c26c
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [pal-new-provider-must-join-priority-order, untested-tool-config-bugs-stay-invisible]
---

**主张**：provider 适配层的 `ModelCapabilities` 声明的是"**我们的适配代码支持什么**"，不是"模型本身能做什么"——两者不能混为一谈。`generate_content()` 签名只接收 `prompt: str`、没有构建任何 image content block 时写 `supports_images=True` 就是 overclaim bug，会让上层工具误以为可以向该 provider 发图。

**证据**：会话 commit `6ec42f5` "fix: register Kimi in PROVIDER_PRIORITY_ORDER, **stop overclaiming capabilities**"；末条 assistant 自述："改的不是模型本身的能力，是 pal 里 ModelCapabilities 这个'我们的代码支不支持'的声明——这两者被我最初的实现混为一谈了"，并指出 `generate_content()` 只收 `prompt: str`。

**边界**：反模式来源是照抄同族 provider 的能力声明当模板；填每个 capability 字段前问一句"我的代码里处理这个载荷的分支在哪"，答不出就写 False。
