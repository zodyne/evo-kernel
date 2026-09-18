---
id: fmcw-interframe-phase-absolute-time-axis
type: lesson
status: candidate
scope: global
domain: radar-sim
tags: [fmcw, multiframe, phase-coherence, simulation, absolute-time]
triggers:
  - "写多帧 FMCW 时域仿真：每帧的时间基准/相位基准该怎么取"
  - "多帧相干处理结果对不上理论，怀疑帧间载波相位不连续（失败信号）"
  - "核验简报里『帧间相干性』的做法：帧间相位是否自然连续、是否需要补偿"
  - "帧与帧之间 4πR(t)/λ 出现跳变，查是不是每帧重置了时间原点（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a7b1-a576-777c-a410-326c0e8fea05
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [fmcw-absolute-phase-float64-precision, cross-frame-range-gate-must-track-target]
---

# 帧间相位连续靠绝对时间轴求值 R(t)，不是逐帧拼相位

## 一句话主张

多帧 FMCW 仿真要保证帧间载波相位连续，做法是让目标状态在**绝对时间** `t = t_start_k + n·Tc + u` 上求值、
每个采样点算一次真实双程距离 R(t)：`4πR(t)/λ` 这一项随帧自然连续，跨帧相干处理才成立；
不要每帧把时间原点重置为 0 再人为拼接/补偿帧间相位。

## 为什么

帧间相位的物理来源是同一目标在绝对时间轴上的连续运动；漏掉该帧的绝对起始时刻 `t_start_k` 后，
帧 k 与帧 k+1 的相位之间会出现人为跳变（幅度取决于帧间位移 ΔR），相干积累/相干检测的结论随之失真。
"短帧内目标参数近似不变、拍频峰相位等于正弦初相"是这一建模的文献前提——本次核验下载的 TI 应用手册与 arXiv 论文均可逐字查证。

## 反例 / 边界

- "绝对时间轴"说的是几何/相位模型的**自变量**；绝对相位 `2πf0·t` 本身在高频长时宽下受 float64 精度限制，
  实现时相位计算仍应走差频/相对路径（见 related: fmcw-absolute-phase-float64-precision），两者不冲突。
- 若帧间本就不相干（PRF 分集、各帧 Tc 不同、走非相干积累），则不需要也不能按相干相位连续来建模。
- 本条依据是核验中读到的项目建模设计 + 逐字查到的文献，会话未做"绝对时间 vs 每帧重置"的数值对照实验，故如实标 verified_by: human。

## 证据

命令 ↔ 结果（session 01a0a7b1 切片）：

- `sed -n '395,445p' README.md` →
  `目标状态在**绝对时间** t = t_start_k + n·Tc + u 上求值，每个采样点算一次真实双程距离，于是帧与帧之间的载波相位（4πR(t)/λ 那一项）**自然连续**，不需要…`
- `pdftotext ti_fmcw.pdf` + grep "initial phase" →
  `400: Phase of the peak is equal to the initial phase of the sinusoid`
- `pdftotext arxiv.pdf` + grep "frame-by-frame|constant over the short frame" →
  `106: … and any targets may be assumed constant over th[e short frame]`
- 旁证：同会话抓到的 ADI 论坛页标题 `ADF4159 phase coherence between the chirp`（200 / 305783），同属"帧间/啁啾间相位相干"问题域。
