---
id: include-closure-per-tu-impact-count
type: lesson
status: validated
scope: global
domain: cpp-headers
tags: [cpp, header, include-closure, impact-analysis, include-guard, per-tu]
triggers:
  - "要判一批新写/被改的 C++ 头文件影响哪些编译单元（TU），准备写影响面或严重度"
  - "只数了『谁直接 include 这个头』（一跳入度）或头文件自身的 include 行（出度）就要下影响面结论（失败信号）"
  - "复核『缺 include guard 会重定义』类发现，需要在目标产物里指出哪些 TU 真的会重复包含"
  - "新增共享头（fp.hpp / libm.hpp 这类）要评估被多少 TU 间接拉到、有没有 TU 拉 ≥2 次"
  - "报告要写『受影响 TU 数』，手上只有直接 include 者清单"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-eca1-7475-af70-36bc7743f28f
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [zero-include-header-still-has-includers, inline-constexpr-header-still-needs-include-guard, blind-spot-claim-needs-instance-count]
---

# 头文件影响面按「每个 TU 的 include 闭包」计数，而不是一跳入度/出度

## 主张

判一批新写/被改头文件的影响面时，按**每个 TU 的 include 闭包**统计它命中的待改头（出现次数）：命中 ≥1 给出受影响 TU 集；同一个无 guard 头在同一个 TU 的闭包里出现 ≥2 次，就是该 TU 的必然重复包含 ⇒ 必然重定义路径。实测 `core/src` 25 个 TU 中 24 个的 include 闭包命中 ≥1 个新写头（脚本另统计 ≥2 的 "guaranteed redefinition" 档）。

## 为什么

编译器报重定义的粒度是 **TU**，不是头或边：一个头只被 A 直接 include 一次，但 A 同时被 B、C 包含且两者再各自拉一次，同一 TU 里就会出现两次。一跳入度（谁直接 include 它）和出度（它自己 include 了谁）都只是依赖图的局部边，回答不了「编译器在这个 TU 里到底看到几次」。闭包计数才是与编译单元实际内容对应的量，也正好给「机制可复现」补上 `blind-spot-claim-needs-instance-count` 要的实例数。

## 证据（切片命令 ↔ 结果）

- `python3 - <<'PY' … root="/tmp/review-refute-core-fp-libm-missing-include-guards/repo2" …`（展开每个 `core/src` TU 的 include 闭包，对待改头计数）
  ↳ `core/src TUs total: 25  TUs whose include closure pulls >=1 patched core header: 24  TUs pulling >=2 (guaranteed redefinit…`（切片在该行截断，只剩 25 / 24 两个数可见）。
- 同会话机制侧旁证：`clang++ -std=c++17 -fsyntax-only -I core/include -I core/src …` → `rc=1 … fatal error: too many errors emitted, stopping now [-ferror-limit=] … core/include/base/libm.hpp:9:15: e…`；只给 `fp.hpp` 补 guard 后 → `rc=0 (after adding guard ONLY to fp.hpp) 0 error count = 0`。

## 边界 / 反例

- 计数要按**出现次数（多重性）**；只数 distinct 头数时，闭包里有两个不同的无 guard 头并不必然重定义（除非一个包含另一个）。本切片未展示脚本的计数口径，复用时按多重性实现，并用一次逐 TU 语法编译核对。
- 闭包只覆盖按字面 `#include` 的可达路径：宏拼接头名、`-include` 强制包含、构建系统 GLOB 不在内，需要时用编译器的 `-H`/`-M` 或逐 TU 编译兜底。
- 闭包命中 ≠ 一定报错：头有 guard（或重复定义被宏挡住）时多次包含无害；本条只用来圈定候选 TU 集与必然路径。
- 25/24 两个数是该仓库 2026-09-19 快照；换仓库/换头集必须重算。

## 失败信号（未来命中即该想起本条）

- 影响面报告只给「谁直接 include 了这个头」或「这个头自己有 0 行 include」就写 N 个 TU 受影响。
- 声称「缺 guard 会在多个 TU 炸」却说不出任何一个 TU 里这个头被包含了几次。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
D=$(mktemp -d); mkdir -p "$D/inc"
printf 'struct Foo { int x; };\n'                 > "$D/inc/h.hpp"   # 无 guard 的叶子头
printf '#include "h.hpp"\n'                        > "$D/inc/m.hpp"   # 拉到 h.hpp
printf '#include "m.hpp"\n'                        > "$D/inc/a.hpp"
printf '#include "m.hpp"\n'                        > "$D/inc/b.hpp"
printf '#include "a.hpp"\n#include "b.hpp"\nint main(){return 0;}\n' > "$D/t.cpp"

grep -rl '#include "h.hpp"' "$D/inc" | wc -l
#   -> 1        （一跳入度：h.hpp 只被 m.hpp 直接 include 一次，看不出重复）
clang++ -std=c++17 -E -I "$D/inc" "$D/t.cpp" | grep -c 'struct Foo'
#   -> 2        （闭包多重性：该 TU 里 h.hpp 的体出现 2 次）
clang++ -std=c++17 -fsyntax-only -I "$D/inc" "$D/t.cpp"; echo "rc=$?"
#   -> error: redefinition of 'Foo'  @ …/inc/h.hpp:1:8 ; rc=1

printf '#ifndef H_HPP\n#define H_HPP\nstruct Foo { int x; };\n#endif\n' > "$D/inc/h.hpp"
clang++ -std=c++17 -fsyntax-only -I "$D/inc" "$D/t.cpp"; echo "rc=$?"
#   -> rc=0      （只给这一个无 guard 头补 guard，编译即通过）
```

**审核给出的修改意见（要点）**：核心主张（按「每个 TU 的 include 闭包」多重性计数，而非一跳入度/出度）是 C++ 预处理器的稳定性质、通用且正确，值得留在注入集。但证据节的两条命令在切片里都被截断（python 的 root= 断在路径中；clang++ 断在被编译 TU 路径），且承载它们的 /tmp/…-include-guards 沙箱已消失 ⇒ 现证据无法照抄重跑。改法（换证据，非改主张）：(1) 把证据节主证据换成上面的自包含最小复现（本机可跑，已实测：入度=1 / 多重性=2 / rc=1→补 guard→rc=0）；(2) 把 25/24 降为「该仓库 2026-09-19 快照的示例数字」，明标不随主张走（条目边界已如此声明，保持即可）；(3) 可选收窄措辞：主张里「≥2 次 ⇒ 必然重定义路径」改为「⇒ 该 TU 里必然重复包含（是否报错取决于头内容，见边界节）」，与边界节「闭包命中 ≠ 一定报错」保持一致。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
