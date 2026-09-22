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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含、本机实跑通过（pi 0.86.1）：

# (A) provider 不在 models.json → pi 根本看不见它（一次性 HOME，不碰真配置）
T=$(mktemp -d); mkdir -p "$T/.pi/agent"
echo '{"providers":{"deepseek-internal":{"baseUrl":"https://x/v1","api":"openai-completions","apiKey":"k","models":[{"id":"deepseek-v4-flash"}]}}}' > "$T/.pi/agent/models.json"
HOME=$T pi --list-models glm
# 实测 → No models matching "glm"
echo '{"providers":{"deepseek-internal":{...同上...},"glm-coding":{"baseUrl":"https://open.bigmodel.cn/api/anthropic","api":"anthropic-messages","apiKey":"k","models":[{"id":"glm-5.3-flash"}]}}}' > "$T/.pi/agent/models.json"
HOME=$T pi --list-models glm
# 实测 → provider model ... / glm-coding  glm-5.3-flash ...

# (B) 查表落空 = 静默 return（无通知、无 setModel）——源码即真值
sed -n '213,217p' ~/.pi/agent/extensions/model-fallback/index.ts
# 实测 → const model = ctx.modelRegistry.find(decision.to.provider, decision.to.id);
#         if (!model) { trace(`early switch: ${key(decision.to)} 不在注册表`); return; }
sed -n '24,26p' /opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent/dist/core/model-registry.js
# 实测 → find(provider, modelId) { return this.runtime.getModel(provider, modelId); }
```

**审核给出的修改意见（要点）**：核心主张真值稳定（本机 pi 0.86.1 + 本地 model-fallback 源码即可复现），应留注入集，但证据节要换、数字要收窄：1) 把两段『坏的状态』历史命令（切片里已被截断，且 models.json 已修好、照抄重跑得到的是修后结果）换成 minimalRepro 的自包含复现（一次性 HOME 演示『不在册 → pi --list-models 看不到』+ 贴 index.ts:213-217 与 model-registry.js:24-26 两行源码证明『查表落空即静默 return』）。2) 『9/18 三个会话共 18 条模型错误』改为可复算口径，如『9/18 起 terminated 10 + Connection error. 6 + Request timed out. 2 共 18 条，全部来自 deepseek-internal，跨 4 个会话』；删掉对不上的『34/202』，或把 34 明确写成 01a0b4a3 的 error 计数、56 写成 01a0b4b1 的 assistant 计数。3) `auth.json`={} 在切片无对应命令，标注『本机复核』或补 `wc -c ~/.pi/agent/auth.json`（现为 2 字节）。4) 主张句『任何写死 provider 名的自动化（fallback 链、子代理模型、脚本）』超出

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- "9/18 三个会话共 18 条模型错误" —— 18 这个总数可复算，但『三个会话』不成立：错误实际分布在 ≥4 个会话文件里
- "assistant 消息的 provider 计数 34/56/202" —— 56 可核，34 实为 01a0b4a3 的 error-stopReason 计数而非 assistant provider 计数，202 未复现
- "9/15 17:19 重写 models.json 只留 deepseek-internal" —— 备份 mtime=Sep 15 17:19、894 字节可核，但『重写（即人为删掉）』是推断，切片无该动作的命令
- "扩展源码没动、自测也一直绿" —— 历史性『一直』无法验证；selftest 现为 11/11，但切片无 git 记录证明源码未动

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
