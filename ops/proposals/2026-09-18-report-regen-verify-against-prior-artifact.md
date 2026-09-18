---
id: report-regen-verify-against-prior-artifact
type: lesson
status: candidate
scope: global
domain: verification
tags: [openpyxl, xlsx, artifact-verification, baseline, reparse, periodic-report]
triggers:
  - "改完周报/周期报表生成器并成功生成新一期产物，准备收工"
  - "生成器打印了 ✅ 已生成 / Sheet 1: N 项，就想据此宣告产物没问题（失败信号）"
  - "需要判断新一期报表有没有静默版式漂移：合并单元格丢失、行高塌陷、尾部行数异常"
  - "手上已有上一期产物文件，想拿它当结构基线做跨期对差"
  - "产物是 xlsx/pdf 这类二进制格式，git diff 看不到内容变化"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b320-f54d-7528-b53f-009d31ed83ce
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [docx-batch-edit-verify-by-redump, rebuild-pdf-verify-against-head-version, green-selftest-does-not-cover-plot-params]
---

**主张**：改周期报表生成器后的验收闭环是「**上一期产物取基线 → 生成 → 用 openpyxl 把新一期产物逐项读回对差**」（读回 sheet 名 / dims / 合并区 / 字体 / 表头 / 单元格文本 / 行高 / max_row）；生成器自己打印的 `✅ 已生成 / Sheet 1: N 项` 只证明它跑通，不是产物正确的证据。

**为什么**：生成器的成功日志覆盖"跑通 + 条目数"，版式层（合并区、行高、往期格式、尾部追加行）不在任何断言里；而"本期相对上一期有没有静默漂移"只有拿上一期产物当基线才回答得了——二进制产物 git diff 无从看内容。本次会话按此闭环执行：改生成器**前**读 W38 建基线，改完生成 W39 后**再**逐项读回核对。

**反例 / 边界**
- 与 `docx-batch-edit-verify-by-redump` 分工：那条是"一次性批量替换后回读，防把文件写坏"；本条针对"周期重出"，基线来自上一期产物，问的是跨期一致性/漂移。
- 与 `green-selftest-does-not-cover-plot-params` 同构但盲区不同：那条讲数值自检对绘图参数失明，本条讲生成器成功日志对表格版式失明。
- 若产物是纯文本且进了 git（md/csv），跨期 diff 直接可读，不必叠 openpyxl 基线法。
- 行高/字体这类版式项只在"产物给人看"时是验收项；做纯数据管道时可只对数值单元格。
- 与 `rebuild-pdf-verify-against-head-version` 同族：那条是"重建 PDF 与 HEAD 版本对差"，本条是"周期产物与上一期对差"。

**证据**
- 改前基线（上一期 W38 产物，改生成器之前执行）：
  - `sheets: ['进度与问题追踪', '历史沉淀']`
  - dims → `进度与问题追踪 A1:F41 41 6`、`历史沉淀 A1:E65 65 5`
  - merged → `A41:F41 A2:F2 A28:F28 A36:F36 A17:A18 A1:F1 A5:F5 A9:F9`
  - 样式 → `{'coord': 'A1', 'font': ('微软雅黑', 14.0, True, '001F3864'), 'fill': (None, '00000000'), 'align': ('center', 'center', None…)}`
  - 历史沉淀表头 → `模块 | 任务 | 周次 | 工作内容 | 状态`
- 生成：`python3 scripts/gen_weekly_report_v2.py --week W39` → `✅ 已生成: …/无人机避障雷达_W39_周报.xlsx   Sheet 1: 进度与问题追踪 (12 项)`
- 生成后回读本期产物：
  - `P08 时间节点 → '09-11(W38) 提出 → 09-25(W40) 计划完成\n⚠ 延期 1 周（原节点 W39）'`
  - `P08 行高 → 173.0`
  - `历史沉淀 max_row = 69`（基线 W38 为 65），末三行/第 63、64 行内容被逐条读出核对
- 不计入证据的一步：切片里 `=== YAML 校验 + 变更核对 ===` 那条命令链带 `✗`（非零退出码），因此不引用它作为"数据文件校验通过"的证据；本条只采信产物层的读回结果。
