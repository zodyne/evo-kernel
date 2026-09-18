---
id: pi-extension-tool-details-verify-via-mode-json
type: lesson
status: candidate
scope: global
domain: agent-harness
tags: [pi, extension, verification, headless, json-mode]
triggers:
  - "验证 pi 扩展注册的工具实际返回了哪些字段"
  - "用 pi -p 让模型复述工具 details，字段值可疑（失败信号：unknown / none）"
  - "排查 pi 扩展的降级/兜底逻辑到底有没有生效"
  - "headless 脚本化冒烟测试 pi 扩展工具"
  - "拿模型复述的一行输出当扩展行为证据"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7d3-c853-744a-939b-f6e91f2f995b
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pi-extension-command-print-json-mode-unavailable]
---

# 验证 pi 扩展工具返回什么，要用 `--mode json` 取原始事件，别让模型在纯文本里转述

**主张**：headless 验收 pi 扩展工具时，必须跑 `pi -p --mode json` 并从原始事件流里 grep 目标字段；用纯文本 `-p` 让模型把 details"复述成一行"，拿到的是模型的转述而不是工具的真实返回。同一份 `web_search` 实现，纯文本轮给出 `enginesPinned=unknown engines=… degraded=none`，而 JSON 流里实际是 `"enginesPinned":true` + `"degraded":["brave(too many requests)","sogou(Suspended: CAPTCHA)"]` —— 按前者验收会把"降级逻辑已生效"误判成"没生效"。

**为什么**：`-p` 文本模式下工具 details 是否完整进入模型上下文、模型是否照抄，都不受控；模型完全可能概括、省略或按 prompt 里的措辞倒推填空。验收脚本要的是可机器判读的事实，只能来自事件流本身。这与"让模型复述日志当证据"是同一类错误。

**证据（本会话命令 ↔ 结果）**：
- 纯文本轮：`pi -p --no-session "Use the web_search tool exactly once with query 'DDMA radar velocity ambiguity', then reply with only this one line: en…"`
  → `enginesPinned=unknown engines=360search,bing,yandex degraded=none`
- JSON 轮：`pi -p --no-session --mode json "Call web_search once with query 'CFAR detection radar' and nothing else." 2>&1 | rg -o '"enginesPinned":(tr…`
  → `"degraded":["brave(too many requests)","sogou(Suspended: CAPTCHA)"] "enginesPinned":true "engines":["bing","360search",…`
- 对照前提：两轮之前已用 mock harness 确认工具注册与 schema 正常（`工具已注册: web_search | 参数 schema: [ 'query', 'max_results', 'language' ]`），排除"工具没生效"这一解释

**反例/边界**：
- 切片没闭合"纯文本轮为什么丢字段"（prompt 表述导致模型没读到 details、还是模型自己填了 `unknown`，无从判定）。本条只主张"别拿复述当验收证据"，不主张同一查询在两轮里真实返回不一致。
- 两轮问的 query 不同（DDMA vs CFAR），不能拿两轮的 engines 列表互相当对照。

**失败信号（未来命中即该想起本条）**：headless 冒烟里出现 `unknown` / `none` / `N/A` 这类"模型自述值"却没人去 JSON 流里核；或验收脚本靠 grep 模型回复文本判断扩展行为。
