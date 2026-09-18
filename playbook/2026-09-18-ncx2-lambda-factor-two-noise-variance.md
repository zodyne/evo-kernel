---
id: ncx2-lambda-factor-two-noise-variance
type: lesson
status: validated
scope: global
domain: radar
tags: [radar, ncx2, noncentral, pd, noise-variance, caliber]
triggers:
  - "核验/复算非相干积累 P_d 表里的 SNR，或从 P_d 反解所需 SNR，与别人给的数字对不上"
  - "准备断言某段蒙特卡洛 P_d 数据『与理论不自洽 / 算错了』之前"
  - "复高斯噪声下用 scipy ncx2 写 H1 的 P_d 闭式，非中心参数 λ 该填 2K·s 还是 K·s 拿不准"
  - "用 λ=K·s 代进闭式，结果恰好复现对方指控里的那组数字（失败信号：错的是口径，不是数据）"
  - "文献/简报给的噪声方差口径（E|n|²=σ² 还是 2σ²）与本项目仿真代码不一致"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7b1-3634-777c-a410-326ad527f35f
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [noncoherent-sum-statistic-dof-2nk, adversarial-review-repro-as-written, validation-params-readable-from-artifact]
---

# H1 的非中心参数 λ 要带上噪声方差的因子 2（λ=2K·s）；漏掉它会"复现出对方的错数字"，把自洽的 MC 数据判成不自洽

**主张**：非相干积累统计量 Z=Σ_{k=1..K}|X_k|² 在 H1 下的非中心参数与**噪声方差口径**绑定：本项目口径是每 I/Q 分量方差=1（即 E|n|²=2），此时 λ = **2K·s**（s 为单元 SNR），不是 K·s。做"从 P_d 反解 SNR"或"复算 P_d 表"这类核验时漏掉 `E|n|²` 里的因子 2，会系统性地算出另一套数字——而**这套错数字恰好能自圆其说地解释对方"你的数据不自洽"的指控**，于是把一份本来自洽的 MC 数据判成错的。

**为什么**：闭式（ncx2 / Swerling 混合积分）里 λ 和 H0 门限都随同一套归一化走，口径只差一个 2 也照样给出"看起来合理"的 P_d，不会报错、不会越界——所以错口径与对口径的输出都是"一个概率值"，只能靠复现双方数字来裁决。本会话栽的正是这个：被核验的简报在 F5 里自己写对了 λ=2K·SNR_cell，到 F7 反解时却用了 λ=K·SNR_cell，于是宣布"评审 MC 数字不自洽"——错的不是 MC 数据。

**做法（裁决"不自洽"指控的两步）**：
1. 先把口径写死再算：每 I/Q 分量方差、E|n|²、χ² 的 scale/dof 三者对齐，并**从被测产物本身读回实际口径**（不要只信文档声明）。
2. 双方数字都亲手复现一遍：**错口径能否逐位复现对方指控里的那组数字？对口径能否复现被测数据的数字？** 前者复现成功 = 指控者的口径问题，不是数据错。
3. 判"不自洽"的证据门槛：**同一口径下**理论值与 MC 值逐点对得上才算自洽的证据。

**反例 / 边界**：
- 若统计量本来就按"每分量方差 1/2、E|n|²=1"归一化，则 λ=K·s 才是对的——判据是代码里噪声怎么加的，不是文献怎么写。切片实测该项目 `add_noise_sigma(sigma=1.0)` → `E|n|^2 = 0.9993945192144885`、`per-comp var = 0.5018622527024253`，即 σ=1 时 E|n|²=σ²、每分量方差 σ²/2，因子 2 的来源就在这。
- 切片只覆盖单通道 D=2K 口径下的 Sw0/Sw1 复算；8RX 求和（16K dof）的口径换算见 related 的 `noncoherent-sum-statistic-dof-2nk`。

**证据（本会话命令 ↔ 结果）**：
- `h.py`（Pfa=1e-3，`def Pd(s,K,mult)` 两口径对照）实跑：`若 λ=K·s（漏掉 E|n|²=2σ² 的那个 2）： s=1: Pd(K=1)=0.0069  s=1: Pd(K=16)=0.1061  → 与简报写的 0.0069 / 0.106 对比`——错口径逐位复现了简报的数字。
- `g.py`（`-- 单通道 D=2K --  峰/底均值比=1+s=2.00`，s=1.0）实跑：`Pd(K=1)=0.0185  Pd(K=16)=0.5181  Pd(1)=0.0169`——对口径一侧同样复现了 SPEC 的那对数字（0.0169 / 0.5176 量级）。
- 会话结论（末条 assistant）：简报 F7「评审 MC 数字不自洽」是其自身 λ 用错所致；用对的 λ，"SPEC 那对数字其实自洽"。
