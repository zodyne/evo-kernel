---
id: literal-first-include-replace-drops-types
type: lesson
status: validated
scope: global
domain: cpp-build
tags: [include, refactor-card, literal-execution, unknown-type-name, algommw]
triggers:
  - "施工卡/PLAN 写『每个 core 头的第一条 include 改为 `#include \"base/fp.hpp\"`』，要照着批量改"
  - "按字面 replace（而不是 insert）首条 include 后，编译报 `error: unknown type name 'Real_t'` / `'ComplexF_t'`（失败信号）"
  - "头文件里『原先承载类型定义的那条 include』被新头替换掉，全库类型找不到定义"
  - "要把新头文件设成每个头的第一条 include，犹豫该插入还是替换"
  - "复核『这条改造会让构建挂掉』类发现，要在同源两份副本上做 replace vs insert 对照"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-ecee-7475-af70-36be1d4ba92f
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [algommw-real-t-switchable-typedef]
---

# 「第一条 include 改为 X」按字面 replace 执行 = 静默删掉承载类型定义的首条 include

## 主张

对 32 个 core 头里首条是 `#include "base/types.hpp"` 的 27 个（`first-include == base/types.hpp : 27`）执行 PLAN 字面语义的 **replace**（首条 include *换成* `#include "base/fp.hpp"`，原 include 被删）后，`core` 库编译炸出 `98 error: unknown type name 'Real_t'` + `39 error: unknown type name 'ComplexF_t'`（rc=2，无产物）；同样这批头改成 **insert**（`base/fp.hpp` 插为首行、**保留**原 `base/types.hpp`）则 `core` 目标 rc=0 并产出 `build/core/libcore.a`（106136 bytes）。所以「第一条 include 改为 X」必须按**插入**执行，不能按替换。

## 为什么

`base/types.hpp` 是 core 的公共类型入口（`Real_t` / `ComplexF_t` 由它带入）。把「首个 include」这一行**替换**掉，等于把类型入口从 27 个头里同时摘除：这些头自身、以及所有 include 它们的 TU 立刻失去类型定义，报错面是整库级的 `unknown type name`，与 `fp.hpp` 本身无关。措辞「第一条 include 改为 X」只约束新 include 的位置，不蕴含删除原 include —— 两种读法的产物只差一行，编译结果却是 0 错 vs 整库失败。

## 证据（本会话切片，命令 ↔ 结果）

在 `/tmp/review-refute-literal-first-include-replacement-drops-types/` 内对 `/Users/zodyne/Dev/algommw-plus` 的两份同源副本做只差一个变换的对照（`python3 apply_card.py repo_lit replace` / `repo_ins insert` → `mode=replace headers=32 cpps=25` / `mode=insert headers=32 cpps=25`）：

- REPLACE（字面替换）：`cmake --build build --target core -j1` → `REPLACE build rc=2`，错误分类为 `98 error: unknown type name 'Real_t'`、`39 error: unknown type name 'ComplexF_t'`；最终对照行 `[INSERT] 106136 bytes 0 error: lines [REPLACE] …`——REPLACE 侧无 `libcore.a`。
- INSERT（保留原 include）：唯一残留错误是无关的 `core/src/dpu/doa/music.cpp:177`（补掉后）→ `INSERT(patched music 176/177) build rc=0` + `…/build/core/libcore.a 106136 bytes`。
- 首条 include 归属统计（finding 的原始 tally 命令复跑）：`first-include == base/types.hpp : 27`。
- 反向的「抢救」变体 `REPLACE + fp.hpp-includes-types`（让 `fp.hpp` 回头 include `types.hpp`）**仍失败**：`rc=2 error lines: 22 no libcore.a`——即结构上被删掉的那条 include 不能靠新头反向包含救回来（机制未在本会话定位，仅记录现象）。

## 边界 / 反例

- 只有「替换语义 + 被替换的首条 include 承载下游必需定义」才炸；同样这批头的 **insert** 语义不炸（上面就是对照）。
- 本会话前几轮 REPLACE 的错误行数在 20 / 182 / 247 之间跳动（副本重拷、转换脚本迭代所致），不能拿某一轮的行数当结论；稳定的是最终那轮「同源两副本、只差一个变换」的 rc 与产物差异。
- `unknown type name` 的报错点不在被改的头文件里（先挂的是 `src/types/mount.cpp.o` 等下游 TU），只看改过的文件容易误判「改动无害」。
- 逐 TU 用 `clang++` 单独编译探针时，`core/src/chain/chain.cpp` 缺 `-I` 会先报 `fatal error: 'chain/chain.hpp' file not found`——那是探针的命令行问题，不是本条主张的失败（见 related 的引号包含解析条目）。

## 失败信号（未来命中即该想起本条）

批量改完 include 后 `cmake --build` 在**没改过的**下游 TU 上大面积报 `error: unknown type name '<Real_t 之类的公共类型>'` → 先 diff 一下被改头的首条 include 是不是被新 include **顶掉**了，而不是只加了新 include。
