---
id: algommw-dbf2d-not-config-enum-only
type: fact
status: candidate
scope: project:algommw-plus
domain: radar-doa
tags: [algommw, algommw-plus, dbf2d, doa, conformance-audit, chain-c]
triggers:
  - "审阅/引用 algommw-plus PLAN.md:291 里『eDoaVariantDbf2d 只在配置枚举里存在』这一断言"
  - "判断 dbf2d 是配置兼容别名还是可执行 DOA 变体（失败信号：只查枚举定义就下结论）"
  - "核对 variant=dbf2d 的必填配置（[doa.scan] 扫描表）与绑定层校验位置"
  - "审计方案文档的『只在 X 层存在』类存在范围断言，要与执行层 case 分发对照"
  - "在 chain.c 看到 `case eDoaVariantDbf2d` 却当成历史残留（失败信号）"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b3e8-3b01-7475-af70-36ab077aec46
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [algommw-sparse-3z-array-needs-dbf2d-full-grid, algommw-doavariant-init-ok-frame-notimpl, algommw-doa-beam-1d2d-auto-split]
---

# `eDoaVariantDbf2d` 不是「只在配置枚举里存在」：执行分发、路由、绑定校验三层都有它

**主张**：algommw-plus 的 PLAN.md:291 写「`eDoaVariantDbf2d` 只在配置枚举里存在（它本来就是 beam + 网格，ADR 0008）」，但代码实况是三层都有它：执行分发有 `case eDoaVariantDbf2d`（chain.c:98、:345），route 把非格点几何路由给它（route.c:6、:13 注释），绑定层有独立枚举值 `E_DOA_VARIANT_DBF2D = 3`（dtypes.py:70）且 `variant=dbf2d` 强制要求 `[doa.scan]` 扫描表（config.py:492）。本会话对该断言的最终裁决是 `overstated`——原始事实成立，但等级过高，PLAN 主张应为 `partial` / `minor`。把 dbf2d 当「配置别名」处理会漏掉这些真实分支。

**为什么**：审方案文档时，「只在配置枚举里存在」这类**存在范围断言**必须回到执行层（`rg 'case <枚举名>'`）与绑定层校验去核对；只读枚举定义/ADR 叙述会把「仍然可被派发执行」的变体误判成纯兼容项。同理，看到 case 分支也不能只凭 PLAN 的一句话就当历史残留删改。

**证据（会话切片 01a0b3e8，命令 ↔ 结果）**：
- `cd algommw-plus && rg -n -i "dbf2d" PLAN.md` → `291:- 「恰好一个变体活跃」从注释变成类型约束；eDoaVariantDbf2d 只在配置枚举里存在（它本来就是 beam + 网格，ADR 0008）。`
- `rg -n 'case eDoaVariantDbf2d' core/src/chain/chain.c | cat -n` → 2 处：`98: case eDoaVariantDbf2d:`、`345: case eDoaVariantDbf2d: /* 同一估…`（切片在此截断）。
- `rg -n "Dbf2d|DBF2D|dbf2d" core/src/chain/chain.c core/src/chain/route.c` → `route.c:6: …整数格且行/列全覆盖)走谱峰法 beam;其余走 dbf2d(F4 起:任意几何暴力扫描…`、`route.c:13: route 只把能安全走 beam…`。
- `cd ../algommw && rg -n 'E_DOA_VARIANT_DBF2D = 3' python/core_bind/dtypes.py` → `70:E_DOA_VARIANT_DBF2D = 3`；`rg -n 'requires a \[doa.scan\] scan table' python/core_bind/config.py` → `492: "profile: [doa] variant=dbf2d requires a [doa.scan] scan table"`。
- `find ../algommw … -name "0008*"` → `./docs/adr/0008-merge-doa-dbf2d-into-beam.md`（ADR 0008 在 algommw 侧，不在 plus 的 docs/adr/ 首条清单里）。

**边界 / 反例**：
- 本条的否证对象是 PLAN.md:291 的措辞（「只在配置枚举里存在」），不是「dbf2d 该不该保留」；本会话最终只把该主张定为 `partial` / `minor`，未判 PLAN 整体错误。
- 切片未展开 chain.c:345 case 的完整注释（`/* 同一估…` 截断），也未证明 plus 的目标 C++ core 会保留这些分支；不要把本条外推成「重写后 dbf2d 仍是独立路径」。
- chain.c 的 case 命中来自 algommw-plus 仓内的 C core；dtypes.py/config.py 命中来自 `../algommw` 的 `python/core_bind`，两边不要混记成一个仓的同一层。
