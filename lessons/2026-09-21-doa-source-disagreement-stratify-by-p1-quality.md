---
id: doa-source-disagreement-stratify-by-p1-quality
type: lesson
status: candidate
scope: global
domain: signal-processing
tags: [doa, cross-check, stratification, p1, evaluation, radar, suc221]
triggers:
  - "对拍两套测角/估计器输出（闭式解 vs FPGA/参考实现）"
  - "KEEP 点里角度差大的比例看起来很高，要判估计器是否有问题"
  - "点云/快拍估计器带质量指标（p1 相干能量占比、SNR、拟合残差）可用"
  - "对拍报告只在全体/KEEP 上算差异占比，没有按质量分层（失败信号）"
  - "准备用一次对拍结论宣布某套测角链路不可信"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bcf1-4733-7265-ada1-fb36116f6be1
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [dual-impl-cross-check-tolerance-grid-anchored, suc221-cross-angle-dataset-record]
---

# 测角对拍的分歧比例必须按 p1 分层：KEEP 全体 5% vs 高质量点 0.44%

## 主张

对拍两套测角输出时，分歧比例要按点质量（p1）分层报告；只看 KEEP 全体会把低质量点主导的分歧误读成估计器缺陷。本例 `compare_angles.py` 输出：十字测角 |Δaz|>2° 在 KEEP 全体占 5.01%、在 p1>0.98 子集只占 0.44%（|Δaz|>45° 从 3.04% 降到 0.00%）；000028 上 10.77% → 6.46%。

## 为什么

KEEP/MARGINAL 判定放行的点里混着大量低 p1 点，两套估计器在低相干能量点上分歧本来就会放大；不分层时，"KEEP 点 5%~10% 的角度大偏差"看起来像参考链路失锁或估计器坏了。按 p1 分层后，高质量子集的分歧降一个量级（十字测角 5.01%→0.44%），能把"估计器系统性错误"与"低质量点各估各的"分开。反过来，分层后仍高的子集（000028 的 6.46%）才是要继续查的对象。

## 证据（session 01a0bcf1，suc221-pointcloud-2.0）

- 工具（本会话新增 `python/compare_angles.py`）与运行：`python3 python/compare_angles.py -i data/十字测角 --rubric` →
  `④ 判决影响：KEEP 点里角度差大的占多少（这些是可能被失锁污染的"输出"）  |Δaz| > 2.0°：KEEP 点 5.01%  p1>0.98 点 0.44%`；
  另一轮同口径输出 `|Δaz| > 45.0°：KEEP 点 3.04%  p1>0.98 点 0.00%`。
- 第二个场景：`for s in 000028 000034; do … compare_angles.py -i data/$s …` → `000028 … |Δaz| > 2.0°：KEEP 点 10.77%  p1>0.98 点 6.46%`。
- 查看器侧自检同口径：启动输出 `测角（闭式解）：高质量点 n=226（p1>0.98）上两份之差 Δ…`。

## 边界 / 反例

- 切片未展示 `compare_angles.py` 的源码与两套角度的具体来源；主张限定在"分歧比例随 p1 分层"这一观测与报告口径，不代拟比对链路。
- p1 是本项目现成的质量量；换领域用对应的置信/质量协变量（SNR、相干性、拟合残差），原则相同。
- 分层是定位手段，不是免责声明：000028 上 p1>0.98 子集仍有 6.46% 大偏差，不能据此宣布估计器没问题。
- 与 `dual-impl-cross-check-tolerance-grid-anchored` 互补：那条管"通过判据锚定数值分辨率"，本条管"分歧统计按质量协变量分层"。

## 失败信号（未来命中即该想起本条）

- 对拍报告只给 KEEP/全体上的差异占比，没有高质量子集对照。
- 看到 KEEP 上 ~10% 的角度大偏差就判"某套测角坏了"，没排除低 p1 点的贡献。

## 2026-09-22 独立复核增补

下列是复核时在本机跑过的**自包含最小复现**：

```
cd /Users/zodyne/Dev/suc221-pointcloud-2.0 && python3 -W ignore python/compare_angles.py -i data/十字测角 --rubric | grep "Δaz" ; echo "--- 000028 ---" ; python3 -W ignore python/compare_angles.py -i data/000028 | grep -A3 "④ 判决影响"

# 期望输出（本机 2026-09-22 实跑，与切片逐字一致）:
#   |Δaz| >  2.0°：KEEP 点  5.01%   p1>0.98 点  0.44%
#   |Δaz| > 10.0°：KEEP 点  3.39%   p1>0.98 点  0.00%
#   |Δaz| > 45.0°：KEEP 点  3.04%   p1>0.98 点  0.00%
#   --- 000028 ---
#   |Δaz| >  2.0°：KEEP 点 10.77%   p1>0.98 点  6.46%
# （另 ③「差 vs 质量」分箱显示 |Δaz| 中位从低 p1 的 67° 单调降到高 p1 的 0.55°，正是「为什么」节机制的实测依据）
```


**审核给出的修改意见（要点）**：无

**判定**：keep · 拟 keep-lessons · 原证据快照风险=high · 复核时本机可复跑=true
