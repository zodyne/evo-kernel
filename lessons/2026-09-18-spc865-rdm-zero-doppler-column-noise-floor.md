---
id: spc865-rdm-zero-doppler-column-noise-floor
type: fact
status: candidate
scope: project:spc865
domain: radar-signal-processing
tags: [spc865, rdm, zero-doppler, noise-floor, detection-margin]
triggers:
  - "在 SPC865 距离-多普勒矩阵上算检测裕量 / CFAR 门限，零速附近命中异常多或整列出点"
  - "拿整矩阵中位数（全局噪声底）当 RDM 噪声底做逐单元判决"
  - "零多普勒列幅度中位比邻列高约 10 dB（失败信号）"
  - "评估 ROI 命中率时把零速 ±2 bin 也纳入统计"
  - "怀疑 SPC865 RDM 有直流 / 零速泄漏，拿不准要不要逐列估底"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a977-6e7b-77c1-a593-51a2cfa0a8bf
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---
# SPC865 RDM 零速列比整矩阵中位高约 10 dB：噪声底要逐多普勒列估

**主张**：SPC865 的 RDM 里零多普勒列（切片标注 `d=32` 为零速列）明显更亮——QD-1/V1.2.0 远波束实测 `整矩阵中位=90.4`、`零速列(d=32)中位=100.5`、`非零速列(d=45)中位=90.3`。因此用整矩阵中位数当噪声底去算裕量，会在零速列系统性多给约 10 dB，让这一列整列更容易越过门限（假命中）；检测裕量 / 门限应逐多普勒列估底（至少零速列单独估），尤其在命中统计包含零速 ±2 bin 时。

**为什么**：裕量 = 单元幅度 − 底，底取全局值时零速列整体凭空高出 ~10 dB，等价于给这一列单独降了门限。本会话的分析脚本也是把噪声底改成按 Doppler 列取后才得到可解释的裕量（补丁把 `dop_noise` 改为 `det[:, li].mean(...)`、裕量改为 `det[r, d] - dop_noise`）。

**证据（本会话命令 ↔ 结果）**
- 进程内用 `spc865.config` 解析 QD-1/V1.2.0 远波束后打印 → `整矩阵中位=90.4  零速列(d=32)中位=100.5  非零速列(d=45)中位=90.3`。
- 同文件另一条解析输出 → `矩阵中位数(噪声底)=90.39 dB`、`Rd=1.6720 m/bin`（与 90.4 互证）。
- `/tmp/spc865_detail.py` 两次就地补丁：`dop_noise = (det[:, li].mean...`、`dop_margin = det[r, d] - dop_noise`。
- 命中率评估窗口本来就含零速：`spc865_three_way.py` 表头 `## 命中率（ROI 内 + 零速 ±2 bin）`。

**边界 / 反例**
- 这是单文件单波束（QD-1/V1.2.0 远波束）的单次实测，未做跨设备 / 跨波束统计；约 10 dB 的幅度是否普适需复测。
- 未验证抬高来源（直流泄漏 / 静杂波 / 窗），本条只给「零速列更亮 + 按列估底」这一可操作结论。
- 按列估底不等于免门限：零速列仍要过同样的 CFAR / 门限，别为补偿而手工减门限。
