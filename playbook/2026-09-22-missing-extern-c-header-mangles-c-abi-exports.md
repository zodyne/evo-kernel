---
id: missing-extern-c-header-mangles-c-abi-exports
type: lesson
status: validated
scope: global
domain: c-abi
tags: [extern-c, name-mangling, nm, c-abi, cpp-port]
triggers:
  - "C++ 重写 C 库后审计 C ABI 完整度，nm 里出现 ` T __Z` 修饰符号"
  - "头文件没写 extern \"C\"，函数以 C++ mangled 名导出（失败信号）"
  - "要定位一个 __Z 修饰符号来自哪个头文件的声明"
  - "按 C ABI 导出的函数数少了一截，差值是少量 __Z 符号"
  - "C 调用方链接新库报找不到符号，源码里函数明明存在"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b3e7-de9e-7475-af70-36a88ea79127
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [verify-dylib-port-completeness-via-nm-symbols, cpp-mode-libm-symbol-diff-per-tu, mmw-cpp17-port-golden-equivalence]
---

# 头文件缺 `extern "C"` ⇒ 函数以 `__Z...` mangled 符号导出，是 C ABI 完整度缺口

**主张**：C++ 重写的 C 库里，头文件漏写 `extern "C"` 会让它声明的函数以 C++ 修饰名（`__Z...`）导出，而不是 C ABI 名。审计路径两步：`nm -g` 输出里找 ` T __Z` 符号，再到其声明头文件 `grep 'extern "C"'`——返回 NONE 即命中。

**证据（本会话命令 ↔ 结果，只读）**：

- `nm -g build/core/libcore.a | grep ' T __Z' | wc -l` → 4（全局 T 符号共 88）。
- 4 个修饰符号形如 `__Z15eDoaSnapExtractPK5xCUBEPK9xWAVE_CFGPK6xARRAYjjP10xCOMPLEX_F`、`__Z18eDoaSnapExtractRawPK5xCUBEPK9...`；demangle 后为 `eDoaSnapExtract(xCUBE const*, xWAVE_CFG const*, xARRAY const*, unsigned int, unsigned int, xCOMPLEX_F*)` 与 `eDoaSnapExtractRaw(...)`。
- `grep -n 'extern "C"' core/src/dpu/doa/snap.h` → `NONE in snap.h`。
- PLAN.md:57 的 M6 描述也标明这 4 个已修饰符号「全部来自 `snap.h`」。

**为什么**：`extern "C"` 关闭 C++ 的名字修饰（name mangling）与函数重载；缺了它，编译器按 C++ 规则生成 `__Z...` 链接名。对以 C 调用方为边界的库来说，这些函数在符号表上就不是 C ABI 符号——nm 上看是「已修饰」，C 侧链接则是找不到符号。

**边界 / 反例**：

- 本条只覆盖「声明所在头文件缺 `extern "C"`」这一种成因；函数定义处单独加 `extern "C"`、或 .c 文件整体按 C 编译等情形未在本会话验证。
- 修饰符号不必然是缺陷：C++ 内部实现导出 mangled 名是正常的；只有「本该是 C ABI 的接口」出现 `__Z` 才是缺口，判定要结合接口清单（本例是 DoA snap 系列）。
- 本会话 demangle 的 python 路径抛过一次 Traceback（切片里只保留到异常开头，原因未展开），最终换方式拿到了 demangled 名；复现时先确认 demangler 可用。

**失败信号**：C ABI 完整度统计里未修饰数对不上、差值恰是少量 ` T __Z`；或 C 调用方报 undefined symbol 而函数在源码中存在。

## 复核证据（2026-09-22，本机重跑）

原提案的证据（algommw-plus 的 4 个 `__Z` 导出、`snap.h` 缺 `extern "C"`）**载体已消失**
（`core/src/dpu/doa/snap.h` 现已被删除；当前 `libcore.a` 135 个 `T` 全是 `__Z`）。
下列自包含复现只演示**机制**：

```
$ printf 'int cpp_func(){return 2;}\n' > cpp.cpp          # 注意：无 extern "C"
$ clang++ -c cpp.cpp -o cpp.o && ar rcs libtest.a cpp.o
$ nm -g libtest.a | grep ' T '
0000000000000000 T __Z8cpp_funcv                           # 以 C++ 修饰名导出，不是 C ABI 名
```

**范围收窄**：本条只主张「缺 `extern "C"` ⇒ 该声明以 `__Z…` 导出」这一步（上表即证）。
原提案由「符号表里有 4 个 `__Z`」推出的后果——「C 调用方链接新库报找不到符号」——
**本次从未观测过链接/调用方测试**，属解释，不作为已验证事实。

> **同源（n 记账）**：本条与同一会话 `01a0b3e7-de9e` 的另 2 条提案同源于PLAN.md:57 的 M6 那一行——**一次观测被拆成多条**，别当独立经验计权。
> 更大一层：2026-09-18 那批有 3 个会话在 **33 秒内**先后启动、切片里「首条 user」逐字相同（对同一份 PLAN.md 的并行符合性审计），所以 A/B 两簇 12 条的**有效独立来源 ≈2 次**，不是 12 次。
> 另：`evo slice` 会**截断长命令**——凡依赖被截断部分的引用，只能算「当时跑过」。
