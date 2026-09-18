---
id: rdmap-log2-domain-average-is-geometric-mean
type: lesson
status: candidate
scope: global
domain: radar-dsp
tags: [radar, cfar, rdmap, log-domain, averaging-bias]
triggers:
  - "在 log2 域的 RD/距离多普勒图上做算术平均（跨单元、跨帧聚合或噪底估计）"
  - "CFAR/噪底门限用了 log 域均值，检测率整体偏移却查不出原因（失败信号）"
  - "移植（algommw 等）CFAR 代码时看不出 RdMap 是 log2 域还是线性功率域（失败信号）"
  - "把 dB/对数谱当线性量做均值、求和或插值之前，要确认它处于哪个域"
  - "同一个 RD 图两种域各算一次均值结果对不上，怀疑算法而不是域（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad30-a962-77c1-a593-51aa6abcdec8
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [playbook-suc221-cfar-point-cloud-filtering, deskew-fmcw-phase-noise-residual-scales-with-range]
---

**主张**：当 RdMap 处于 **log2 域**时，对 log2 数值做**算术平均**，换算到功率域等于**几何平均**（不是算术平均）——因此「在 log2 域直接平均」得到的是功率域的几何均值，会系统性地低于功率算术均值；拿它当噪底/门限估计会让判决整体偏向某侧。

**为什么**：均值不是与单调变换可交换的线性算子。`mean(log2 p) = log2( (∏p)^(1/N) )`，还原回功率域即几何平均。因此域决定了统计量的语义：要做算术平均必须先 `exp2` 回线性功率域，平均完（若下游需要）再 `log2` 回去。单调变换只保序（比较/argmax 不受影响），不保均值。

**证据**（本会话硬证据切片，命令 ↔ 结果）：
```
$ cd /Users/zodyne/Dev/algommw/core && sed -n '25,115p' include/core/dpu/cfar/cfar.h; echo "===== DOA CFG ====="; sed -n '20,105p' include/core/dpu/doa/...
  ↳ * 库函数(mmwavelib_cfarOS)提供的有序统计法,本项目并入同一个枚举。
    * ⚠ 一个必须知道的事实:RdMap 是 log2 域,而"log2 域的算术平均"在功率域等于**几何平均**(手册 ch04 §…
```
即被侦察的 CFAR 头文件把该事实标注为「必须知道」，并指向其手册 ch04 出处。

**边界**：
- 只影响**聚合类**运算：跨单元/跨帧均值、噪底估计、插值、求和。单点阈值比较、argmax、极大值挑选不受影响（单调变换保序）。
- 若 RdMap 已是线性功率域，本条不适用；判别办法是看上游写入该缓冲的变换（本项目为 log2），不要凭字段名猜。
- 与「dB 口径混用」类问题（如面板间 dB 曲线差固定倍数）机理不同：那是 10log/20log 口径，本条是「在错误域里求平均」。
