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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
在 scratchpad 实跑通过（mre2/）。自包含最小复现（合成 3 文件，不依赖 algommw-plus / 旧沙箱）：

set -e
D=$(mktemp -d); cd "$D"; mkdir -p inc repl ins
printf '#pragma once\n#define F 1\n' > inc/fp.hpp
printf '#pragma once\nnamespace amw { using Real_t=float; struct ComplexF_t{Real_t r,i;}; }\n' > inc/types.hpp
printf '#include "types.hpp"\nnamespace amw { Real_t scale(Real_t); ComplexF_t mk(); }\n' > canon.hpp
sed '1s|.*|#include "fp.hpp"|' canon.hpp > repl/a.hpp      # REPLACE: 首条 include 被顶掉 -> 丢 types.hpp
{ echo '#include "fp.hpp"'; cat canon.hpp; } > ins/a.hpp   # INSERT: 新头插首行 -> 保留 types.hpp
printf '#include "a.hpp"\nint main(){ amw::Real_t r=amw::scale(1.0f); amw::ComplexF_t c=amw::mk(); (void)r;(void)c; return 0; }\n' > user.cpp
clang++ -std=c++17 -Iinc -Irepl -c user.cpp -o /dev/null 2>repl.log; echo "REPLACE rc=$?"; grep -o "error: [^\"]*'" repl.log | sort | uniq -c
clang++ -std=c++17 -Iinc -Iins  -c user.cpp -o /dev/null 2>ins.log;  echo "INSERT rc=$?"; wc -l < ins.log

实测输出：
REPLACE rc=1
  2 error: unknown type name 'Real_t'
  1 error: unknown type name 'ComplexF_t'
INSERT rc=0   (ins.log 0 行)

即与主张同形：字面 replace 首条 include → unknown type name 公共类型；insert → rc=0。真值与语言/方法绑定、现可复跑。
```

**审核给出的修改意见（要点）**：证据节整体被绑在已消失的 /tmp 沙箱（/tmp/review-refute-literal-first-include-replacement-drops-types/）+ 自写脚本 apply_card.py + algommw-plus 的 2026-09-19 HEAD 上：那条 tally 当时是 27，现已推进为 fp.hpp×30 / types.hpp×2（本机实测），旧命令一条也照抄不了。核心主张（「第一条 include 改为 X」按字面 replace 会顶掉承载类型定义的首条 include → 下游整库报 unknown type name；应改按 insert）是稳定的 C++ 属性，已用自包含最小复现当场复跑（见 minimalRepro），故保留在注入集。改法：(1) 证据节把上述快照性引用降为背景，主证据换成 minimalRepro 里的合成复现（含期望 REPLACE rc=1 + unknown type name、INSERT rc=0）；(2) 主张末句「必须按插入执行，不能按替换」把限定直接并进句子——「仅当被替换的首条 include 承载下游必需定义时 replace 才炸」，别只把限定留在边界节（否则单次观测被读成无条件一般律）；(3) 注明数字 27 在切片内另有 26 的计数、且仓库现况已变，数字只作当时快照；(4) 证据节

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
