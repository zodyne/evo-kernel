---
id: auto-branch-skips-explicit-validation
type: lesson
status: candidate
scope: global
domain: code-review
tags: [config, validation, auto-route, review, algommw, doa]
triggers:
  - "配置项支持 auto/自适应派生（如 variant=auto），要审查校验是否覆盖所有分支"
  - "显式分支有『必填段』校验，auto 分支是否同样有（失败信号：只有显式分支抛错）"
  - "配置加载成功，但生效的后端/参数是另一条路径算出来的（失败信号）"
  - "写 profile 时用 auto 省掉必填段，下游却按需要该段的实现跑"
  - "reviewer 要核对『声明配置』与『生效配置』是否一致"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a5f0-9954-7353-8a3d-42d3da5cbafa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [validation-params-readable-from-artifact, algommw-doa-beam-1d2d-auto-split]
---

**主张**：配置解析里只要存在"auto / 派生 / 默认"分支，就不能假定显式分支上的前置校验覆盖了它——auto 路径常先由路由算出实际取值、再走另一段赋值逻辑，而校验代码留在显式分支（`if/elif` 的另一支）里，于是被绕过。审查配置校验或自测时，必须**单独把 auto 路径走一遍**，确认每个前置约束仍然生效。

**为什么**：auto 分支把"用户声明的值"替换成"路由算出的值"，校验却往往照声明值写；两条路径赋值点不同，漏一条不报错——配置能加载成功，下游按另一种实现跑，直到运行时报错或静默给错结果。

**怎么做**：
1. 定位分支与校验归属：`rg -n 'if <field> == "auto"|config\.<field> = ' <config.py>`，把 auto 分支起止行、显式分支的校验行都列出来，用缩进判断校验属于哪一支。
2. 让 auto 路由产出**每一个**可能的后端/模式，逐个检查各自的必填约束是否也在 auto 分支上执行。
3. 对照下游消费侧：确认缺失必填段时，core 侧会不会拿到非法输入（本例 `core/src/chain/chain.c:88-92` 按生效枚举直接使用网格配置）。

**证据（session:01a0a5f0…，algommw 审查 finding #1，medium）**：
- 切片里 `rg` 命中 `python/core_bind/config.py`：`479: if variant_str == "auto":` 与 `489: if variant == dtypes.E_DOA_VARIANT_DBF2D and _scan_table(d)[1] is None:` —— 会话结论是该 `[doa.scan]` 必填校验只在显式分支（489-494），auto 分支没有。
- auto 路由实测（探针加载 `profiles/afm761_ddm`）：`config: doa=auto -> dbf2d (doa route: irregular/sparse array (real coords) → dbf2d)`，即稀疏阵的 auto 结果正是需要 `[doa.scan]` 的 dbf2d 后端。

**边界**：本条"跳过校验"的结论来自代码阅读（切片只提供分支行号与 reviewer 结论），故 `verified_by: human`；复验最直接的一枪是构造一份 `variant="auto"` 且**缺** `[doa.scan]` 段的 profile，看加载是否报错——跑通即证实、报错即推翻。另：若 auto 分支与显式分支共用同一个后置校验函数，则本条不适用，判定前先确认校验不在公共尾段。
