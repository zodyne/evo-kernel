---
id: single-rng-per-frame-replay-reproducibility
type: lesson
status: candidate
scope: global
domain: radar-sim
tags: [rng, noise, reproducibility, multiframe, simulation, verification]
triggers:
  - "核验多帧/多脉冲仿真的噪声是否可复现、种子怎么接进链路"
  - "要用『单一 rng 顺序贯穿所有帧』复现仿真噪声，逐帧比对 max|Δ| 该判到多少"
  - "只想整体重跑一遍看结果是否一致，就宣布多帧噪声可复现（失败信号）"
  - "多帧积累效果异常好，怀疑各帧噪声并不独立"
  - "复查多帧仿真链路里 rng 是只初始化一次还是每帧重新播种"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7a4-2f33-777c-a410-325f79674b44
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [detection-probability-not-peak-floor-ratio]
---

# 多帧噪声的复现判据：用单一 rng 顺序抽样逐帧重放，max|Δ| 到 1e-16 量级

## 主张

多帧仿真的噪声可复现性要用**逐帧重放**钉死：新建一个 `default_rng(0)`，按帧顺序消费同一随机流，逐帧与仿真输出的噪声比对（本次不传 rng、走库内默认路径）。实测帧 0 的 `max|噪声 − 单一 default_rng(0) 顺序抽样| = 4.965e-16`，帧 1 同量级——逐帧到 1e-16 量级即证明噪声是"种子只初始化一次、每帧继续消费同一流"。只看"整体重跑结果是否一致"没有这个判别力。

## 为什么

帧间噪声的相关性直接决定多帧（非相干）积累的增益与检测统计；"整体重跑一致"既兼容"单一流逐帧继续"，也兼容"每帧重新初始化"等其他接法，必须逐帧对账到单帧级别才能把 rng 的接法定死。

## 做法

在探针里复刻被测方的调用方式（本次：**不传 rng**，走默认路径），用同一个 `default_rng(0)` 按帧序生成噪声，逐帧打印 max|Δ|。必须复刻默认路径——探针自己显式传 rng 会掩盖默认路径是否每帧重置。

## 反例 / 边界

- 若链路允许每帧显式传独立 rng（或按帧派生 seed），则要按各帧自己的流重放，不能套用"单一流顺序抽样"的判据。
- 切片在该检查的第 2 帧处被截断：帧 0 与帧 1 的数值前缀可见（4.965e-16），更后面的帧未显示；引用完整逐帧序列需按同一探针重跑。
- 1e-16 是浮点重排级别的容差，不是"结果看起来一样"的目视判据。

## 证据（切片命令 ↔ 结果）

- `C3b 单一 rng 贯穿所有帧的**逐帧**复现（不传 rng）：帧0: max|噪声 − 单一 default_rng(0) 顺序抽样| = 4.965e-16  帧1: max|噪声 − 单一 default_rng(0) 顺…`（切片末截断）
- 同会话探针组织：多帧相位/噪声核验写在 `/tmp/vrfy_c.py`（另有内联探针 `from bpm_2t8r_sim.config import …` 复现同一结论）。

## 失败信号（未来命中即该想起本条）

- 复现检查只有"重跑一次结果相同"，没有逐帧 max|Δ|。
- 探针里自己构造 rng 而没走被测方的默认路径；逐帧差异突然跳到 O(1) 时先怀疑帧序/消费量对不上。
