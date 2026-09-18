---
id: pd-closed-form-cross-check-mc-and-quadrature
type: playbook
status: candidate
scope: global
domain: radar
tags: [radar, detection, pd, numerical-stability, laguerre, monte-carlo]
triggers:
  - "用解析闭式/级数/Laguerre 展开算非相干积累 P_d 或阈值表，结果要拿去核验别人给的数字"
  - "算 P_d 的脚本报 RuntimeWarning: divide by zero（失败信号：解析路径数值退化，但输出仍是看似合理的概率值）"
  - "极端 P_fa（1e-6）或大 K 下闭式 P_d 与仿真/文献打印对不上，分不清是公式错还是数值实现退化"
  - "只跑了一条数值路径就准备把闭式 P_d 表当结论引用"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7b1-3634-777c-a410-326ad527f35f
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [dual-impl-cross-check-tolerance-grid-anchored, noncoherent-sum-statistic-dof-2nk]
---

# 闭式 P_d 表采信前必过三件套：MC 对拍 + 两条独立数值路径互拍 + 单调性扫描

**主张**：解析（级数 / 广义 Laguerre 多项式 / 混合积分）算出来的非相干积累 P_d 表，**不能只跑一条数值路径就采信**——`numpy.polynomial.laguerre` 路径在部分参数区会抛 `RuntimeWarning: divide by zero encountered`，而它**不抛异常、不中断流程，输出的仍是一个"看起来合理"的概率值**。采信前必须过三件套自检：① 与蒙特卡洛对拍（同 λ、同 scale、同噪声方差口径）；② 两条**数学上独立**的数值路径互拍（数值混合积分 quad vs 级数展开）；③ 单调性扫描（P_d 对 K 单调不减，违例数应为 0）。三件套全过，闭式值才可作为核验别人的依据。

**为什么**：解析式退化是**静默**的——多项式递推/级数求和/极端 P_fa 下的抵消只以 RuntimeWarning 暴露，退出码和输出格式都正常；一条路径上的"合理数值"无法自证，只能靠第二条不共因的路径或随机模拟来对拍。三件套的分工：MC 抓"公式口径写错"（含 λ 漏因子 2），双路径互拍抓"同一公式的数值实现退化"，单调性扫描抓"符号/收敛错误"。

**做法 / 判据**：
1. **MC 对拍**：同口径下多次独立实现（每 I/Q 分量方差、λ、scale 全对齐），一致性按轮数给容差——切片里 1e4 级抽样下 MC 与闭式在 1e-2~1e-5 内吻合即为通过。
2. **双路径互拍**：`scipy.integrate.quad` 混合积分 vs 级数展开，两条路径应给同一数值；差到机器精度（切片实测 `diff=-4.2e-22`）才算过。
3. **单调性扫描**：扫 K=1,2,3…（含 8RX 统计量 D=16 的另一套口径）统计 `Pd(K+1) < Pd(K)` 的违例数，期望 0；顺带看小 K 处差分是否近似持平（近似持平会导致反解 SNR 不稳定）。
4. 把 RuntimeWarning 当失败信号看：`python3 -W error::RuntimeWarning` 或至少人读 stderr，不要因为"脚本 exit 0 + 有数"就当通过。

**边界**：
- 切片只捕获到 Laguerre 路径的除零警告，**未定位到具体触发参数**（哪个 P_fa / K / s 区间退化未在本会话查清）。
- 反过来也不能因为某组参数上两条路径对得上就跳过三件套：切片里 quad vs 级数在 `s=0.01 K=1`、`s=0.1 K=4` 处一致到 1e-22，说明退化只发生在部分参数区，采样点要覆盖极端 P_fa 与大 K。

**证据（本会话命令 ↔ 结果）**：
- Laguerre 路径退化：`c.py` 实跑 → `✗ /opt/homebrew/lib/python3.14/site-packages/numpy/polynomial/laguerre.py:1592: RuntimeWarning: divide by zero encountered`（`✗` 为切片对失败结果的标记）。
- 双路径互拍：`d.py` → `--- Sw1 交叉验证: quad 混合 vs 级数 ---  s= 0.01 K= 1 Pfa=1e-06: quad=0.00000115 series=0.00000115 diff=-4.2e-22  s= 0.1 K= 4 ...`。
- MC 对拍：`Sw1 MC（每 I/Q 分量方差=1，λ=2Kx，scale=1）: s=1.0 K=4: MC=0.14312 公式=0.14321`；`l.py` → `s=1.0 K=4: Sw2 MC=0.11015 公式=0.10973`。
- 单调性扫描：`i.py` → `=== 扫描单调性 Pd(K+1) > Pd(K) ？ ===  违例数： 0  === 同样扫描 8RX 统计量 D=16 ===  违例数： 0`。
