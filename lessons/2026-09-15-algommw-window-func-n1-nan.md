---
id: algommw-window-func-n1-nan
type: lesson
status: candidate
scope: project:algommw
domain: dsp
tags: [window, nan, edge-case, algommw, c]
triggers:
  - "使用/测试 algommw 净室窗函数（hann/hamming/blackman），窗长参数可能取 N=1 等退化值"
  - "窗函数输出出现 NaN，怀疑窗长边界条件未防护"
  - "验证 C 窗函数数值正确性，扫边界窗长 N=1/N=2 时 isnan"
  - "移植/重写窗函数实现，想确认退化窗长是否有除零防护"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a6e5-dd7a-7353-8a3d-42ec3686d5d9
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [mmw-cpp17-port-golden-equivalence]
---

algommw core/src/math/window.c 的净室窗函数在窗长 N=1 时返回 NaN（hann/hamming/blackman 三者一致），N=2 才返回有效值 0.0。

为什么：N=1 是窗函数的退化边界，实现未对该情况防护，直接产出 NaN（具体除零位置未在切片中定位，属推断）。

边界：仅对 N=1、N=2 实测验证，未验证其他小窗长或 N=0。

证据：会话内 w.c 探针（#include "core/math/window.h"，循环 n=1..2）输出
`hann N=1 coef=nan isnan=1 hamming N=1 coef=nan isnan=1 blackman N=1 coef=nan isnan=1 hann N=2 coef=0.000000 isnan=0`。
