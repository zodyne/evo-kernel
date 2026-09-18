---
id: multi-seed-identical-readout-suspect-seed-not-wired
type: lesson
status: candidate
scope: global
domain: verification
tags: [reproducibility, rng, seed, noise, probe-validity]
triggers:
  - "用多个随机种子/噪声实现跑同一条读取路径做鲁棒性验证"
  - "不同 seed 的输出逐位相同（失败信号：随机性没进这条路径）"
  - "准备拿『多 seed 结果一致』当抗噪/鲁棒性证据"
  - "探针脚本里 seed/噪声参数理应影响读数，输出却看不出差别"
  - "复查 MC/仿真探针是否真把随机性接进了被测链路"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ce-925d-777c-a410-327304469e03
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [analysis-cache-filename-must-key-dataset]
---
# 多个「独立噪声实现」给出逐位相同的读数时，先怀疑种子没接进链路

## 主张
用多个独立随机种子跑同一条读取路径，若各 seed 的输出**逐位相同**，先假设随机性根本没有进入该路径
（种子未接、RNG 状态被复用、或读的是确定性中间量），不要把它当成「结果对噪声鲁棒」的证据。
发现零方差后，先核对该路径的随机源是否真被消费（打印噪声功率 / 对比原始快拍 / 换 seed 看中间量是否变），
再谈鲁棒性。

## 为什么
独立种子本应让噪声驱动的估计量在噪声尺度上抖动；连续量逐位相同，说明被测读数与随机源无关。
把它误读为「鲁棒」，会让基于该探针的所有结论（噪声敏感性、门限余量、「算法稳定」）建立在空集上。

## 证据（session 01a0a7ce 命令 ↔ 结果切片）
- `verify6.py`（探针自述为「4 次独立噪声实现的逐帧读数」）输出：
  `seed0: ['-9.8856', '-8.4492', '-7.3118']`
  `seed1: ['-9.8856', '-8.4492', '-7.3118']`
  `seed2: ['-9.8...`（切片在此处截断）
  两个标称独立的噪声实现在 3 帧读数上逐位相同，seed2 首值亦相同——4 位小数的连续量出现零方差。

## 边界 / 反例
- 读数若是离散量（FFT bin 索引、argmax 类别、粗栅格四舍五入），或 SNR 高到估计量本就恒定，
  identity 可能正常——此时应改看连续量或原始快拍，不能直接判「种子没生效」。
- 探针把 `np.random.default_rng(0)` / `RandomState(0)` 写死在同一状态上时，零方差是探针 bug，不是被测系统性质。
- 两个 seed 一致已足以对连续量起疑；判「稳定零方差」最好 ≥3 个 seed 且读数精度足够细。
