---
id: imre-reim-interleave-misread-mirrors-spectrum
type: lesson
status: validated
scope: global
domain: radar-sim
tags: [iq, interleave, imre, reim, binary-format, spectrum-mirror, verification]
triggers:
  - "解析/核验 int16 交错 IQ 的离线采集或 ADC dump，要确认 I/Q 交错顺序（IMRE vs REIM）"
  - "复数谱峰落在镜像位置（bin k ↔ N−k），幅度/能量却完全对得上（失败信号：交错顺序被误读）"
  - "采集容器在元数据里自报格式串（如 int16/IMRE），要核对解析代码是否按声明解析"
  - "bin↔FFT 的 roundtrip 验证只比对了幅度/总能量就准备宣布通过"
  - "同一份数据按两种交错顺序解出的 |X| 完全相同、只有峰位不同"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7a4-2f33-777c-a410-325f79674b44
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [bpm-adc-captures-in-tmp-keyed-by-note]
---

# I/Q 交错顺序误读不改变幅度谱，只把谱峰镜像到 N−k

## 主张

int16 交错复数 IQ 的交错先后（本例容器自报 `IMRE`，误按 `REIM` 解）**不改变幅度谱**，只把整条谱**镜像**：同一份 1024 点数据按 IMRE 解出谱峰在 bin 64，按 REIM 误读则落在 bin 960（= N−64），两者 |X| 完全相同（3781225.6）。所以「能量/幅度对得上」不能证明格式解析正确——核验交错顺序必须比对**峰位**（正半轴 [0, N/2) 内是否还有预期峰），并以容器自报的格式串为准绳。

## 为什么

交换交错先后等价于取共轭：频谱翻到共轭位置、幅度不变。于是只看幅度的检查（能量、RMS、量化误差直方图、饱和统计）全部照常通过，只有相位敏感的检查（峰位/镜像、Doppler 符号、测角相位）会翻——这是典型的静默错：验证脚本越只做幅度统计，越发现不了。

## 做法

同一份 bin 用两种交错顺序各解一次 FFT，打印全长谱峰 bin 与正半轴 [0, N/2) 峰 bin：若两侧峰位互补（k 与 N−k）且 |X| 相同，则唯一变量就是交错顺序；再拿采集容器自报的格式串定案，而不是靠约定俗成猜。

## 反例 / 边界

- 只对"实部/虚部交错存放"的复数格式成立；实采样或 I/Q 分存两个数组时不存在这个歧义。
- 目标本就落在负频、或谱形对称时，镜像峰位本身不构成证据——需要先有预期峰位（已知合成目标/强单音）再判。
- 镜像差异在 k 靠近 N/2 时最小、靠近 DC/Nyquist 时最明显，探针选点要避开 N/2 附近。

## 证据（切片命令 ↔ 结果）

- 同一份 `/tmp/vrfy3/adc_0000.bin`（帧长 4194312 B）按两种顺序解 FFT：
  `IMRE正确: 全长谱峰 bin=64  |X|=3781225.6   正半轴[0,512)峰 bin=64  |X|=3781225.6  REIM误读: 全长谱峰 bin=960  |X|=3781225.6`
  ——幅度相同，峰位 64 vs 960（N=1024）。
- 采集容器自报的格式：`1024 采样 int16/IMRE`（`python3 -m bpm_2t8r_sim.adc capture` 输出头）。
- 旁证：同会话从 `capture.json` 读出 geometry（`n_rx=8, n_tx=2, n_chirp=128, n_…`），说明格式/几何都有产物自报值可对。

## 失败信号（未来命中即该想起本条）

- 谱峰出现在 N−k、而幅度/能量与预期一致。
- 探针只打印了 max|X|、总能量、RMS，没有打印 argmax bin。
