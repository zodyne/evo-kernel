---
id: cfar-vectorization-exact-equality-gate
type: lesson
status: candidate
scope: global
domain: signal-processing
tags: [cfar, vectorization, equivalence, oracle, regression-assertion, radar, numpy]
triggers:
  - "把逐单元检测算法（CFAR/峰值判决类）从 for 循环重写成 numpy 向量化，准备删掉旧循环"
  - "向量化实现与逐点参考实现在真实帧上结果对不上（失败信号：mask / 命中集合差一个单元）"
  - "给向量化重构选验收判据：二值判决输出到底该用浮点容差还是精确相等"
  - "只有合成矩阵（单一已知点）的对拍通过就宣布向量化等价（失败信号：样本里只有 1 个命中，边界分支没被覆盖）"
  - "交付的检测模块里要不要保留慢速参考实现（对拍 / 回归 / 性能基线用）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a80b-0e2d-7719-ba82-31f30746aeba
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [cfar-cross-lib-equivalence-baseline-first, dual-impl-cross-check-tolerance-grid-anchored]
---
# CFAR 向量化：把逐点参考实现留在交付模块里，用「mask + 命中集合完全相等」当验收闸门

## 主张
把 CFAR 这类**逐单元检测**算法从逐点循环改成向量化实现时，不要删掉慢循环——把它以私有名留在交付模块里
（本会话为 `spc865.detect._ca_cfar_reference_loop`），用**同一输入下 mask 与命中集合逐点完全相等**作为向量化版本的验收判据；
且要**两级取样**：先在合成矩阵（已知位置强点）上对，再在**真实 RD 帧**上对。两次都相等才允许宣布等价。
二值判决输出（选/不选）用**精确集合相等**，不用浮点容差——容差会放过"边界单元差一个"的真差异。
顺带在同一探针里记录两条实现耗时，把"向量化收益"变成数字而不是感觉。

## 为什么
逐点循环是照着 MATLAB/参考实现逐行抄下来的"本该正确"版本，向量化版本（切片/广播/整块比较）最容易在**窗口边界与
引用单元裁剪**上出 off-by-one；这类差异只体现在少数单元上，肉眼看谱图看不出来，而检测输出是二值的——
差一个单元就是"漏检/虚警一个点"，没有"差得不多"这种中间状态。
合成矩阵通常只放 1 个强点，覆盖不到边界分支；真实帧有多个命中、且噪声底形状来自实际链路，是合成样本补不上的第二级样本。
把参考实现留在模块里（而不是只留在本地临时脚本），后续改窗口参数/加保护窗时随时可重跑同一道闸门。

## 证据（本会话命令 ↔ 结果）
- 合成矩阵对拍：
  `python3 -c "import numpy as np, time; from spc865.detect import _ca_cfar_reference_loop, ca_cfar_baseline, caso_noise_db …"`
  → `loop 0.01s mask equal: True nnz 1 1 hit set equal: True top hit: CfarHit(range_index_1based=11, doppler_index_1based=21, …`
  （参考循环与向量化版本 mask 相等、命中集合相等；合成样本只有 1 个命中，`nnz 1 1`）
- 真实帧对拍（20 帧、512×64 探测矩阵）：
  `python3 -c "… from spc865.io import BinFile, load_frame; from spc865.dsp import compute_beam_products …"`
  → `frames 20 detmatrix (512, 64) finite True 93.2051942663591 132.31416474241394 equal True nnz 7 loop 0.11s vec 0.002s hit…`
  （真实数据上仍然 `equal True`，7 个命中；同一输入 loop 0.11s vs vec 0.002s ≈ 55×，是向量化的收益证据）
- 交付形态：`wc -l spc865/detect.py …` → `440 spc865/detect.py`，且 `_ca_cfar_reference_loop` 可从模块直接 import
  （参考实现确实留在了交付件里，不是一次性脚本）。同车道 `pytest tests/python/test_detect.py tests/python/test_metrics.py -q`
  → `.......................... [100%]`（26 通过）、`real 0m1.398s`，闸门可日常重跑。

## 边界 / 反例
- **只对最终二值判决要求精确相等**：中间连续量（噪声估计 `caso_noise_db`、SNR）是浮点，改成向量化后累加次序变化可能末位不同，
  这类量要用容差 + 差异集归因，不能套用本条（参考 `cfar-cross-lib-equivalence-baseline-first`：先建可归因的等价基准）。
- 若向量化**故意改变语义**（换窗口裁剪口径、换保护窗），集合相等本就不该成立，此时该做的是逐点差异集分析并写明口径变更，不是硬凑相等。
- 合成样本只有 1 个命中时，`mask equal: True` 的判别力很弱（边界分支没被触发）；真实帧样本（本会话 7 个命中）才是主证据。
- 参考实现留在生产模块里有维护成本（两条实现要同步改）；若算法会持续演进，应把参考实现标注为"仅供对拍/性能基线"并加测试绑定，避免它腐烂成误导。

## 失败信号（未来命中即该想起本条）
- 全量/车道测试全绿，但向量化版本与逐点循环从未在同一输入上比对过——"绿"只证明了两条路径各自自洽。
- 对拍只跑过合成矩阵（1 个峰、`nnz 1`），就宣布向量化等价。
- 为了消除向量化/参考实现的差异去放宽断言（改成容差、改成只比命中数）——先看差的是不是边界单元。
