---
id: pi-fallback-target-must-be-in-model-registry
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, model-fallback, models.json, model-registry, glm-coding, dead-link]
triggers:
  - "pi 里模型报错后自动切备选，切完这一回合还在原模型上报错（失败信号：切换像是没发生）"
  - "给 pi 配自动切换备选 / 子代理模型 / 任何在配置里写死 provider 名的自动化之前"
  - "pi --list-models 里看不到某个 provider，但扩展、配置或历史会话里在引用它"
  - "重写 ~/.pi/agent/models.json 之后，之前能用的备选模型失效（失败信号：错误照旧、模型没变）"
  - "用户问『切到 glm-5.3 了怎么还报错』，要判断是真切了还是切换根本没落地"
created: 2026-09-19
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4b1-4d5c-71e5-a2e6-3b87dd370d2e
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [pi-model-fallback-early-switch-and-retry, pi-provider-config-split-models-json-vs-models-store, untested-tool-config-bugs-stay-invisible]
---

# 备选 provider 没注册进 pi 的模型表时，自动切换是静默 no-op

## 主张

pi 的模型自动转移（`model-fallback` 扩展）在切换前会拿 provider/id 去 `ctx.modelRegistry.find(...)` 精确查表（`dist/core/model-registry.js` 的 `find` → `runtime.getModel(provider, modelId)`）。**备选 provider 没在 `~/.pi/agent/models.json` 注册时查表返回 undefined：失败当场那条早切路径只写一行 debug trace 就 `return`（连通知都没有），`agent_settled` 那条也只弹一条 TUI 通知、不调 `pi.setModel`。**结果就是模型不变、失败回合原样重演——用户看到的是"切了 glm-5.3 怎么还报错"，而实际上一次都没切。所以任何写死 provider 名的自动化（fallback 链、子代理模型、脚本）上线前，先用 `pi --list-models` 确认它在册。

## 为什么

pi 的 provider/模型清单只以 `models.json`（外加 `/login` 写入的 `auth.json`）为准；`models-store.json` 是空的也不影响这一点。本例的成因就是一次静默删配置：9/15 17:19 重写 `models.json` 只留 `deepseek-internal`，把 9/8–9/11 会话里一直在用的 `glm-coding` 定义删掉了，扩展里默认的 `glm-coding/glm-5.3-flash → glm-coding/glm-5.3` 从此变成死链——扩展源码没动、自测也一直绿，坏的是配置侧，所以直到 9/18 用户看到"还在报错"才暴露。

死链的失败形态是"沉默"，这是它比报错更危险的地方：早切路径只在显式开了 `MODEL_FALLBACK_DEBUG` 时才留痕，默认连 TUI 通知都没有；剩下的信号只有"错误照旧"。

## 证据（切片命令 ↔ 结果 + 本机复核 2026-09-19）

**坏的状态（9/18）**
- `cat ~/.pi/agent/models.json` ↳ provider 只有 `deepseek-internal`（`glm-coding` 无定义）；`models-store.json` = `{}`、`auth.json` = `{}`。
- `pi --list-models glm` ↳ `No models matching "glm"`。
- 扩展默认备选（复核）：`index.ts:30-33 DEFAULT_FALLBACKS = [glm-coding/glm-5.3-flash, glm-coding/glm-5.3]`；`~/.pi/agent/model-fallback.json` 不存在 → 走默认。
- 查表与静默分支（复核 `index.ts:213/268/277`）：`if (!model) { trace("early switch: ... 不在注册表"); return; }`（早切，无通知、无 `setModel`）；settled 分支才是 `safeNotify(ctx, "model-fallback: 备选模型 ... 不在注册表里", "error")` 后 return。
- 现象：9/18 三个会话共 **18 条模型错误**（`terminated` / `Connection error.` / `Request timed out.`，全部来自 `deepseek-internal`），而三个会话的 `model_change` 只有 `deepseek-internal/deepseek-v4-flash`，assistant 消息的 provider 计数 34/56/202 也全是 deepseek——**零次真切换**。

**修好之后（9/18–9/19，同一台机器）**
- 加回 `glm-coding` 定义（`"api": "anthropic-messages"`、`baseUrl: https://open.bigmodel.cn/api/anthropic`、凭据字段由一条 shell 命令从本机 env 文件里取值（`awk` 取键值，不回显明文））后：`pi --list-models` 从 1 行变 4 行（`deepseek-v4-flash` + `glm-5.2/glm-5.3/glm-5.3-flash`）。
- 端到端：`pi -p --no-session -ne -nc -ns -np -a --model glm-coding/glm-5.3-flash "只回答两个字：收到"` ↳ `收到`（`glm-coding/glm-5.3` 同）；扩展自测 `node selftest.mjs` ↳ `11/11 通过`。
- 真切换落地（同一 algommw-plus 会话，9/19 复核）：`10:22:57.613Z model_change → glm-coding/glm-5.3-flash`（前 3ms 恰是 deepseek 的 `Request timed out.` 错误），随后 10:23–11:25Z 有 **11 条 assistant 消息跑在 `glm-coding/glm-5.3-flash` 上**（stop=length/toolUse、token 非 0）；`10:25:43Z` 又出现 `Connection error.` → 立即再次切到 glm。同一份扩展代码，9/18 零切换、9/19 真切换，差别只在注册表里有没有这个 provider。

## 边界

- 本条只证明"注册表里没有 → 一定切不动"；反过来"在册"**不等于**能用——baseUrl / 协议 / 鉴权仍可能错，所以补回定义后还要用 `curl` 或 `pi -p --model <provider>/<id>` 端到端跑一次（本例两条都跑了）。
- `pi --list-models` 是新进程读盘的结果；正在跑的会话按 pi 文档（`docs/models.md`：models.json "reloads each time you open /model"）要开一次 `/model` 或重启才会重载，别拿旧会话里的失败当"配置还没修好"。
- 只针对 pi；其他 harness 的 provider 注册表位置和查找语义不同（hermes 有独立的 `providers`/`fallback_providers` 配置），不要外推。
