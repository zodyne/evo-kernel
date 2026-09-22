---
id: wtr10-firmware-range-window-tukey-16tap
type: fact
status: candidate
scope: project:wtr10
domain: radar-signal
tags: [wtr10, 窗函数, tukey, 旁瓣, 距离谱]
triggers:
  - "分析 WTR10 距离谱泄漏/旁瓣，需要知道固件实际用的窗"
  - "dss_data_path.c 里距离 FFT 前那 16 个窗系数（0.08 + 0.92 组合）是什么窗"
  - "WTR10 距离谱最大旁瓣约 -13 dB，怀疑窗与 TI 默认 Hann 不一致（失败信号）"
  - "估 WTR10 泄漏污染时找不到等效窗的 3dB 主瓣宽/相干增益损失"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bdef-64b5-738d-af4a-290ada962882
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [suc221-leakage-far-exceeds-hann-sidelobe, noncoherent-sum-statistic-dof-2nk]
---

# WTR10 固件距离窗：首尾 16 抽头的 Tukey（α≈3.1%），不是 Hann

## 主张

WTR10 DSS 固件在距离处理前施加的窗是首尾各 16 抽头、系数形如 `0.08 + 0.92 × hann32 前半支` 的等效 Tukey 窗（α≈3.1%），不是 TI 默认 Hann/Hamming。其实测指标：3 dB 主瓣宽 ≈0.90–0.91 bin、最大旁瓣 ≈−13.3 dB（出现在 1.5 bin）、相干增益损失 −0.13 dB。

## 证据（session 01a0bdef，wtr10）

- 系数来源：`high_accuracy_68xx_dss/dss/dss_data_path.c` 的 16 个系数（命令注释：`0.08 + 0.92*hann32 的前半支`）。
- 复算输出：`固件等效窗(Tukey α=3.1%)  3dB主瓣宽 0.91 bin  最大旁瓣 -13.3 dB (在 1.5 bin)  相干增益损失 -0.13 dB`。
- 窗对比表复现同一行：`固件等效窗(首尾16抽头) -13.3  0.90 ...`。
- 对照：同一批复算里独立核对 Hann（`np.hanning(sym)`）最大旁瓣 −31.47 dB、3 dB 主瓣 1.44 bin。

## 边界 / 反例

- 数值来自按固件系数做的 numpy 复算（源文件与切片命令一一对应），未做上板实测；换固件版本/换配置前应重新核对系数。
- 引用该窗做泄漏污染估算时注意：−13.3 dB 旁瓣意味着比 Hann（约 −31.5 dB）高近 18 dB，把 Hann 的理论泄漏量直接搬来会低估。
