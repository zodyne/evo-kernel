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
