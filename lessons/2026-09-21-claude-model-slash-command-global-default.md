---
id: claude-model-slash-command-global-default
type: lesson
status: candidate
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
