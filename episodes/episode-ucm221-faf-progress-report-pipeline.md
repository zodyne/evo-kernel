---
id: episode-ucm221-faf-progress-report-pipeline
type: episode
status: candidate
scope: project:ucm221
domain: reporting
tags: [ucm221, faf, progress-report, matplotlib, latex, gt-eval]
triggers:
  - "要更新/再生成 UCM221 faf 过滤效果的进展汇报 PDF"
  - "faf_offline 下要做点云/航迹的 legacy vs faf 对照图"
  - "progress_report.tex / progress_plot.py 在哪、怎么重新出图"
  - "把 gt_report.tex 式的详细检测分析改成只展示结果的进展汇报"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:eaa269a8-34b2-4abf-a08f-1dd23a6ff138
last_verified: 2026-08-03
superseded_by: null
schema_version: 1
related: [episode-ucm221-faf-legacy-gate-domain-bugs, fact-ucm221-libucm221-dir-gitignored]
---
# UCM221 faf_offline 进展报告管线：progress_plot.py 出图 + gt_tables.py 出表 + progress_report.tex

## 事件

用户要求把 gt_report.tex 风格的详细检测报告简化成「只展示过滤结果与跟踪差异、丰富点云与估计显示」的项目进展汇报。本次会话在 `libucm221/src/examples/faf_offline/` 下新建了一套可复用管线：

- **数据**：`make ab` 在 `out/<DATA>/` 下产出 legacy / faf 两组 `points_in.npy / points_out.npy / tracks.npy`（本次用 000028，15 040 帧）。
- **评估**：`gt_eval.py out/<DATA>`——以人工确认过的 legacy 长命航迹为真值，用跟踪器当验证器评 faf（覆盖率/断裂/位置误差/供给率）。
- **出图**：`progress_plot.py --frames 1000,4500,11000 [--gt3d <id>]` 生成 `report/fig/p_*.pdf`（逐帧点云对照、3D 点云、3D 航迹、覆盖图等）。
- **出表**：`gt_tables.py` 把表格片段写入 `report/tab/*.tex`（meta / result / gt_set / persist / window 等）。
- **报告**：`report/progress_report.tex`（xelatex，中文），最终 5 页：摘要+规模表 / 点云变化两张 3D 图 / 航迹变化 3D 图+表 / 表 3。

## 证据

- 写文件动作：`progress_plot.py`、`report/progress_report.tex` 均为本会话产出。
- 命令佐证：`python3 progress_plot.py --frames 1000,4500,11000 --gt3d 18` →「写出 report/fig / p_*.pdf」；`gt_tables.py` →「表格片段写入 report/tab」；`latex-figure-check.sh progress_report.tex` 多轮编译通过。
- 量化结果（000028）：GT 帧 3895、覆盖 98.8%、id 1 覆盖 100.0%/断 0 次/误差 0.12 m；faf 把每帧点数从 1 905 881 进、276 435 出。

## 可复用经验

下次要更新进展汇报，直接改 `progress_plot.py` 的图或换 `--frames/--gt3d`，重跑出图 → `gt_tables.py` → xelatex 编译即可；不要从 gt_report.tex 重写。注意第 4 节（详细分析）在源文件里是注释保留的（约 117–143 行），需要时可恢复。
