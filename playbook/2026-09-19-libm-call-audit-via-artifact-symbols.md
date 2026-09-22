---
id: libm-call-audit-via-artifact-symbols
type: lesson
status: validated
scope: global
domain: verification
tags: [libm, nm, symbol-table, compiler-fusion, static-audit, sincos]
triggers:
  - "审计/门禁要判定『这份代码调用了哪些 libm 函数』，手段是源码 grep / 正则名字表"
  - "源码里 sincos 零命中，产物 nm -u 却出现 ___sincos_stret / ___sincosf_stret（失败信号）"
  - "要证明某个数学函数确实没被调用（或被禁用的函数没被调用），手上只有源码扫描一种证据"
  - "源码扫描结果与产物符号表对不上（失败信号：漏项、编译器融合、宏生成的调用）"
  - "验收门禁分『源码正则段』与『产物符号段』，要先定哪一段是真值层"
created: 2026-09-19
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b754-1b2d-7475-af70-36d1c8e07a6e
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [cpp-mode-libm-symbol-diff-per-tu, verify-dylib-port-completeness-via-nm-symbols, grep-alternation-count-cannot-prove-single-pattern-present]
---

# 判定 libm 调用面的真值层是**产物符号表**（nm -u），不是源码扫描

## 主张

「这段代码调用了哪些 libm 函数」不能只靠源码 grep/正则回答：编译器会把 `sin()` + `cos()` 融合成一次 `sincos` 调用，源码里 `sincos` 出现 **0** 次，而编出来的静态库里躺着一个未定义符号 `___sincos_stret`（float 版 `___sincosf_stret`）。所以源码名字扫描只是**检出层**，真值层是**已构建产物的符号表**（`nm -u <lib>.a` / `.o`）；两者必须分开表述，判「有没有调用」以产物为准。

## 为什么

- 源码里根本没有 `sincos(` 这个 token（0 命中），任何按名字写的源码门禁都永远看不到这个调用——它不是漏写模式，而是**调用发生在源码之外**（编译器生成）。
- 反过来，源码里写了 `std::exp2( x )` 也不保证按名字写的正则能命中：本会话把门禁 C 段正则套到这个探针上得到 `rg rc=1`（零命中），而同一对象的 `nm -u` 明明白白给出 `_exp2f`。
- 正则/计数给出的是「模式覆盖到的东西」，不是「产物实际引用的符号」；两者混用会把覆盖面问题误判成「没有调用」。

## 证据（切片命令 ↔ 结果）

1. 源码逐名计数（`core` 全树，每个名字单独数）：
   `for fn in sin cos sincos tan asin acos atan atan2 sinh cosh tanh exp exp2 log log2 log10 pow sqrt cbrt hypot fabs …; do …`
   ↳ `sin 42  cos 39  sincos 0  tan 0  asin 5  acos 0  atan 2  atan2 4  sinh 0  cosh 0  tanh …`
   —— 源码里 `sincos` 计数为 0。
2. 同一棵树已构建产物的符号表：
   `nm -u build/core/libcore.a | awk '{print $NF}' | grep -E '^_'`
   ↳ `=== nm -u build/core/libcore.a libm symbols === ___sincos_stret ___sincosf_stret _asin _atan _atan2 _cos _exp2 _log _log2 _…`
   —— 产物引用了 `sincos`（`___sincos_stret` / `___sincosf_stret`），源码扫描看不到。
3. 检出层漏报的对照实验：门禁 C 段正则（`C_PAT='(std::|::)(sin|cos|tan|asin|…'`）套到探针文件上
   ↳ `--- C regex on p_std.cpp (has std::exp2( x )) --- rg rc=1`（零命中）；
   同一探针对象 `nm -u p_std.o` ↳ `_exp2f`；`p_unqual.cpp`（非限定 `exp2( x )`）同样 ↳ `_exp2f`。
4. 同会话还跑过第三层清点：`clang++ -std=c++17 -fsyntax-only -Xclang -ast-dump` 全量 AST（dump 372062 行）+ 逐函数 `DeclRefExpr` 统计（切片只给到 dump 体量与统计标题，未展开计数结果——作为正则之外的另一条路，尚不能据本条证据断言其结论）。

## 边界 / 反例

- 真值只对**该次构建**成立：本会话读的是 `build/core/libcore.a`（切片里 `ls -la` 显示 Sep 18 20:33 构建）。源码改了不重新构建，符号表就是旧的。
- 符号名带平台/ABI 前缀（macOS：`_exp2`、`___sincos_stret`；探针对象是 `_exp2f`），跨平台比对前要先归一化前缀。
- 本会话没有做「不同编译器 / 不同 `-O` 档是否都融合 sincos」的对照（只用了 Apple clang 17.0.0 + `-std=c++17`），所以「融合总是发生」不在本条主张内；换工具链要重跑一次 `nm -u`。
- 产物符号表只覆盖真正被编译、链接进去的调用；未实例化的模板、未参与构建的 TU 不在其中。
- 本条只说「哪一层是真值」，不判被漏掉的调用有没有实际影响面（实例数另计）。
