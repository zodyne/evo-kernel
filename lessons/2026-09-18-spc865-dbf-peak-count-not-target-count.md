---
id: spc865-dbf-peak-count-not-target-count
type: lesson
status: candidate
scope: project:spc865
domain: radar-doa
tags: [spc865, doa, 谱峰, 虚警, 合成验证]
triggers:
  - "SPC865 DBF 谱峰检测返回多个峰，想按峰个数判断目标数"
  - "合成单目标 roundtrip 峰值正确但峰检测 npeaks>1（失败信号）"
  - "两个同相/等幅目标在谱里出现远离目标的额外峰（失败信号）"
  - "写/审 spc865/doa.py 的峰值筛选与多目标判定"
  - "把谱峰个数当目标数写进报告/断言"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a80b-0e7a-7719-ba82-31f4af5174d2
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [sparse-mimo-fov-limited-by-element-pattern-not-grating, bpm-folded-peak-pairing-needs-coherence-not-amplitude]
---

# DBF 谱峰个数 ≠ 目标数：单目标 npeaks=4，双同相目标多出 −12dB 额外峰

**主张**：在合成数据上，SPC865 beam1 DBF 谱的峰检测结果包含目标峰之外的额外峰——注入单个 0° 目标时 roundtrip 峰值正确（`peak=0.00`）但检测器给出 `npeaks=4`；注入两个同相目标时峰表为 4 项：`(-7.75, 0.0), (7.75, 0.0), (-14.0, -12.1), (14.0, -12.1)`（0.0dB 两项对应注入目标，±14.0° 两项是低约 12dB 的额外峰）。所以峰个数不能当目标数；单目标 roundtrip 通过也不代表谱里只有一个峰，峰筛选必须带幅度/先验判据。

**证据（本会话合成探针输出）**
- 单目标：`--- beam 1 positions [ 0.  7.  7. 12. 14. 17. 19. 24.]   d=  0 th=  0.00 roundtrip=True peak=   0.00 npeaks=4`（虚阵位置为半波长单位）。
- 双同相目标：`=== in-phase two targets === beam 1 peaks [(-7.75, 0.0), (7.75, 0.0), (-14.0, -12.1), (14.0, -12.1)] beam 2 peaks [(-7.7…`。

**为什么**：峰表只是谱的局部极大值列表，含旁瓣/交叉项，不是目标清单；两个等幅同相源的谱相互叠加时会在目标之外形成局部极大。拿峰个数做多目标判定或写进断言，会把额外峰算成目标（虚警/目标数误判）。

**边界 / 反例**
- 以上是 in-beam 合成探针（无噪声、未涉及阈值调参）的观测；真实数据若带幅度门限，额外峰可能被滤掉——但门限是必需的，不能省。
- 本条不断言额外峰是缺陷还是阵列固有旁瓣特性，也不给具体门限值；只锁定「峰计数不能当目标数」。
- 单峰 roundtrip（peak/err 正确）只证明主峰位置对，不证明谱干净。

**失败信号**：合成单目标用例出现 `npeaks > 1`；或多目标峰表里出现幅度明显低一档（≈−12dB）且关于波束中心对称的峰。
