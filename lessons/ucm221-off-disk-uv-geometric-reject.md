---
id: ucm221-off-disk-uv-geometric-reject
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: signal-processing
tags: [doa, direction-cosine, off-disk, hard-reject, silent-clip, viewer]
triggers:
  - "FPGA 点云出现 az=±90° 的假目标/假墙（失败信号）"
  - "u²+v²>1 的出圆点如何处理"
  - "解析/可视化层对非法方向余弦做静默 clip"
  - "怀疑 FPGA 测角算错"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:7b0f5574（合并 session:a522a07c）
last_verified: 2026-07-31
superseded_by: null
schema_version: 1
---
# 出圆点（u²+v²>1）按几何恒等约束直接 REJECT；解析层静默 clip 会制造 az=±90 假墙

**主张**：`u=sin(az)cos(el)`、`v=sin(el)` 推出 `u²+v²≤1` 是物理恒等约束，越圆点应直接进 `hard_reject`（与 dc/rho/hpr 并列），**不设阈值、不设 epsilon**（实测 (1.0,1.001] 区间仅 5–29 点/数据集，宽容度无影响）。可视化/解析层不得静默 clip——旧实现把 u 夹进 [-cos_el,cos_el]，三个数据集 |az|≥89.9° 的假点 **100% 是出圆点**被夹出来的，形成方位 ±90° 的假墙。

**为什么**：出圆点成因经三套离线估计器对账判定——**FPGA 没算错**（u 复算吻合率 97–99%），而是 ① 快拍非单源（出圆点单源相干 γ=0.64 vs 圆内 0.79，SNR 反而不低反高，是多径/多目标）② FPGA 在未校准通道上测角（|u_cal−u_fpga| 是 |u_raw−u_fpga| 的 46–62 倍）③ 端射 ±混叠。定位嵌入式异常的顺序：先复算验证"计算是否忠实"，再查输入与算法假设。

**边界**：出圆点方向物理无效，没有位置可画，只能剔除+报数（`off_disk` 标志位）；要"看见它们"需另开 u-v 平面 2D 面板。算法侧 `_uv_to_angles`（受 golden 约束）与解析侧 `off_disk` 是同式独立实现，改一处不会同步另一处。

**证据**：session 7b0f5574 判据落地后三数据集 KEEP 中 az=±90 点数 5201/176/10 → 0，keep_score 无需重标；session a522a07c 去掉 viewer 静默 clip，圆内 232,126 点与改动前 bit-identical。
