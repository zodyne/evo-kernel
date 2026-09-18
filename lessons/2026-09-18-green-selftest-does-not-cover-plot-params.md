---
id: green-selftest-does-not-cover-plot-params
type: lesson
status: candidate
scope: global
domain: verification
tags: [matplotlib, figure-audit, self-test, render-params, oracle]
triggers:
  - "项目自带 demo/自检脚本 N/N 全绿，要判断它能否证明静态图/报表画对了"
  - "审查一整套静态图（fig1..figN）是否真的画对，而不是只看数值自检"
  - "自检项全过，但图注数字/坐标范围与原始数据对不上（失败信号）"
  - "决定图正确性审查要采信哪些信号：自检日志 / 图内标注 / 原始数组重算"
  - "要在只读约束下给绘图脚本补一层渲染参数核对"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7d2-d6ba-777c-a410-327560871932
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [cocoa-platform-verify-gl-render-errors, count-only-acceptance-gates-miss-value-drift]
---

## 主张

仿真脚本自带的数值自检全绿（`run_demo.py` 汇总 `76/76 项通过`）**不能**作为静态图画对了的证据：渲染层参数（vmin/vmax、坐标轴范围、帧窗口、各面板 dB 约定）不在自检断言的覆盖面内。审查图的正确性只有两条有效路径：①读回 artist 的实际参数（`ax.get_ylim()` 之类），②用原始数组重算图上的每个标注值。两者都必须由审查脚本自己做，不能引用自检日志的通过数。

## 为什么

自检项检查的是数值流水线（角度/速度/距离/检测率的断言），绘图是同一脚本跑完后的副作用，画图函数里的 `vmin=-40`、`ylim`、窗口下标、`20*np.log10(...)` 这类参数没有任何断言盯着——改坏了照样 76/76。于是「全绿」给了虚假信心，图的缺陷只能靠独立脚本读回参数+重算才能暴露（本会话里确实如此：全绿的同时独立重算在 fig6(a) 动态范围与帧窗口上给出 ✗）。

## 反例 / 边界

- 不是「自检无用」：它覆盖数值层，是必要基线（本会话用它确认了 `rd` 形状 `(8,128,512) = (rx,doppler,range)` 与 76 项数值结论）。
- 判据互补：`count-only-acceptance-gates-miss-value-drift` 讲「计数闸门对数值退化失明」，本条讲「数值自检对渲染参数失明」——盲区在另一个维度；`cocoa-platform-verify-gl-render-errors` 是同构现象（offscreen pytest 全绿 ≠ 真实 GL 渲染无错），但那条的验证手段是换平台跑窗口冒烟，本条是读回绘图参数+重算数据。
- 若项目已把图内容纳入断言（例如渲染后对像素/artist 数据做断言），本条不适用。

## 证据

session 01a0a7d2 核验切片：

- 自检：`python3 bpm_2t8r_sim/run_demo.py` → `305 /tmp/run_demo.log … 76/76 项通过`，8 张图已刷新。
- 独立重算脚本（/tmp/vf/，与 run_demo 无关地重建数据后对照渲染参数）在同一状态下给出：
  - `✗ fig6(a) 图像动态范围: max=0.00 dB p50=-26.09 p90=-25.44 p99=-2.22 min=-26.68 -> vmin=-40 时，底噪距下界还有 -13.9 dB`
  - `✗ 帧起点(ms): [0. 7.68 15.36 23.04 30.72 38.4 46.08 53.76] fig6(a): i_lo=47(35.23m) i_hi=147(109.42m) ylim=(35,110)`
  - 读回 artist 参数：`fig2(a) 坐标轴实际 ylim = (np.float64(-23.898452924360797), np.float64(15.969058487215909))`
