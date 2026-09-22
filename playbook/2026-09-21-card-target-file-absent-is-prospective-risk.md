---
id: card-target-file-absent-is-prospective-risk
type: lesson
status: validated
scope: global
domain: code-review
tags: [adversarial, severity, blocker, risk, construction-card, include-guard]
triggers:
  - "对抗式复核『施工卡将要新建的文件有缺陷』类发现，要在 confirm/refuted 与 blocker/risk 之间定级"
  - "机制在 /tmp 副本里手写复现成功，但目标仓库 HEAD 里这些文件尚不存在（失败信号：把前瞻缺陷当当前阻塞）"
  - "判『缺 include guard / 缺校验』类发现是否阻塞当前合并或验收"
  - "施工卡动作清单逐字要求写出某文件，复核要判『按卡执行时会不会真踩到』"
  - "复核报告要写 severity，手上只有 HEAD 副本的复现 rc=1，没有目标仓库里的实际文件"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-eca1-7475-af70-36bc7743f28f
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [synthetic-sandbox-mechanism-is-not-target-repo-risk, readonly-verify-tmp-variant-git-status-proof, inline-constexpr-header-still-needs-include-guard, blind-spot-claim-needs-instance-count]
---

# 施工卡将新建的文件在 HEAD 尚不存在时：事实成立，但定级为前瞻 risk 而非当前 blocker

## 主张

复核对象是**施工卡将要新建的文件**时，把「事实」与「严重度」分开判：（1）事实——在目标 HEAD 副本里按卡片动作清单**逐字**写出该文件，机制在编译下复现（rc=1）即 `isReal=true`；（2）严重度——目标 HEAD 里这些文件尚不存在（新建头只活在 /tmp 副本），这不是当前仓库的阻塞，而是执行该卡时会踩到的前瞻 risk。本会话最终裁决正是 `isReal = true（事实成立），但严重度应从 blocker 降为 risk`。

## 为什么

「机制存在」与「当前仓库已有该缺陷」是两个不同的断言；但也不能走向另一个极端——发现方复现所用的文件若是**卡片动作清单逐字要求写出的内容**，那它就是该卡执行路径上的真实输入，不是无关的自造沙箱，不能因此判 refuted。缺席证据（HEAD 没有文件）与路径证据（卡的动作就是写出它）合起来，指向「执行该卡时必然发生」这一档，而不是「现在就坏着」。

## 证据（切片命令 ↔ 结果）

- 目标 HEAD 无该文件：`ls -R core … ls core/include core/include/base` ↳ `core/include: base chain dpu math types  core/include/base: compiler.hpp types.hpp`（没有 `fp.hpp` / `libm.hpp`）；`git status --short` ↳ `?? docs/ledger/2026-09-18-P1.0b/  ?? inc_types.cpp`（无待落地的新头）。
- 按卡动作逐字写入 /tmp 副本：`cat > $R/core/include/base/libm.hpp <<'EOF' …`（副本 `…/repo`、`…/repo2`，仓库零改动）。
- 机制复现：`clang++ -std=c++17 -fsyntax-only -I core/include -I core/src …` ↳ `rc=1 … core/include/base/libm.hpp:9:15: e…`；补 guard 后 ↳ `rc=0 (after adding guard ONLY to fp.hpp) 0 error count = 0`。
- 末条 assistant：`结论：**isReal = true（事实成立），但严重度应从 blocker 降为 risk。**`；关键点 1 写「独立复现成功（全部在 /tmp/… 副本内，仓库零改动）：按动作 2/3 逐字写无 guard 的 fp.hpp/libm.hpp，按动作…」（切片在此截断）。

## 边界 / 反例

- 切片截断了末条 assistant 的完整定级理由；本条只主张可见的裁决与证据链，不复述未显示的理由。
- 对比 `synthetic-sandbox-mechanism-is-not-target-repo-risk` 的 isReal=false 情形：那条的证据载体与目标仓库无关（自造上下文）；本条的载体由**卡片动作文本**指定。若发现方只是随手手写、卡片并没有要求那种写法，则仍按 refuted 处理。
- 目标 HEAD 里该文件/形态已存在时，按当前 blocker 计，不适用本条。
- 文件缺席只说明「现在没有」，不降低卡片落地时的修复必要性：同会话已复现「只给 `fp.hpp` 加 guard 即 rc=0」的修复路径。
- 「按卡逐字写」要对着动作清单核到字面：卡动作若本身含守卫/校验，风险不成立。

## 失败信号（未来命中即该想起本条）

- 复核报告把「按卡片动作手写复现出的机制」直接升级成当前阻塞项，或反过来直接判 refuted，却不查目标 HEAD 有没有这些文件。
- 定级理由里出现「理论/前瞻」或「已是阻塞」的措辞，却拿不出文件存在性（ls / git status）证据。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
D=$(mktemp -d); mkdir -p $D/base $D/inc
printf '#include <cmath>\nnamespace amw { inline double sin(double d){ return std::sin(d); } }\n' > $D/base/libm.hpp
printf '#include "base/libm.hpp"\nnamespace amw { inline constexpr double dPi = 3.14159265358979323846; }\n' > $D/base/fp.hpp
printf '#include "base/fp.hpp"\n' > $D/inc/a.hpp
printf '#include "base/fp.hpp"\n' > $D/inc/b.hpp
printf '#include "inc/a.hpp"\n#include "inc/b.hpp"\nint main(){return 0;}\n' > $D/tu.cpp
clang++ -std=c++17 -fsyntax-only -I $D $D/tu.cpp; echo "rc=$?"
# => rc=1, 报 error: redefinition of 'sin' + redefinition of 'dPi'（fp.hpp 未加守卫，被 a.hpp/b.hpp 双重包含）
{ echo '#ifndef BASE_FP_H'; echo '#define BASE_FP_H'; cat $D/base/fp.hpp; echo '#endif'; } > $D/f && mv $D/f $D/base/fp.hpp
clang++ -std=c++17 -fsyntax-only -I $D $D/tu.cpp; echo "rc=$?"
# => rc=0（只给 fp.hpp 加守卫；libm.hpp 仍无守卫，但因只经 fp.hpp 可达，故不再重定义）
```

**审核给出的修改意见（要点）**：证据节三条命令（`cat > … <<'EOF' …`、`clang++ … -I core/src …`、加 guard 的 python heredoc）在切片里都被截断，且绑定当时的 /tmp 沙箱与 algommw-plus HEAD —— 该仓现 HEAD 已前移至 228f8ff，core/include/base/ 下已存在带守卫的 fp.hpp/libm.hpp，故『目标 HEAD 无此文件』这一前提只是过去快照、已不可复验。主张真值本身（复核定级方法）稳定，且机制可用本机 clang++ 自包含复现 ⇒ 留在注入集，但把证据换成 minimalRepro 那条命令（不依赖目标仓、不依赖沙箱）。另两处收窄：(1) `为什么` 给的定级理由（缺席证据＋路径证据 →『执行该卡时必然发生』）对应的末条 assistant 正文在切片里已截断，与本条 `边界` 首句「不复述未显示的理由」自相矛盾——把 `为什么` 明确标注为对可见裁决的合成，或只保留机制侧、定级理由压成一句；(2) 主张里的『前瞻』是条目加的限定词（切片只说『降为 risk』），建议保留但注明其依据是『HEAD 无该文件』这一事实。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
