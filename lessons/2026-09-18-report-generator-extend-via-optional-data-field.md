---
id: report-generator-extend-via-optional-data-field
type: lesson
status: candidate
scope: global
domain: document-processing
tags: [report-generator, optional-field, data-driven, backward-compatible, openpyxl, weekly-report]
triggers:
  - "给既有的周报/周期报表生成器加一类新展示信息（延期标注、状态徽标、新列）"
  - "只有某一期的个别条目需要特殊标注，第一反应是在渲染函数里写死这一期的例外"
  - "生成器的数据文件（YAML/JSON）按周/按期追加字段，旧期条目里没有这个字段（失败信号：渲染旧期 KeyError 或被迫回填旧数据）"
  - "渲染代码里开始出现 if week == 'W39' 这类按期硬编码（失败信号）"
  - "改完生成器后拿不准要不要重出/迁移往期报表"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b320-f54d-7528-b53f-009d31ed83ce
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [episode-suc221-faf-progress-report-pipeline, generated-report-exact-match-patch-breaks]
---

**主张**：给周期报表生成器加新展示信息时，把它做成**数据文件里的可选字段 + 渲染层透传**（`view()` 透传 `rescheduled`，`timeline()` 的 `due` 分支见到该字段才追加一行），而不是把"本期有延期"这类例外写进渲染代码。

**为什么**：周期报表的渲染器是长期复用的、数据文件按期追加——把某一起事实写进渲染代码（按期 `if` / 硬编码文案），下期就得加第二个分支，且任何渲染改动都会影响往期重出。做成可选字段后，事实留在数据层、渲染层只有一条通用分支；未携带该字段的条目走原路径。本次产物里 `⚠ 延期 1 周（原节点 W39）` 中的"原节点 W39"是历史事实，渲染层无从推断，只能来自数据文件。

**反例 / 边界**
- 若新信息**可由已有字段推导**（例如"计划完成日早于本期即逾期"，纯规则计算），就不该新增冗余字段，而应把规则写成通用条件；本条针对的是无法推导的例外事实（顺延后批准的新节点）。
- 字段一旦进入数据文件就带上"谁在什么口径下填"的约定；缺失时渲染层必须保持原样输出，不能报错或补默认文案。
- 与 `generated-report-exact-match-patch-breaks` 互补：那条讲"别用精确匹配去补生成物"，本条讲"要加内容就回到生成器 + 数据文件这一侧"。

**证据**
- 渲染逻辑在代码、日期事实在数据：`rg -n '延期|逾期|overdue|剩余|历时|计划完成' scripts/gen_weekly_report_v2.py` → `482: 本周末 = 提出日、下周末 = 计划完成日（如 09-11 提出 + 1 周 → 09-18）。`、`672: """时间节点：提出日(该周末) → 计划完成 / 最近更新 …`。
- 生成器按期参数化：`rg -n 'add_argument|def main|OUT_DIR|args.week'` → `42: OUT_DIR = WORKSPACE / "reports"`、`821: def main():`、`823: parser.add_argument("--week", require…`。
- 加字段后整表生成成功：`python3 scripts/gen_weekly_report_v2.py --week W39` → `✅ 已生成: …/无人机避障雷达_W39_周报.xlsx   Sheet 1: 进度与问题追踪 (12 项)`（12 条条目里多数不带该字段，仍整表渲染完成）。
- 回读本期产物：`P08 时间节点 → '09-11(W38) 提出 → 09-25(W40) 计划完成\n⚠ 延期 1 周（原节点 W39）'` —— 新字段的渲染结果可见，且"原节点"这一历史事实与数据侧一致。
- 改动面只有数据 + 生成器：切片「写/改文件」只列出 `scripts/gen_weekly_report_v2.py` 与 `state/suc221-weekly-data-v2.yaml`（未改模板，也未手改 xlsx）。
- 末条 assistant 自述改动 1 为 "`view()` 透传新增可选字段 `rescheduled`；`timeline()` 在 `due` 分支下，若存在 `rescheduled` …"（切片在此截断）；机制以上面的产物回读为准，自述仅作索引。
