---
id: algommw-doa-beam-1d2d-auto-split
type: fact
status: candidate
scope: project:algommw
domain: codebase-map
tags: [algommw, doa, beam, 1d-2d-split, 谱峰]
triggers:
  - "移植 algommw beam/谱峰测角，要判断当前阵型走 1D 还是 2D 路径"
  - "beam 1D/2D 自判结果与预期不符，怀疑分流判据（失败信号）"
  - "找 eDoaVariant 枚举与谱峰变体的分流实现位置"
  - "给 eDoaVariantBeam 变体传阵型配置，结果与手工 fft/fft1d 选择不一致"
  - "1D 阵判定阈值是多少（xPosZ 极差 vs λ/8）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af3a-ab1b-7097-91f3-80f1eaca1bbd
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [mmw-cpp17-port-golden-equivalence]
---

algommw 的谱峰 DOA 变体 `eDoaVariantBeam`（枚举值 0）是 1D/2D 合一实现：
变体枚举在 `core/include/core/dpu/doa/cfg.h:44-47`，注释明确
「谱峰(DFT 波束形成):1D/2D 合一,init 按阵列几何自动分流(2026-09-07 融合 fft+fft1d)」；
运行期快路径由 `beam.c:24-29` 的 `bDirect`/`bIs1D` 再分：
**1D 判据 = 阵面 xPosZ 极差 < λ/8 且无俯仰需求**，满足则走角度 FFT 快路径
（候选 = az/el 各 64 点规范正弦格）；
阵列级 1D 判定函数为 `bDoaArrayIs1D`（`core/src/dpu/doa/geo.c:37`，同文件 :20 `eDoaArrayValidate`）。

为什么：移植/对拍时必须复现同一分流判据，否则同一阵型两边走不同路径，
golden 等价比对会系统性偏差（此前 C++17 移植已踩过「12 虚拟阵元被判成 1D」的坑）。

边界：λ/8 极差阈值以代码注释为准；判定的权威实现在 geo.c，
不要按注释自行重推。证据：会话切片 3 组 rg 命令及输出
（cfg.h:44-47 / beam.c:24-29 / geo.c:20,37）。
