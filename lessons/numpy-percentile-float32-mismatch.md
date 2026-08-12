---
id: numpy-percentile-float32-mismatch
type: lesson
status: candidate
scope: global
domain: numerical
tags: [numpy, float32, percentile, cross-language-verification]
triggers:
  - 用 np.percentile / np.quantile 算自适应阈值并与 C 实现比对
  - C 侧分位数与 numpy 参照对不上，差在 1e-7 量级但判定边界被跨过
  - 对 float32 数组直接调 np.percentile
  - 跨语言数值一致性验证里分位数/百分位系统性地差最后几位
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:da720f38-036f-42ec-820d-ce8538a4fc1f
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [dual-impl-cross-check-tolerance-grid-anchored]
---

# np.percentile 对 float32 输入按 float32 计算：与 float64 参照实现系统性不一致

`np.percentile` 的插值（`_lerp`）跟随输入 dtype：float32 数组进去，中间量和结果都是 float32。同一组数据用 float64 路径（或 C 侧 double 实现）算出的分位数会在 1e-7 量级上不同——对「点数 × 阈值比较」这种逐点判定，边界点会被翻转。

**实测**（session da720f38，numpy 2.3.4）：手写的 linear 分位数实现与 np.percentile 对拍，float64 路径 0 处 mismatch，**float32 路径 2657 处 mismatch**（p90/p95 上 `np.float32(2.4119332)` vs `np.float32(2.4119334)` 这类最后几位差异）。

**处置**：做 C↔Python 或跨实现的分位数比对前，统一 `a = np.asarray(a, dtype=np.float64)` 再算 percentile；比阈值本身时，把参照阈值也 `np.float32(参照值)` 对齐到 C 侧存储精度，否则 1e-8 级差会掩盖真正的档位不匹配。
