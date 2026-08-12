---
id: coverage-denominator-is-a-moving-target
type: lesson
status: candidate
scope: global
domain: metric-design
tags: [metrics, telemetry, reconcile, criteria-driven]
triggers:
  - "给自记录系统定「覆盖率/对账率」类判据，要选分母"
  - "覆盖率长期贴地，怀疑是纪律差还是口径错"
  - "判据阈值定了很久却从没接近过（失败信号）"
  - "依赖 transcript / 日志留存的度量要设阈值"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:b6cf7fd7-73c7-4cef-b538-5428b694a71b
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [doc-selfreported-counts-drift, injection-precision-must-split-recall-vs-adoption]
---

# 以「全部历史事件」为分母的覆盖率判据是永不可达的移动靶——分母必须限定在可补救窗口内

## 主张

当一个指标的分母是**只增不减的历史事件总数**、而分子只能来自**有时效的原始素材**（transcript、
日志、会话记录）时，这个比值不度量执行纪律，它度量的是**素材留存率**。素材一旦被清理，
对应的分母永远留在那里、分子永远补不上，比值只会单调下沉。拿它当「指标是否可解读」的闸门，
闸门会被永久焊死，而且会把「素材过期」误诊成「纪律差」，导致去修一个没坏的东西。

## 为什么

Evo-Kernel 的 M1 判据里，对账覆盖率 = 已对账实例 ÷ **总注入实例**，阈值「<30% 精度不可解读」。
2026-07-29 实测（515 个有 session 归属的注入实例，按 session 归因）：

| 桶 | session 数 | 注入实例 | 占比 |
|---|---|---|---|
| 从未登记（SessionEnd 没触发） | 43 | 266 | 51.7% |
| 登记了但 transcript 已失效（哨兵 `'?'`） | 29 | 204 | 39.6% |
| 进了蒸馏队列 | 22 | 43 | 8.3% |
| 被 50KB 体量门槛挡掉 | 1 | 2 | 0.4% |

补跑当时全部 8 个可蒸馏 session，最多再添 10 个对账实例，**覆盖率上限 7.1%**——
阈值 30% 靠补跑绝无可能达到。更关键的是归因：未登记的 43 个 session 里，
只有 7 个（6%）的 transcript 还在磁盘上，其余是 harness 按自己的策略清理掉的。
**分母里超过九成的实例，从被记进日志的那一刻起就注定无法对账。**

反过来看已对账的部分：18 个已蒸馏 session 内部**零漏判**（每个 injected id 都判了四态）。
也就是说纪律侧其实是好的——低覆盖率完全由素材留存造成。若照字面读判据去「先修蒸馏纪律」，
修的是一个没坏的东西。

## 反例 / 边界

- 不是说覆盖率没用。它在**可补救窗口内**（transcript 仍在、或已蒸馏）是有效的纪律指标——
  实测该窗口内覆盖率接近 100%，恰恰证明了这一点。
- 若素材永久留存（分母里每个事件都随时可补），原口径成立，本条不适用。
- 阈值本身没错，错的是分母的取值域。改分母不等于放宽标准：可补救窗口内的 30% 比
  全历史的 30% 更难，也更有信息量。

## 待人审裁决（本条不自动入库执行）

分母改为下列哪一种，属设计口径变更（v4 §7.1 / build-spec §3.4），需人审：

1. **可对账窗口**：分母只计 `transcript` 仍存在或 `distilled=true` 的 session 的注入实例；
2. **滚动窗口**：分母只计近 N 天（如 30 天）的注入实例；
3. **维持现状 + 诚实标注**：口径不动，但报告里必须与「素材留存率」并列呈报，
   避免把留存问题读成纪律问题。

无论选哪个，历史数字都不可与新口径直接比较，需在 BASELINE 类记录里标注口径切换点。

## 证据

- 归因统计：按 `ops/log/recall.jsonl` 的 `session` 字段 join `inbox/session-refs.jsonl`，
  再对未登记 session 反查 `~/.claude/projects/*/*.jsonl` 与 `~/.pi/agent/sessions/*/*.jsonl`。
- 同日已修的实现层缺陷（与本条独立）：reflect 曾用 recall **调用数**当分母，
  虚高 3.3 倍（39/205=19% vs 定义口径 39/685=5.7%），见 commit `5b1d6ab`。
- 前向侧已修：登记从 SessionEnd 前移到首次 `hook-recall`，堵住 51.7% 那一桶的**未来增量**
  （存量追不回），见 commit `b4cf1c5`。
