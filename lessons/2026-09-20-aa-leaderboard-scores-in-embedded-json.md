---
id: aa-leaderboard-scores-in-embedded-json
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [artificialanalysis, html-extraction, embedded-json, curl, benchmark-research]
triggers:
  - "要抓 artificialanalysis.ai 榜单/模型页的分数（Intelligence Index、价格、tok/s）做模型对比"
  - "grep/rg 模型展示名在 AA 页面里 0 命中或只命中 CSS，据此下『页面没这个数据』的结论（失败信号）"
  - "从 Next.js 页面内嵌 JSON 里提数，正则因为引号被反斜杠转义而匹配不上（失败信号：肉眼在页面里能看到却搜不到）"
  - "调研报告要给出可复现的第三方评测分数提取路径"
  - "按模型展示名在榜单页里搜不到分，准备改抓另一个页面/改问别人（失败信号：其实是转义问题）"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b965-0941-75eb-8af3-647a9ae53e12
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [arxiv-html-fulltext-grep-sed-eval-extraction, benchmark-index-version-caliber-mixing]
---

# AA 榜单分数藏在内嵌 JSON 里且引号被转义：先 `.replace('\\"','"')`，再按 label + metric 键配对取分

**主张**：artificialanalysis.ai 的分数（`intelligenceIndex` / `answerCost` 等）不在可见文本里，而在页面内嵌的 Next.js 数据块中，且块内引号被反斜杠转义。可复现的提数路径是：`curl` 下载整页到本地文件 → Python 读入后先 `.replace('\\"','"')` 反转义 → 按 `{"label":"<模型名>","<metric>":<数值>,...}` 的 **label + metric 键**配对取分；拿不到展示名时改抓 `https://artificialanalysis.ai/models/<slug>` 详情页。直接在原始 HTML 上 grep 模型展示名只会得到 0 命中或 CSS 噪声，据此判断「页面没有该模型数据」是错的。

**为什么**：页面是 JS 渲染，分数存在于 flight/RSC JSON 中（形如 `"label":"GLM-5.3 (max)","intelligenceIndex":44.777…`），转义后 raw 文本里是 `\"label\":\"…`，所以不带反转义的 `grep 'GLM-5.3 (max)'` 匹配不到；同时模型在 JSON 里可能只以 slug 出现（如 `deepseek-v4-1-flash`），展示名与 slug 两套键都要试。

**证据**（本会话切片，命令 ↔ 结果）：

1. `curl -sL --max-time 25 "https://artificialanalysis.ai/leaderboards/models" …` → `http=200 size=1984409`，raw 文本里 `GLM-5.3: 3 命中`，命中处是 CSS（`al-200));min-width:200px;…`），不是分数。
2. 在**未反转义**的 HTML 里逐个搜展示名 → 输出只剩三个空标题后接页面噪声：`===== DeepSeek V4.1 Flash ===== ===== DeepSeek V4 Pro 0813 ===== ===== GLM-5.3 (max) =====`，即 0 命中。
3. 同页 `intelligenceIndex 出现次数: 804`，而 `intelligence_index 出现次数: 0` —— 键名是驼峰。
4. 反转义后 `label` 与 `intelligenceIndex` 成对出现：`{"label":"GLM-5.3 (max)","intelligenceIndex":44.777392385614,"detailsUrl":"/models/glm-5-3"},{"label":"Grok 4.6 (high)",…`。
5. 换 metric 键同样可用：`=== answerCost ===    GLM-5.3-Flash 14.6124945 / GLM-5.2 (max) 88.9268952 / Deep…`；可用指标键能从 `图表指标: ['aaBriefcaseElo', 'activeParams', 'allModels', 'answer', 'answerCost', 'answerTime', 'artificialAnalysisIntellige…` 里列出来。
6. 详情页同样内嵌分数：`https://artificialanalysis.ai/models/<slug>` 抓回后 `deepseek-v4-1-flash: 29 处  ✓ ?  idx=37.32  (pos 85309)`，单页约 3.9MB。

**边界 / 反例**：

- 同一页面里同名 metric 出现几百次（多图表/多序列），必须按 label 精确配对；不要取「第一个出现的 `intelligenceIndex`」。
- 页面体积大（榜单 ~2MB、详情页 ~3.9MB），不要整份读进上下文；用 Python 定位偏移后再截段。
- 本条只覆盖 2026-09 观测到的 AA 页面形态；站点改版后键名/转义形式可能变，批量提数前先用一个已知模型（如 GLM-5.3 (max)）验证提取路径仍通。
- 上列分数只是提取路径的示例，不构成对模型能力的结论；引用时的版本口径问题另见 related 条目。
