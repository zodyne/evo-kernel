---
id: algommw-doavariant-init-ok-frame-notimpl
type: lesson
status: candidate
scope: project:algommw
domain: radar-doa
tags: [algommw, doa, 变体, eChainInit, eChainDoa, eErrNotImpl, 能力探测]
triggers:
  - "探测 algommw 的 DOA 变体（music/dml/beam/dbf2d）在当前阵列上是否可用"
  - "eChainInit 返回 0，但逐帧 eChainDoa 返回 3 / eErrNotImpl（失败信号）"
  - "写能力探测脚本判断某个 DOA 后端是否受支持（失败信号：以 init 成功当可用）"
  - "music/dml 在稀疏 3-z 阵上到底在哪一步被拒"
  - "换 profile 后要确认新阵列支持哪些 DOA 变体"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5b6d-7353-8a3d-42ca582bd179
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [algommw-doa-beam-1d2d-auto-split]
---

algommw 的 DOA 变体"能不能用"**不在 `eChainInit` 校验**：不支持的变体 init 照样返回 0，要到首帧 `eChainDoa` 才返回 3 = `eErrNotImpl`。实测 music 在 afm761 profile 上走的就是这条路径。所以要判断某变体在当前阵列上可用与否，**必须真跑一帧**，不能只看 init 返回值。

## 证据（切片内命令 ↔ 结果）

- `python3 /tmp/probe_chain2.py 2>&1 | tail -30` →
  `=== A) afm761 profile + 网格清零 + music/dml:init 还是要逐帧跑? ===`
  `music: eChainInit -> 0; eChainDoa -> 3 (3=eErrNotImpl)`
- 同一探针在 **`[doa.scan]` 扫描网格清零**后结论不变（init 仍返回 0）——init 阶段不校验变体-阵列/网格兼容性。
- 旁证（docs 自陈，本会话未复现）：`docs/afm761_integration_study.md:256` → `music/dml → eErrNotImpl（§8.1 实证 music 不适用 3-z 阵）`。

## 为什么

变体-阵列兼容性（如 music/dml 不适用稀疏 3-z 阵）在 init 阶段不做判定，错误只在逐帧处理时以 `eErrNotImpl` 暴露。把 init 的 0 当作"该后端可用"，会把"跑起来才知道不支持"误诊成"配置没生效/参数没传对"，往错误方向排查。

## 边界 / 反例

- 只实测到 **music** 的 `eChainInit -> 0` / 首帧 `eChainDoa -> 3`；dml 在同一探针输出里被截断，未逐字取得其返回码，不要按"music 如此 dml 必如此"外推。
- 本条只断言当前实现的校验位置；若日后 `eChainInit` 加入阵列-变体判定，本条即失效，以代码为准。
- 与 `algommw-doa-beam-1d2d-auto-split` 相邻：那条讲 beam 变体内部的 1D/2D 分流，本条讲 init 不对任意变体做兼容性校验。
