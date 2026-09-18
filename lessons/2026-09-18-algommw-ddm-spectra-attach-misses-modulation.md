---
id: algommw-ddm-spectra-attach-misses-modulation
type: lesson
status: candidate
scope: project:algommw
domain: radar-doa
tags: [algommw, spectra, 谱导出, DDM, 调制, eChainDoaSpectraAttach, 判定漏维度]
triggers:
  - "改/审 algommw 的谱导出（eChainDoaSpectraAttach / pxSpectra）"
  - "DDM（调制）会话下 spectra 一直空、却没有任何报错（失败信号）"
  - "给新调制方式（DDM/TDM）接谱导出，担心可用性判定漏维度"
  - "空谱到底是没算、没选，还是后端不导出"
  - "审 chain.c 的导出判定分支（402-421）与 DOA 分发（278-330）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5b6d-7353-8a3d-42ca582bd179
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [spectra-state-off-conflates-not-computed-with-not-selected]
---

algommw 谱导出的可用性判定**漏了调制维度**：`eChainDoaSpectraAttach`（`core/src/chain/chain.c:402`）只判 music/dml 与 `bDirect`/`bIs1D`，**不判调制**；而 DDM（调制）会话逐点只走 `eDoaBeamEstimate`，`pxSpectra` 的写入点在 `core/src/dpu/doa/beam.c:520`（`if( pxCtx->pxSpectra != NULL )` 分支）。会话审查的结论是 **DDM 会话的谱导出契约破裂**（`chain.c:402-421` 判定 + `278-330` 分发）：DDM 会话拿不到谱。

## 证据（切片）

- 末条 assistant（会话结论原文）：`1. **DDM 会话的谱导出契约破了**(chain.c:402-421 + 278-330):eChainDoaSpectraAttach 只判 music/dml 与 bDirect/bIs1D,不判调制;DDM 分支逐点只调 eDoaBeamEstimate,而写谱代码全…`（切片在 200 字处截断）。
- `grep -n "eChainDoaSpectraAttach\|bDirect != 0U\|bIs1D != 0U\|pxSpectra = pxSpectra\|eChainDoa(" core/src/chain/chain.c` → 只命中 `274:eStatus eChainDoa( ChainCtx_t *pxChain, const Cube_t *pxCube, Cloud_t *pxCloud )` 与 `402:eStatus eChainDoaSpectraAttach(`。
- `grep -n "pxSpectra" core/src/dpu/doa/beam.c` → `520:    if( pxCtx->pxSpectra != NULL )`、`524:        pxCtx->pxSpectra->ulNumPoints = 0U;`。
- Python 侧对"空谱属于哪种状态"有显式建模：`python/radar_viz/pipeline.py:80` 注释给出谱导出状态 `"ok"/"notimpl"/"off"`。

## 边界

- 本条是**静态审查（grep + 读码）**得出的契约结论，切片里没有 DDM 空谱的运行时复现；会话共 4 条发现，只有这一条进入切片（其余 3 条被截断）。
- 只断言"判定维度里没有调制"与"DDM 逐点走 beam 估计、谱写入点在 beam.c:520"这两点；attach 之后 DDM 具体在哪一步丢谱，切片未展开。
- 与 `spectra-state-off-conflates-not-computed-with-not-selected` 互补：那条讲状态字面量把"没算"报成"没选"（状态建模），本条讲导出判定本身漏维度（覆盖不全）。
