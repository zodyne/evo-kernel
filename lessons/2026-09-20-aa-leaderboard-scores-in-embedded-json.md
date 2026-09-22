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

## 2026-09-22 独立复核增补

下列是复核时在本机跑过的**自包含最小复现**：

```
curl -sL --max-time 25 "https://artificialanalysis.ai/models/claude-fable-5-1" -H 'user-agent: Mozilla/5.0' -o /tmp/aa.html
python3 - <<'PY'
import re
t = open('/tmp/aa.html', encoding='utf-8', errors='ignore').read()
r = r'\{"label":"([^"]{1,40})","intelligenceIndex":([0-9.]+)'
print("RAW   (no unescape) label+idx pairs:", len(re.findall(r, t)))
print("UNESC (replace escaped quotes)  pairs:", len(re.findall(r, t.replace('\\"','"'))))
print("raw grep of display name count:    ", t.count('Claude Fable 5.1 (max with fallback)'))
PY
# 期望输出（2026-09-22 实测）：
#   RAW   (no unescape) label+idx pairs: 40
#   UNESC (replace escaped quotes)  pairs: 40      <- 反转义一步零收益
#   raw grep of display name count:      24        <- 展示名 raw 可 grep
# 结论：条目主张的『必须先 .replace 反转义』与『grep 展示名只会 0 命中』在现网详情页均不成立。
# 另证榜单页走的是另一套：模型数据在反斜杠转义的 blob 里、键为 name/slug（非 label），
#   raw 里同时有服务端渲染的 <td>GLM-5.3 (max)</div> 与散文 '…2. GLM-5.3 (max) (45)…'，
#   故 {@code {"label":..,"intelligenceIndex":..}} 配型在榜单页命中 0 条。
```


**审核给出的修改意见（要点）**：主张的两根承重柱已被现网推翻，必须改写后留（不能原样 keep）：  1) 标题/主张里的『块内引号被反斜杠转义，**必须先** .replace('\\"','\"')』——现网详情页 /models/<slug> 的分数是**未转义的纯 JSON**（`"data":[{"label":"…","intelligenceIndex":53.35…,"detailsUrl":…}]`），raw 直接 grep 即中；反转义前后配对数都是 40（零收益）。改写为：『分数在内嵌 JSON script 块里；转义与否随页面/版本而异（2026-09-19 观测为转义，2026-09-22 详情页为纯 JSON），故先试 raw、不中再试反转义』——去掉『必须』。  2) 失败信号『直接 grep 模型展示名只会得到 0 命中或 CSS 噪声』——已 falsify：现网详情页展示名 raw 命中 24 次、榜单页 'GLM-5.3 (max)' 命中 8 次（服务端渲染的 <td> + 散文）。改写为：『grep 展示名可能命中（渲染表/散文）也可能 0 命中，两者都不足以判定数据在不在；判据是内嵌 JSON 块，而不是 grep 结果』。相应地把 triggers 里两条『grep 0 命中 → 页面没这数据』的失败信号删掉/重写——否则召回时会把人引向一个**已失效**的判据。 

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 「页面是 JS 渲染，分数存在于 flight/RSC JSON 中」——切片里会话自己只把这个当假设写（命令标题 '尝试抓 AA 榜单（可能 JS 渲染）'），条目却升格成事实陈述；且 flight/RSC 这个术语切片里根本没有。现网复测：榜单页的模型表其实是服务端渲染的（`<td …>GLM-5.3 (max)</div>` 直接出现在 HTML 里），『JS 渲染/只在 RSC 里』并不成立。

**判定**：rewrite-claim · 拟 keep-lessons · 原证据快照风险=high · 复核时本机可复跑=true
