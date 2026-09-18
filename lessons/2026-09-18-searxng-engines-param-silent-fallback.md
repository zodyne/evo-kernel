---
id: searxng-engines-param-silent-fallback
type: lesson
status: candidate
scope: global
domain: self-hosted
tags: [searxng, engines, degraded, silent-failure, api-contract]
triggers:
  - "给 SearXNG 传 engines= 想只从一个/几个引擎取结果"
  - "钉死的引擎挂起或名字写错，查询却仍返回结果（失败信号：total 大于 0 但结果不来自该引擎）"
  - "写 pi 扩展/脚本封装 SearXNG，要判断返回是否降级"
  - "以为 engines= 是硬约束，据此断言某引擎的质量或可用性"
  - "响应里的 engines / unresponsive / degraded 字段该不该上报给调用方"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7d3-c853-744a-939b-f6e91f2f995b
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# SearXNG 的 `engines=` 不是硬约束：引擎非法或挂起时静默回退到其他引擎

**主张**：SearXNG 的 `engines=` 参数只是"期望"，不是硬约束——钉死的引擎名非法、或该引擎被挂起（Suspended / too many requests / CAPTCHA）时，它照样返回**其他引擎**的结果（`total > 0`），只在响应里留 `engines`（实际用了谁）与线索字段。调用方若只看条数/`total` 就会把"降级后的杂牌结果"当成"钉死引擎的结果"。封装层必须回读并**显式上报降级**（本会话的 pi 扩展即新增 `degraded` / `enginesPinned` 字段，CI 冒烟也按它判据）。

**为什么**：这是个"只要不检查就永远看不见"的静默降级。下游拿它做引擎质量评估、或把结果当成某个来源（如"这是 brave 的结果"）继续推理，结论会系统性偏。

**证据（本会话命令 ↔ 结果）**：
- 用非法引擎名钉死（改 mock 扩展里的 `PINNED_ENGINES`）：
  `sed 's/^const PINNED_ENGINES = .*/const PINNED_ENGINES = "definitely-not-an-engine";/'` → `24:const PINNED_ENGINES = "definitely-not-an-engine";`
  实跑 → `回退用例 details: {"total":8,"engines":["360search","bing","yandex"],…`（引擎名非法，仍出 8 条）
- 钉死一个正在挂起的引擎：`PINNED_ENGINES = "brave"` → `details: {"total":8,"engines":["360search","bing","yandex"],"degraded":["brave(Suspended: too many requests)"]}`
- 真实链路同样如此：`pi -p --no-session --mode json "Call web_search once …"` → `"degraded":["brave(too many requests)","sogou(Suspended: CAPTCHA)"] "enginesPinned":true "engines":["bing","360search",…`

**反例/边界**：
- 引擎合法且健康时 `engines=` 是被遵守的：`curl '…&engines=brave,yandex,z…'` → `results: 33 engines: Counter({'brave': 20, 'yandex': 13})`。本条只针对"钉死的引擎不可用/名字非法"这一支。
- 切片证明的是"出现了回退 + 降级字段被带上"，未证明 SearXNG 各版本的回退策略完全一致；跨版本升级后要重跑一次这个用例。

**失败信号（未来命中即该想起本条）**：钉死单引擎却返回了非零结果、而你没核对 `engines` 里到底是谁；或封装层从不向上报 `degraded`，让调用方以为拿到的是指定引擎的结果。
