---
id: peebles-gi-approximation-error-half-db-plus
type: lesson
status: candidate
scope: global
domain: radar
tags: [radar, noncoherent-integration, integration-gain, gi, approximation, peebles]
triggers:
  - "用 Peebles/Mahafza 教材公式算非相干积累改善因子 Gi"
  - "把教材近似 Gi 表直接抄进阈值/P_d 设计,要求亚 dB 精度"
  - "核验文献/简报里积分增益数值的来源与适用范围"
  - "实测增益与教材表差零点几 dB,怀疑仿真错(失败信号)"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a5ef-b7d0-777c-a410-325dae81e5ed
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [noncoherent-sum-statistic-dof-2nk]
---

# Peebles(7.45) 式 Gi 近似随 K 系统性偏大,大 K 差 −0.5 dB 量级;工程算 Gi 用精确数值解

## 主张
Peebles 教材(7.45)式的非相干积累改善因子 Gi 近似式,K 增大时误差系统性增大:实测对精确值(exact,ncx2/chi2 + brentq 数值解)的偏差,Pfa=1e-2、Pd=0.5 下 K=2/4/8/16/100 → +0.07 / +0.06 / −0.01 / −0.12 / −0.51 dB。要求亚 dB 精度的工程计算不抄教材近似表,用 scipy 数值求解。

## 为什么
同一会话中,简报给的闭式阈值表正是源自 Peebles 近似口径,与项目精确统计量对不上(K=2、Pfa=1e-3、Pd=0.5:exact 2.198 dB vs Peebles 2.067 dB,差 −0.13 dB)。先分清近似与精确两条口径,能避免把"近似表误差"误判成"实现 bug"(见 noncoherent-sum-statistic-dof-2nk 的口径问题)。

## 边界 / 反例
- 教材近似适合量级估算与手算核对;若工程只要求 ±1 dB,小 K 下偏差可接受。
- K=2 时偏差可能为正(+0.07 dB),不是单调单侧——不要用"固定偏一个方向"去修正。
- 精确解的计算口径本身也要与统计量定义匹配(自由度/缩放),否则精确解同样对不上实测。

## 证据(2026-09-15 会话命令对照)
- 会话切片实跑 brentq 精确解 vs Peebles 公式批量对照:`K=2 exact=2.198 Peebles=2.067 diff=-0.13 dB`;`Pfa=1e-2 Pd=0.5: +0.07 +0.06 -0.01 -0.12 -0.51(K=2..100)`。
- 参考文献 Mahafza 7.4.2/7.4.3 节(pdftotext 抽取后 grep/sed 定位)提供近似式出处。
