---
id: searxng-zero-results-empty-unresponsive-verify-outside
type: lesson
status: candidate
scope: global
domain: self-hosted
tags: [searxng, engine-quality, silent-failure, control-experiment, troubleshooting]
triggers:
  - "SearXNG 单引擎查询返回 0 条且 unresponsive 为空（失败信号）"
  - "要判断某搜索引擎是真挂了，还是 SearXNG 侧解析/请求路径失败"
  - "逐引擎实测或质量报告里某引擎忽好忽坏，要给定性"
  - "改 SearXNG 引擎解析器（xpath/请求头）前后要做对照"
  - "拿 0 条结果直接写进引擎质量表/可否用清单"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7d3-c853-744a-939b-f6e91f2f995b
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [searxng-all-engines-fail-check-outgoing-proxy]
---

# `results: 0` + `unresponsive: []` 不等于引擎挂了：要在容器外做同参对照

**主张**：SearXNG 单引擎强制查询返回 `results: 0` 且 `unresponsive: []` 时，**不能**判"该引擎失效"——同一天用容器外 curl 经同一代理、同样 UA 打同一个站点，能正常取回 10 条结果。也就是说站点可用、失败发生在 SearXNG 这条路径上（请求构造/解析），而不是引擎本身。逐引擎质量统计必须配一份容器外对照，否则会把"SearXNG 侧静默失败"记成"引擎质量差/不可用"。

**为什么**：`unresponsive` 只覆盖 SearXNG 自己识别到的失败（超时、挂起、异常），"请求成功但解析出 0 条"落在它的盲区里——它不会报错，只会给一个和其它情况长得一样的空结果。这种沉默失败最容易被写进质量报告变成永久误判。

**证据（本会话命令 ↔ 结果）**：
- 容器内强制单引擎：`curl -s -m 30 'http://localhost:8888/search?q=DDMA+radar&format=json&engines=zapmeta'` → `results 0 unresponsive []`
- 容器外经代理直取同站：`rg -o 'organic-results-item' /tmp/zm.html | wc -l` → `10`，且能看到结果容器样本 `<article class="organic-results__item organic-results-item"> <h2 class="organic-results__title"> …`
- 进一步模拟 SearXNG 的完整请求头再打：`http=200 bytes=26282 10`（拿到 10 条）；再分别用 `--http2` / `--http1.1` 对照 → 各自 `结果条数=10`
- 反面对照：同一份引擎实测里 zapmeta 并非一直 0（`reports/…tsv` → `zapmeta en 9 OK …`），说明"0 条"是这条路径的偶发失败，不是引擎不可用

**反例/边界**：
- 切片**没有**闭合容器内 0 条的根因：容器内探针没跑通（`docker exec searxng … python3 -c 'from searx.network import get …'` 直接 Traceback），所以这是"排除法 + 容器外对照"级证据，不是根因级。
- "容器外能拿到"只能证明站点与出口链路可用，不能证明 SearXNG 的解析器没被改坏——真要归因还得修好容器内探针再打一次。

**失败信号（未来命中即该想起本条）**：看到 0 条结果就往"引擎挂了/质量差"下结论，而没做容器外同参对照；或把 `unresponsive: []` 当成"一切正常"的证明。
