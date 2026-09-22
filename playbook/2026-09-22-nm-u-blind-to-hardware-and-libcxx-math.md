---
id: nm-u-blind-to-hardware-and-libcxx-math
type: lesson
status: validated
scope: global
domain: cpp-toolchain
tags: [libm, nm, disassembly, macos, libc++, sqrt, lround, symbol-audit]
triggers:
  - "用 nm -u 列 libm 依赖，准备下『某个 TU/库没有调用 sqrt / lround』或『依赖面只有符号表这些』的结论"
  - "源码里明明写了 std::sqrt / std::lround，产物 nm -u 里却找不到 _sqrt / _lround（失败信号）"
  - "审计/门禁的产物符号段只扫未定义符号（nm -u，不含 nm 全表），要判它能不能覆盖全部数学调用"
  - "反汇编里出现 fsqrt 指令或 __ZNSt3__16__math… 调用，与按 nm -u 列的数学符号清单对不上（失败信号）"
  - "逐 TU 比对数学符号时，某 TU 的 nm -u 数学符号为空但源码有 math 调用，被当成『该 TU 无 libm 依赖』（失败信号）"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74c-b02e-7475-af70-36baf60d9399
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [libm-call-audit-via-artifact-symbols, libm-symbol-chosen-by-arg-type-not-call-syntax, cpp-mode-libm-symbol-diff-per-tu]
---

# `nm -u` 不是数学调用依赖的完备真值面：硬件指令与 libc++ 内部 weak 包装都不在未定义符号里

## 主张

`nm -u`（只看**未定义**符号）会漏掉两类真实存在的数学调用：(1) 被编译器降成硬件指令的 `sqrt`——Apple arm64 上是 `fsqrt`，根本没有 `_sqrt` 符号；(2) 走 libc++ 内部包装的 `std::lround`——调用落在 `std::__math::lround`，该包装以 weak / `.private_extern` 定义在**同一个 `.o` 内**，不是未定义符号。因此按 `nm -u` 数 libm 依赖会得出「没有调用 sqrt / lround」的错误结论；产物侧审计要再补两层：反汇编（`clang -S` / otool / objdump）看指令与调用目标，以及 `nm`（非 `-u`）/ `nm -g` 看对象内定义的 weak 符号。

## 为什么

`-u` 这个过滤器只回答「本对象还需要谁来提供符号」，不回答「本对象里执行了哪些数学操作」：硬件指令不产生符号引用；库里自带的实现（libc++ 的 `__math` 包装是 inline/weak 定义，可能就在本 `.o` 里发射）也不需要外部提供符号。这两类调用在 `nm -u` 里完全隐形，但在行为与数值上都是实实在在的数学调用。已入库的 `libm-call-audit-via-artifact-symbols` 说「产物符号表比源码扫描更接近真值」——本条是它的边界：`nm -u` 本身也有洞，真值要多层证据拼。

## 证据（本会话切片，命令 ↔ 结果）

1. 对 `core/src/dpu/doa/beam.cpp` 编译出汇编（切片中命令尾部截断：`clang++ -x c++ -std=c++17 -O0 -ffp-contract=off -fno-exceptions -fno-rtti -I…core/include -I…`）：
   `↳ 803: bl __ZNSt3__16__math6lroundB8nn200100Ef  2211: fsqrt d0, d0  2245: .private_extern __ZNSt3__16__math6lroundB8nn200100Ef`
   —— 既出现了 `std::lround` 的调用目标（`std::__math::lround(long lround(float))`），又出现了 `fsqrt` 硬件开方指令；注意探针用的是 `-O0`，不是只有优化档才会这样。
2. 读该汇编里 `__math::lround` 的定义段：
   `sed -n '2245,2310p' /tmp/review-scan-gate/beam.s`
   `↳ .private_extern __ZNSt3__16__math6lroundB8nn200100Ef ; -- Begin function _ZNSt3__16__math6lroundB8nn200100Ef .globl __`
   —— 该包装的机器码就发射在本对象内（weak/private），链接时无需外部符号。
3. 对同一 TU 的目标文件查未定义符号：
   `nm -u core_src_dpu_doa_beam.cpp.o | grep …`（原命令在切片中截断）
   `↳ === undefined non-math symbols that hint at float libc++ wrappers === (none) === defined weak __math symbols in beam.o`
   —— 未定义面里找不到数学符号；`__math` 符号只以**已定义 weak** 形态出现在全表里，`nm -u` 看不到。
4. 对照：同会话 `-O0` 逐 TU 扫描中，别的 TU 的数学依赖确实以未定义符号形态出现（`core_src_dpu_cfar_cfar.cpp.o: _exp2 _log2 …`、`core_src_dpu_doa_music.cpp.o: _cosf _sinf …`），说明步骤 3 的空结果不是「忘了扫这个 TU」，而是这张表对 sqrt/lround 这类形态本来就不收录。

## 边界 / 反例

- 降级形态与平台/工具链绑定：本会话实测环境是 Apple arm64 + 该版本 libc++（clang，`-O0`）。x86 上 `sqrt` 通常是 `sqrtsd` 指令；换 libstdc++/glibc 时 `lround` 可能真的落到 `_lround`。审计结论必须带工具链。
- 本条不否定 `nm -u` 对经典 libm 引用的效力（`_sin`、`_exp2`、`___sincos_stret` 这类仍要靠它），只否定「只扫 `nm -u` 即完备」。
- weak 符号的最终归属可能被链接期/优化改变；要断言某次构建的调用面，以该次构建的反汇编为准，不要拿 `-O0` 探针的结论直接代替 Release 产物。
- 未测：不同 `-O` 档、不同 Xcode SDK / libc++ 版本、其他架构。

## 失败信号（未来命中即该想起本条）

- 反汇编里出现 `fsqrt` / `fmul` 之外的开方指令，或 `__ZNSt3__16__math…` 调用，而手上的数学符号清单来自 `nm -u`。
- 某 TU 的 `nm -u` 数学符号为空，却据此写「该 TU 无 libm/math 依赖」。
- 门禁的产物符号段只跑 `nm -u`，就宣称覆盖了全部数学调用。

## 复核证据（2026-09-22，本机重跑 —— 本条据此进注入集）

下列自包含复现证明 `nm -u` 对**哪两类**是盲的，同时**否证**原提案过宽的那句：

```
$ cat > p.cpp <<'EOF'
#include <cmath>
float f(float x){ return std::sqrt(x) + (float)std::lround(x); }
double g(double x){ return std::sin(x); }
EOF
$ clang++ -std=c++17 -O0 -c p.cpp -o p.o
$ nm -u p.o
_sin                              ← 经典 libm 引用仍在，-u 并非全盲
$ nm p.o | grep -c '__math'
2                                 ← __math::lround 以 weak/private 定义在本对象内，-u 看不到
```

**修正原提案**：证据节原写「未定义面里找不到数学符号」——**过宽**。正确表述是
「未定义面里没有 `_sqrt` / `_lround`（也没有提示 float libc++ wrapper 的符号）」，
`_sin` / `_cos` / `_exp2` 这类**仍会出现**。作者 2026-09-22 的独立复核也给出同一纠正
（当时存活的 `beam.o` 的 `nm -u` 实含 `_sin`/`_cos`/`_asin`）。

**范围**：本条不否定 `nm -u` 对经典 libm 引用的效力，只否定「只扫 `nm -u` 即完备」。
绑定工具链：Apple arm64 + libc++（`lround` 的 ABI tag 随 libc++ 版本变）。原提案引的
具体沙箱/构建已变，上述最小复现是可重跑的那部分。
