---
id: tikz-redraw-curve-digitize-from-pixels
type: lesson
status: candidate
scope: global
domain: latex
tags: [tikz, figure-reproduction, digitize, pixel-trace, curve-extraction]
triggers:
  - "重绘扫描书示意图，图里有平滑曲线（分界线/包络）没有数据文件"
  - "TikZ 重绘曲线要坐标点，手目测描点误差大"
  - "扫描图曲线重绘后形状不像/位置偏（失败信号）"
  - "需要从位图里提取曲线的像素坐标再映射回图内坐标系"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae0f-e727-74bd-bb26-429f7e3cf7df
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [tikz-figure-reproduction-raster-diff-verification]
---

重绘扫描示意图中的平滑曲线（分界线/包络）时，不目测描点，直接从位图逐像素数字化：对每列 x 找暗像素 run 取中点得到像素轨迹，按墨水 bbox 线性映射回图内数据坐标，生成 TikZ `\draw plot coordinates` 点列。

为什么：目测描点误差大且不可复核；像素轨迹列级中点 + 坐标映射是确定性提取，产出的点列可回贴进验证比对。

反例/边界：若曲线与文字/坐标轴相交，需先排除轴向列/文字区域再取 run（本会话先定位横轴行、纵轴列，明确排除后逐列 trace）；拟合 A/B/k 参数化（A≈309, k≈0.019）在文字遮挡段出现 maxerr 48.66px 的假吻合，废弃，逐列直接取点更稳。

证据：`mkdir -p tikz/out && python3 - <<'PY'`（逐列暗像素 run 取中点，输出 up1 n=19 pts 坐标列）→ 用该点列写 `tikz/fig3-1.tex`/`fig3-2.tex` → 最终曲线像素级复核「fig3-1 上曲线 max|d|=1.5px, 下曲线 max|d|=1.5px」。
