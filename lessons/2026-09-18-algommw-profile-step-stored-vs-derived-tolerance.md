---
id: algommw-profile-step-stored-vs-derived-tolerance
type: fact
status: candidate
scope: project:algommw
domain: radar-config
tags: [algommw, profile, range-step, doppler-step, tolerance, validate-only]
triggers:
  - "对账 algommw profile 的 xRangeStep/xDopplerStep 与按公式重算的值，准备做等值断言"
  - "profile stored dR/dV 与 derived 值不等（失败信号：约 0.07% 的相对差被当成配置写错）"
  - "想确认 algommw 的 range/doppler step 是 core 推导的还是配置给进来的"
  - "移植 algommw 波形配置，要先决定哪个值是权威"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5bdd-7353-8a3d-42cfac95e3a6
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [radar-derived-param-mhz-hz-unit-slip, validate-ok-but-derived-index-overflow-silent]
---

# algommw 的 range/doppler step 以 profile 存储值为权威；与公式重算值差约 0.07%

## 主张
algommw 的 `xRangeStep` / `xDopplerStep` **以 profile 存储值为权威**：`core/src/types/waveform.c` 头注释写明"core 只做 validate,不做推导"。Python 侧另有 `python/core_bind/config.py:_derive_steps()` 按公式重算，两者**不相等**——sr61_tdm 实测 `stored dR=0.183105468 derived=0.182978795 relerr=0.06923%`、`stored dV=0.856502955 derived=0.855906004`（同量级 ≈0.07%）。拿重算值对账必须用相对容差（≈1e-3）；等值断言必然误报。

## 为什么
profile 里存的是量化后的实际值，重算值只是同一物理量的另一条数值路径。把"公式推导 == 配置存储"当不变量，会在本该通过的对账里制造假失败，并诱导人去"修"一个正确的配置。

## 证据
- `/tmp/probe2.py` 逐 profile 打印 stored / derived / relerr，输出行即 sr61_tdm 的上述数字。
- `core/src/types/waveform.c` 头注释："core 只做 validate,不做推导——xRangeStep/xDopplerStep ..."（由调用方给定）。
- `python/core_bind/config.py:26 def _derive_steps(`、`:42 range_step = _C_LIGHT / (2.0 * ...`（推导逻辑在 Python 侧，与 core 的 validate-only 分工不同）。

## 边界
- 数字取自 sr61_tdm profile 当次快照；换 profile / 波形后具体 relerr 需重测，但"存储值 != 公式重算值"的性质不变。
- 这不等于"profile 值可以随便写"——core 的 validate 仍会拒绝不合法配置；这是"谁定义权威"，不是"免检"。
