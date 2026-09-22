---
id: claude-model-slash-command-global-default
type: lesson
status: validated
scope: global
domain: claude-code
tags: [claude-code, model, settings.json, concurrency, config-drift]
triggers:
  - "Claude Code 的默认模型 / 全局配置莫名变了，用户说没手改 settings.json"
  - "同一时间开着两个 Claude Code 会话，各切一次 /model 后互相覆盖（失败信号：settings.json 的 model 在几分钟内反复变）"
  - "排查 ~/.claude/settings.json 漂移来源，需要列全部嫌疑操作"
  - "会话 transcript 里出现 <command-name>/model</command-name>，要判断它会不会落到全局配置"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0c1f4-ba46-7370-8301-baf14cc85c89
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [claude-settings-json-bak-forensics, claude-live-session-detection, claude-code-nanoradar-gateway-settings]
---

# Claude Code 会话里的 /model 会写入全局默认（"saved as your default"），并发多会话切换会互相覆盖

**主张**：Claude Code 里执行 `/model` 不是只改当前会话，而是把选择持久化成全局默认（交互提示为 "saved as your default"，写入 `~/.claude/settings.json`）。
同一台机器同时开多个会话时，各自切模型会互相覆盖，表现为全局配置在几分钟内漂移。
排查配置漂移时应把各会话 transcript 里的 `<command-name>/model</command-name>` 列为嫌疑操作，并与 `settings.json` mtime、`settings.json.bak.*` 时间线对齐。

**为什么**：如果模型选择只作用在会话内存里，全局 settings 不应在用户操作后改变；本会话的时间线（两个会话 11:03–11:05 切换、settings.json mtime 11:09:26）与提示文案相互印证。
把「用户以为的临时切换」误判成「配置文件坏了」，会浪费排查方向。

**证据**（本会话切片）：
- 末条 assistant 的事故时间线：「11:03–11:05 | 你在两个会话里用 `/model` 切模型（→deepseek-v4-flash，各提示 "saved as your default"）」。
- 会话 transcript 检索：`=== 65492 会话里执行过的斜杠命令 ===    1 <command-name>/model</command-name>`。
- `stat` → `2026-09-21 11:09:26 /Users/zodyne/.claude/settings.json`（切换动作之后配置确有变更）。
- 另见 `settings.json.bak.20260921105403 (09-21 10:54) ===== model: sonnet`（更早的模型值，可作为对照基线）。

**边界 / 反例**：
- 本会话没有直接抓到「/model → settings.json 写入」那一步命令：settings.json 内容在切片里被截断，该因果主要来自会话内提示文案与 mtime 相邻，因此标 `human`。
- 只在 2.1.277 一版 Claude Code、两个并发会话的实例上观察到，不能推广为所有版本/所有配置项的行为。
- 覆盖的具体机制（后写覆盖还是列表合并）未验证。

## 2026-09-22 独立复核增补

下列是复核时在本机跑过的**自包含最小复现**：

```
BIN=/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe; rg -a -o 'async function l4e\(e,t,n=O\)\{.{0,110}' "$BIN" | head -1; rg -a -o 'saved as your default for new sessions":" for this session only' "$BIN" | head -1; rg -a -o 'setSessionModel\(mt\),f\.setHint\(`Model set to \$\{mt\} \(session-scoped, not persisted\)`\)' "$BIN" | head -1\n\n期望输出（claude 2.1.277，已实跑）：\n1) async function l4e(e,t,n=O){let i=await ct(en("userSettings",{model:e??void 0},void 0,t),n);if(i===void 0)return p("model_set_default","un\n2) saved as your default for new sessions":" for this session only\n3) setSessionModel(mt),f.setHint(`Model set to ${mt} (session-scoped, not persisted)`)\n\n读法：第 1、2 行证明 /model 选择器路径经 l4e() 把 model 写进 userSettings(settings.json) 并提示 \"saved as your default\"；第 3 行证明 `/model <名字>`（带参数直接敲）是会话级、不落盘。注意这是「代码级」复现（从已安装二进制取证）；端到端 TUI 复现在隔离 CLAUDE_CONFIG_DIR 下被登录/OAuth 拦住（.credentials.json 拷贝不足以复现登录，keychain 探测被权限拦截），未能跑通。"
```


**审核给出的修改意见（要点）**：1) 收紧主张：把「执行 /model 不是只改当前会话，而是把选择持久化成全局默认」改为区分两条路径——(a) 无参 `/model` 交互选择器：当所选条目的 result.kind===\"saved\" 时提示 \"...and saved as your default for new sessions\" 并把 `model` 写入 `~/.claude/settings.json`（顶层标量键，故最后一个写入者胜出）；(b) 带参 `/model <name>`：`setSessionModel` + 提示 \"(session-scoped, not persisted)\"，不落盘。当前版本漏掉 (b)，属可误导的反例，必须补。\n2) 删除或降级「在几分钟内反复变/漂移」：切片只有单个 mtime，无重复观测；改为「若两会话先后保存默认，全局 model 取最后写入值」这一可证机制，而不是「反复漂移」的现象断言。\n3) 证据升级：把主证据从弱相关的 mtime 换成 CLI 代码取证（l4e 写入 userSettings + \"saved as your default\" 文案 + `/model <name>` 的 session-scoped 文案），mtime 仅作旁证并注明「不唯一指向 /model（调查会话自己也改过 settings.json

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 「表现为全局配置在几分钟内漂移」（主张）／触发器「settings.json 的 model 在几分钟内反复变」——切片只观测到单一 mtime（11:09:26），没有任何「反复变/漂移」的重复观测；产物（CLI 代码）也只证明单次标量写入，不证明多次抖动。
- 「两个会话里用 /model 切模型...互相覆盖」——覆盖语义本身由产物支持（`model` 是 settings.json 顶层标量键，`en("userSettings",{model})` 后写覆盖、无合并），但切片只呈现最终单一取值，从未出现两个冲突值，故「确实互相覆盖」在该会话里未被直接观测。

**判定**：keep-with-fix · 拟 promote-playbook · 原证据快照风险=low · 复核时本机可复跑=true
