---
id: pi-model-switch-verify-in-session-jsonl
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, session-jsonl, model_change, model-fallback, evidence, debugging]
triggers:
  - "要核实 pi 里模型到底有没有被切换（用户说『它切到 glm 了』，要证真或证伪）"
  - "排查『模型报错后自动切备选』是否真的生效，手上只有 TUI 通知和用户描述"
  - "pi 扩展的通知/状态展示说要切模型，不确定能不能当证据用"
  - "统计某段时间里某个 provider 实际被用了多少次"
created: 2026-09-19
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4b1-4d5c-71e5-a2e6-3b87dd370d2e
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [pi-fallback-target-must-be-in-model-registry, pi-model-fallback-early-switch-and-retry, pi-jsonl-toolresult-toolcallid-pairing]
---

# 核实 pi 有没有真的换模型，只认会话 jsonl 里的 model_change + assistant.provider

## 主张

要判断"pi 里模型有没有被切 / 现在跑的是不是那个模型"，唯一可靠的证据是会话 jsonl：**`model_change` 条目**（扩展 `pi.setModel()` 成功和手动切换都会落一条）+ **每条 assistant 消息自带的 `provider` / `model` 字段**。扩展的 TUI 通知走 `ctx.ui.notify`，**不落盘**；"通知里说要切"和"状态栏显示某模型"都不能当作切换发生的证据。查法就两条 jq：`select(.type=="model_change")` 和 `select(.type=="message" and .message.role=="assistant")`。

## 为什么

切模型失败时最容易被误导的地方是：**失败路径和成功路径的外部表现都是"弹了一条关于备选模型的通知"**——`model-fallback` 扩展在"查不到 provider"和"切成功"两种情况下都会 `safeNotify`（只有文案不同），而只有成功那条才会 `pi.setModel` 并让后续消息带上新的 provider。用户（和排查者）看到通知里有 `glm-5.3` 字样，就很容易记成"切到 glm-5.3 了"。jsonl 里的字段是请求实际用的模型，不受 UI 文案影响，能把"尝试切但没切动"和"真切了"分开。

## 证据（切片命令 ↔ 结果 + 本机复核 2026-09-19）

**证伪用例（9/18，切换是死链）**
- 对三个会话（evo-kernel 12:18 / evo-kernel 13:25 / algommw-plus 13:10）跑 `jq -r 'select(.type=="model_change") | ...'` ↳ 各只有一条 `deepseek-internal/deepseek-v4-flash`；跑 `... | .message.provider + "/" + .message.model | sort | uniq -c` ↳ `34 deepseek-internal/deepseek-v4-flash`、`56 ...`、`202 ...`，**没有一条 glm**。
- 同一批会话里有 18 条 `stopReason=error`（`terminated`/`Connection error.`/`Request timed out.`）——即"发生了模型错误、也发生了切换尝试"，但 jsonl 证明一次都没切。

**证真用例（9/19 补回 provider 后，同一台机器、同一份扩展代码）**
- `model_change` 出现 `2026-09-19T10:22:57.613Z glm-coding/glm-5.3-flash`（紧跟在 deepseek 的 `Request timed out.` 之后 3ms），此后 11 条 assistant 消息 `provider=glm-coding`、`model=glm-5.3-flash`，token 非 0、stop=toolUse。
- 检索 `rg '"provider":"glm' ~/.pi/agent/sessions` ↳ 9/17 及以后为 0（上一次真实使用是 9/11），与上面的结论一致。

**通知不落盘（源码复核）**
- `~/.pi/agent/extensions/model-fallback/index.ts:145-151`：`safeNotify` = `if (ctx.hasUI) ctx.ui.notify(text, level)`，没有任何 session 写入；只有 `pi.sendMessage({customType:"model-fallback", ...})` 那种才会在 jsonl 里留 `custom` 条目（本会话切片里没有）。

## 边界

- jsonl 能判"切没切"，判不了"**谁**切的"：扩展 `setModel` 与手动 `/model` 都写 `model_change`，形态相同。要归因得靠 `MODEL_FALLBACK_DEBUG` 的 trace（本例未开，所以会话里查不到 trace，用 `ls /tmp/*fallback*` 和 shell profile 里没有 `MODEL_FALLBACK_DEBUG` 佐证过）。
- `provider` 字段是"这次请求实际用的模型"，不是用户选的目标模型；切换只影响后续请求，所以同一会话里会看到新老 provider 交错（本例 10:25 切回又切走）。
- 这套字段是 pi 的会话格式（本机 v3 会话）；换 harness 或 pi 大版本前先看一眼首行 `type:"session"` 的 version。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
f=~/.pi/agent/sessions/--Users-zodyne-Dev-algommw-plus--/2026-09-18T13-10-21-079Z_01a0b4a3-ae96-7475-af70-36ad39adaba4.jsonl
jq -r 'select(.type=="model_change")|"\(.timestamp)\t\(.provider)/\(.modelId)"' "$f" | grep '2026-09-19T10:22:57'
# 期望输出： 2026-09-19T10:22:57.613Z	glm-coding/glm-5.3-flash
jq -r 'select(.type=="message" and .message.role=="assistant" and .timestamp>="2026-09-19T10:22:57" and .message.provider=="glm-coding")|.message.stopReason + " out=" + ((.message.usage.output // .message.usage.outputTokens // 0)|tostring)' "$f" | sort | uniq -c
# 期望输出：  11 ...toolUse out=<非0>  +  2 ...length out=1
sed -n '145,149p' ~/.pi/agent/extensions/model-fallback/index.ts
# 期望输出： const safeNotify = (ctx, text, level) => { try { if (ctx.hasUI) ctx.ui.notify(text, level); } catch {} };  —— 无任何 session 写入
grep -n 'writeFileSync\|appendFileSync\|sendMessage\|ui.notify' ~/.pi/agent/extensions/model-fallback/index.ts
# 期望输出： 写盘只有 138 appendFileSync(MODEL_FALLBACK_DEBUG trace) 与 292 sendMessage；147 为唯一 notify，不落盘
```

**审核给出的修改意见（要点）**：核心主张（切换真值只在会话 jsonl 的 model_change + assistant.provider/model 上，ctx.ui.notify 不落盘）稳定且可当场复跑，故仍留注入集，但证据节需换证据：1) E2/E4 把命令与输出写实（`jq -r 'select(.type=="model_change")|"\(.timestamp)\t\(.provider)/\(.modelId)"' <file>` 与对 assistant 的 `.message.provider+"/"+.message.model | sort | uniq -c`），不要用被截断的 `... |` 与 `34/56/202` 这种不复现的裸数字；2) 删掉或明确标注过期快照：`18 条 stopReason=error`（现同一批会话为 39，且切片根本没这项）与 algommw 的 `202`（现 560）；3) E4 的 source 应指向 `--Users-zodyne-Dev-algommw-plus--/2026-09-18T13-10-21-079Z_...jsonl` 而不是条目 source 里的 01a0b4b1（同一台机、不同会话）；4) 收窄『此后 11 条』为『11 条 stop=toolUse（另有 2 条 stop=length）』；5) `safeNo

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 18 条 `stopReason=error`（`terminated`/`Connection error.`/`Request timed out.`）——切片无任何 stopReason 记录，且本机按同样三个会话复核为 39 条（会话已增长），18 无法复现

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
