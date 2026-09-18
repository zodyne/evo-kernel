---
id: algommw-doavariant-init-reject-dimension-ablation
type: lesson
status: candidate
scope: project:algommw
domain: radar-doa
tags: [algommw, doa, 变体, eChainInit, eErrNotImpl, 扫描网格, 消融对照]
triggers:
  - "algommw 的 DOA 变体（music/dml）在 eChainInit 返回 3 / eErrNotImpl，想定位是哪个维度被拒"
  - "准备把 eChainInit 的拒绝归因到调制方式（DDM/TDM）或阵列类型（失败信号：只跑了单格配置）"
  - "同一变体在不同配置下 eChainInit 返回码不一致（3 与 0 并存），不知道该信哪次"
  - "配了 [doa.scan] 扫描网格后 music/dml 起不来，想确认网格是不是触发条件"
  - "写变体能力探测脚本，想一次跑出『这个变体能不能用』的结论"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a704-a638-7353-8a3d-42fa0a3291fb
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [algommw-doavariant-init-ok-frame-notimpl]
---
# 变体被 `eChainInit` 拒绝时，跑消融矩阵定位维度，别从单格返回码归因

**主张**：algommw 的 DOA 变体在 `eChainInit` 阶段被拒（返回 `3` = `eErrNotImpl`）时，"为什么被拒"不能在**一格配置**上归因。实测同一个 music 变体在三格配置下给出 `3 / 0 / 0` 三种结果——至少要把「调制方式」与「是否配扫描网格」两轴各变一次跑成矩阵，才能说出是哪个维度触发的拒绝。

## 证据（切片内命令 ↔ 结果）

- `cd /tmp && cat > probe_ddm_music.py …`（先读出生效配置，再网格清零跑 music）→
  `modulation = 1  E_MOD_DDM = 1` / `doa variant in profile = 3  dbf2d = 3` / `eChainInit(DDM+music, scan=0) -> 0`
- `cd /tmp && cat > probe_b.py …`（配网格，调制换一轴）→
  `DDM+music+grid  eChainInit -> 3` / `TDM+music+grid  eChainInit -> 0`
- 代码侧入口：`core/src/dpu/doa/music.c:60`、`core/src/dpu/doa/dml.c` 都先调 `eDoaCfgValidate(pxCfg)` 并据返回值早退；网格是否配由 `bDoaScanConfigured()`（`core/src/dpu/doa/cfg.c:16`）判定。music.c 的注释点明这条校验针对的正是"网格配了却没生效"这类不透明行为。
- 返回码语义：`3 = E_ERR_NOT_IMPL`（`python/core_bind/dtypes.py:42`）。

## 为什么

`eChainInit` 的拒绝是多个配置维度联合判定出来的（本会话里"是否配网格"直接翻转了 DDM+music 的返回值），单格探测把"这个组合下被拒"读成"这个变体不支持/这个调制不支持"，归因就锁死在错误的维度上，后续排查会去改调制或换变体，而真正要处理的是网格。补一格对照（换调制，或清空网格）成本极低，却能把归因一次钉死。

## 边界 / 反例

- 本会话只逐字取得上述三格返回码（探针输出被切片截断），**没有**穷举 (调制 × 网格 × 变体) 全矩阵，也没有逐字取得 beam/dbf2d 的返回码；不要据本条断定"与调制无关"或"与调制有关"这类单因结论——要下这个断言得把缺的格子补跑。
- 存疑待复核：`TDM+music+grid -> 0` 与"拒绝只因配了网格"的说法表面上不一致（若 TDM 那格真配上了网格，则网格维度不能单独解释拒绝）。复核点：TDM 那一格的网格是否真的生效（对照 `probe_ddm_music.py` 里"读出生效配置再跑"的做法）。
- 与 `algommw-doavariant-init-ok-frame-notimpl` 互补不重叠：那条讲 init 返回 0 也不代表变体可用（要到首帧 `eChainDoa` 才报 3）；本条讲 init 返回 3 时如何定位是哪个维度触发。
- 若日后 `eChainInit` 改了校验条件（例如把网格兼容性判定收敛到统一入口），本条矩阵需按代码重测。
