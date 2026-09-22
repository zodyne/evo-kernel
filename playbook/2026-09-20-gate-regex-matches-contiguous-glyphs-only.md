---
id: gate-regex-matches-contiguous-glyphs-only
type: lesson
status: validated
scope: global
domain: verification
tags: [regex, gate, bypass, whitespace, adversarial, source-scan]
triggers:
  - "设计/复核『用 grep 正则封死某类写法』的源码闸门（如封 `std::sin(` 这类限定调用）"
  - "闸门正则按连续字形写（`(std::|::)(sin|cos|…)`），准备宣布『唯一漏网口已封死』之前"
  - "对抗复核源码正则闸门——写探针覆盖空白/括号等排版变体，逐形态套原样闸门命令"
  - "闸门测试全 CAUGHT，但测试形态全是无空白的连续写法（失败信号：变体面没覆盖）"
  - "限定符里插入空白（`std :: sin (`）或函数名外再加括号（`(std::sin)(`）的等价调用没被闸门命中（失败信号）"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b753-e147-7475-af70-36ce8acff051
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [libm-symbol-chosen-by-arg-type-not-call-syntax, blind-spot-claim-needs-instance-count, single-segment-miss-is-not-a-gate-hole, substring-matcher-cannot-tell-exec-from-mention]
---

# 按连续字形写的正则闸门只封连续字形，不封等价写法

## 主张

用 grep/正则给源码闸门封口时，形如 `(std::|::)(sin|cos|…)` 的模式**只匹配限定符与函数名之间没有任何分隔的写法**：在限定符里插入空白（`std :: sin (`）、或给函数名再套一层括号（`(std::sin)(`），都会从同一张正则下漏过。宣布「这个漏网口已被 grep 封死」之前，必须把这些**等价写法变体当成独立形态**，逐个套用闸门的原样命令。

## 为什么

grep/正则匹配的是字符序列，不是语法：`std::sin(` 与 `std :: sin (` 在 C++ 里是同一个调用，在正则眼里是两个完全不同的串。闸门的覆盖面只能由「形态矩阵」给出——连续字形被 CAUGHT，不代表等价写法被封住。

## 证据（切片命令 ↔ 结果）

本会话对抗复核卡 P1.0b 的 G1-C 封口正则，做法是形态矩阵：

1. 仓库只读，把 `core` 复制到 `/tmp/review-refute-c-gate-regex-bypass-forms/core`，在 `core/src/zzforms/` 植入形态文件：
   `== files planted == f1_std_contig.cpp f2_global_contig.cpp f3_amw_contig.cpp f4_space_in_qualifier.cpp f5_paren_qualifie…`
   —— 形态分类即：连续 `std::` / 连续 `::` / `amw::` / **限定符内插空白** / **函数名加括号**。
2. 对每个植入文件套用卡片原样闸门命令（`per-form: card regex applied to each planted form file`），可见部分结果：
   `CAUGHT  f1_std_contig.cpp: 1:void f(){ double x=0; std::sin(`
3. 末条 assistant 裁决：**该发现为真，无法推翻**；`form_matrix.log` 汇总为「正则确实只抓连续字形」——卡片原样命令 CAUGHT `std::sin(` / `::sin(` / `amw::sin(`，空白/括号变体不在其覆盖内。
4. 被复核对象的自我声明（`PLAN.md:265`、`:314`）是「**唯一漏网口**是限定调用 `std::sin(`/`::sin(` 绕过遮蔽 ⇒ G1-C 用 grep 封死」——闸门的设计前提正是「列全漏网写法」，而实测只覆盖连续字形。

## 边界 / 反例

- 本条只主张「连续字形正则漏掉分隔变体」，不判这些变体在目标仓库的实际出现次数（严重度另计）。
- 覆盖变体面 ≠ 覆盖全部语法：探针形态清单本身也可能不全（换行、行内注释、宏拼接、`using` 引入后的非限定调用）；形态矩阵只证明「测过的那些」被封住。
- 修法方向有二：把闸门升级为语法/产物层判据，或在正则里显式容纳分隔（`std\s*::\s*sin\s*\(`）——两条路都要重新跑一遍形态矩阵复验。
- 与 `libm-symbol-chosen-by-arg-type-not-call-syntax` 互补：那条讲「写法不改变 `nm -u` 符号」，本条讲「写法改变源码正则的覆盖面」，两件事不要混。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
cd /tmp && rm -rf gate_repro && mkdir -p gate_repro/core/src/zzforms && cd gate_repro
printf 'void f(){ double x=0; std::sin( x ); }\n'     > core/src/zzforms/f1_std_contig.cpp
printf 'void g(){ double y=0; ::sin( y ); }\n'       > core/src/zzforms/f2_global_contig.cpp
printf 'void h(){ double z=0; std :: sin ( z ); }\n' > core/src/zzforms/f4_space_in_qualifier.cpp
printf 'void k(){ double w=0; (std::sin)( w ); }\n'  > core/src/zzforms/f5_paren_qualifier.cpp
C='(std::|::)(sin|cos|tan|asin|acos|atan|atan2|sqrt|exp|log|log2|log10|pow|fabs|floor|ceil|round|lround|fmod|hypot)\s*\('
for f in core/src/zzforms/*.cpp; do rg -q "$C" "$f" && echo "CAUGHT $(basename $f)" || echo "MISSED $(basename $f)"; done

# 实测输出（2026-09-22，/opt/homebrew/bin/rg）：
# CAUGHT  f1_std_contig.cpp
# CAUGHT  f2_global_contig.cpp
# MISSED  f4_space_in_qualifier.cpp
# MISSED  f5_paren_qualifier.cpp
#
# 对照：换成条目所写的缩写模式 `(std::|::)(sin|cos)`，f5 变 CAUGHT（证明条目引用的模式漏了 \\s*\\( 这一载荷）。
```

**审核给出的修改意见（要点）**：主张本身成立且可当场复现（正则按字符序列匹配，`std :: sin (` 与 `(std::sin)(` 都逃出真实卡正则 `(std::|::)(…)\s*\(`），所以该条有资格留在注入集，但证据/引文要修两处：(1) 把卡正则按原样补全为 `(std::|::)(sin|cos|…|hypot)\s*\(` 并点明『尾部 `\s*\(` 是 `(std::sin)(` 漏网的唯一原因』——现文写的 `(std::|::)(sin|cos|…)` 会命中 `(std::sin)(`，与同条括号例自相矛盾（切片截断把 `\s*\(` 切掉了，属照抄截断部分的连带错误）。(2) 证据 4 的 `PLAN.md:265` 引用已随产物改写（现 284 行，且已把空格形态纳入漏网口），改为标注『会话当时快照』或替换成可复核的产物，别让读者去当前 PLAN.md 找不存在的行。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 形如 `(std::|::)(sin|cos|…)` 的模式**只匹配限定符与函数名之间没有任何分隔的写法** —— 条目把卡正则抄漏了尾部的 `\s*\(`：真实卡正则是 `(std::|::)(sin|cos|…|hypot)\s*\(`。正是这条尾部要求使 `(std::sin)(` 漏网；按条目现写的缩写模式，`(std::sin)(` 反而**会**被命中（实测 CAUGHT），条目自身主张与自身引用的模式互相矛盾。截断源：切片第 40 行对 `rg -n '(std::|::)(sin|cos|tan|asin|acos|atan|` 的命令截断，把 `\s*\(` 切掉了。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
