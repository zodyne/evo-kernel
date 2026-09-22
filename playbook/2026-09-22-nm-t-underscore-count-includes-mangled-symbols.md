---
id: nm-t-underscore-count-includes-mangled-symbols
type: lesson
status: validated
scope: global
domain: c-abi
tags: [nm, mangled-symbols, counting, grep, c-abi]
triggers:
  - "在 nm 输出上统计未修饰 C 符号数（grep ' T _' / grep ' T __Z'）"
  - "审计 C ABI 完整度，要报『未修饰 N 个 / 已修饰 M 个』这类分类计数"
  - "分类计数相加超过 T 符号总数（失败信号：88 未修饰 + 4 已修饰 > 88 个 T）"
  - "grep 模式是另一模式的前缀（' T _' 与 ' T __Z'），计数出现包含关系"
  - "文档里的符号分类数字没有验算总和就直接引用"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b3e7-de9e-7475-af70-36a88ea79127
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [grep-alternation-count-cannot-prove-single-pattern-present, verify-dylib-port-completeness-via-nm-symbols, doc-selfreported-counts-drift]
---

# nm 的 `grep ' T _'` 计数把 ` T __Z`（C++ 修饰符号）也算进去，未修饰数必须显式减掉

**主张**：在 macOS `nm` 输出上统计「未修饰 C 符号」时，`grep ' T _'` 会同时匹配 ` T _eDoa...`（未修饰）和 ` T __Z...`（C++ 修饰），因为 `__Z` 也以 `_` 开头。未修饰数 = ` T _` 计数 − ` T __Z` 计数，不能直接把 ` T _` 计数当未修饰数。

**证据（本会话命令 ↔ 结果，只读复跑）**：

- `nm -g build/core/libcore.a | awk 'NF==3{print $2}' | sort | uniq -c` → `88 T`（全局 T 符号共 88 个）。
- `nm -g build/core/libcore.a | grep ' T _' | wc -l` → `88`；`... | grep ' T __Z' | wc -l` → `4`；紧接的显式差值命令回显 `=== explicit: ' T _' minus '__Z' ===`（88 − 4 = 84）。
- `nm -gU` 口径复核同样是 ` T _` = 88、` T __Z` = 4，与 `nm -g` 一致。
- 对照 PLAN.md:57（M6 C ABI 完整度）写的是「88 未修饰 / 4 已修饰（全部来自 `snap.h`）」——88 + 4 = 92 > 88 个全局 T，两个数不可能同时成立。实际 88 是「含修饰符号」的 ` T _` 总数，未修饰应为 84。

**为什么**：`grep ' T _'` 匹配的是「空格 T 空格下划线」这个前缀，而 C++ 修饰符号 `__Z...` 同样以 `_` 开头，天然落在这个前缀里。分类用的是两个有包含关系的模式，宽模式把窄模式的结果吞进去，只有显式做减法才能得到互斥的两类。

**边界 / 反例**：

- 只关心 T 符号总数时 `grep ' T _'` 是对的；错在把它当成「未修饰」这一类。
- `nm -gU`（仅已定义全局符号）与 `nm -g` 在本例给出相同计数（88/4），但过滤范围不同，别互相替代去支撑别的口径。
- 本会话只在 macOS `nm` + `libcore.a` 上实测；ELF `nm` 的符号格式不同，需另行验证。

**失败信号（未来命中即想起本条）**：写分类计数报告时各类相加大于总数，或用一条宽 grep 直接当「未修饰」数引用。

## 复核证据（2026-09-22，本机重跑 —— 本条据此进注入集）

原提案引的是 algommw-plus 当时的 `libcore.a`（88/4），那组数**现在已不复存在**
（该产物已重建，现为 135 个 `T`）。下列是**自包含最小复现**，与本机工具链绑定、可当场重跑：

```
$ printf 'int c_func(void){return 1;}\n' > c.c
$ printf 'int cpp_func(){return 2;}\n' > cpp.cpp
$ clang -c c.c -o c.o && clang++ -c cpp.cpp -o cpp.o && ar rcs libtest.a c.o cpp.o
$ nm -g libtest.a | grep -c ' T _'      # 2   ← 含修饰
$ nm -g libtest.a | grep -c ' T __Z'    # 1
$ nm -g libtest.a | grep ' T '
0000000000000000 T _c_func
0000000000000000 T __Z8cpp_funcv        ← 也以 _ 开头，被上一条 grep 一并计
```

**结论**：未修饰数 = ` T _` 计数 − ` T __Z` 计数；直接把 ` T _` 计数当未修饰数是错的。
（原提案「PLAN.md:57 的 88+4=92>88 自相矛盾」那半句是**对同一行文档的另一处独立缺陷**的判断，
与 `doc-metric-command-artifact-target-mismatch` 同源——见其条目；那半句依赖的锚点现已过期。）

> **同源（n 记账）**：本条与同一会话 `01a0b3e7-de9e` 的另 2 条提案同源于PLAN.md:57 的 M6 那一行——**一次观测被拆成多条**，别当独立经验计权。
> 更大一层：2026-09-18 那批有 3 个会话在 **33 秒内**先后启动、切片里「首条 user」逐字相同（对同一份 PLAN.md 的并行符合性审计），所以 A/B 两簇 12 条的**有效独立来源 ≈2 次**，不是 12 次。
> 另：`evo slice` 会**截断长命令**——凡依赖被截断部分的引用，只能算「当时跑过」。
