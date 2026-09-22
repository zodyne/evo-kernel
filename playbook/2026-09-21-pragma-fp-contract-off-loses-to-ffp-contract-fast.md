---
id: pragma-fp-contract-off-loses-to-ffp-contract-fast
type: lesson
status: validated
scope: global
domain: build-system
tags: [clang, fp-contract, fma, pragma, codegen, determinism]
triggers:
  - "用 `#pragma clang fp contract(off)`（或随头文件带进来的等价开关）承诺关闭 FMA 收缩，但构建命令行带 `-ffp-contract=fast`"
  - "带 pragma 与不带 pragma 的 TU 反汇编里都出现 `fmadd`，pragma 像是没生效（失败信号）"
  - "逐位/golden 对拍在 `-ffp-contract=fast` 的构建上失败，而源码里明明写了 contract(off)"
  - "要按文件/TU 关闭浮点收缩，纠结改源码 pragma 还是改构建 flag"
  - "变体构建 rc 全 0、源码只差一个 pragma，却要判浮点位型没变（失败信号：没比对生成的汇编）"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-60a5-7475-af70-36b72f8c98e6
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [fma-contraction-invalidates-bitwise-acceptance-gates, include-order-flips-fp-contraction-rc-blind]
---

# `#pragma clang fp contract(off)` 在 `-ffp-contract=fast` 下不生效

## 主张

`#pragma clang fp contract(off)`（写在头文件里被 include、或写在源文件首行都一样）在 TU 以 `-ffp-contract=fast` 编译时**不生效**：生成的汇编里仍有 `fmadd`，与不带 pragma 的对照完全相同；同一个 pragma 在 `-ffp-contract=on`（C++ 默认）下确实生效（带 pragma 计数 0、不带 1）。所以「按文件/按 TU 关闭 FMA 收缩」不能只靠源码 pragma——只要构建里出现 `-ffp-contract=fast`，该 pragma 就挡不住收缩。

## 为什么

本机 clang 实测到的是一条**不对称**：`#pragma clang fp contract(off)` 压不过命令行的 `-ffp-contract=fast`，但反向能压——pragma(**on**) 能压过命令行的 `-off`（复核实测：pragma(on)+`-off` 下 `fmadd` 计数 1，无 pragma+`-off` 对照为 0）。所以别读成「命令行总是赢」。判「pragma 有没有起作用」只能看产物（汇编里有没有 `fmadd`）：本组合下两组 rc 都是 0，rc 无法区分。

（2026-09-22 复核订正：原文把 pragma 说成「**TU 级**」控制——不准，clang 的 fp pragma 是**词法作用域**控制、可写在函数体内；实测函数体内写 `contract(off)` 在 fast 下同样失效。）

## 证据（切片命令 ↔ 结果）

- 环境：`Apple clang version 17.0.0 (clang-1700.4.4.1) Target: arm64-apple-darwin24.6.0`。
- 头文件携带 pragma（`pragma/fp.hpp` 内 `#if defined(__clang__) / #pragma clang fp contract(off)`）vs 不带，均在 `-std=c++17 -O2 -ffp-contract=fast -S` 下反汇编：
  `=== a.cpp (pragma) === 8: fmadd d0, d0, d1, d2 === b.cpp (no pragma) === 8: fmadd d0, d0, d1, d2` —— 两者都是 `fmadd`。
- 源文件首行直接写 pragma 的 c.cpp，在 `-ffp-contract=fast` 下计数仍为 1：
  `=== c (contract=fast) === 1 === d (contract=fast) === 1 === e (contract=fast) === 1`。
- 同一 c.cpp 换 `-ffp-contract=on`（默认）后：`=== pragma under -ffp-contract=on (default for C++) === b: 1 c: 0` —— pragma 在 on 下生效（c=0），在 fast 下不生效。
- 首轮探针对照同向：`--- with pragma, -ffp-contract=fast --- 1 --- without pragma, -ffp-contract=fast --- fmadd --- pragma warns? --- rc=0`（pragma 不产生告警，静默失效）。

## 边界 / 反例

- 仅 Apple clang 17.0.0 / arm64 实测；其他 clang 版本、`#pragma STDC FP_CONTRACT`、x86 未复验。
- 计数单位是 `-S` 汇编里 `fmadd` 的出现次数，不是运行期结果；本会话没有做运行期逐位对拍。
- 只主张「fast 命令行压倒 pragma off」这一组合；pragma 在 `-ffp-contract=on`/默认下有效（上面的 c:0 vs b:1）。
- 若构建策略是「默认允许收缩、个别 TU 用 pragma 关掉」，本条证据说明该策略在当前工具链上不成立。

## 失败信号（未来命中即该想起本条）

源码里写了 `contract(off)` 就把它当位型保证；或只有 `-ffp-contract=fast` 构建上 golden 对拍失败，却先去查算法与数据类型，而不是先数汇编里的 `fmadd`。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
$ P=$(mktemp -d)
  $ printf '#pragma clang fp contract(off)\ndouble f(double a,double b,double c){return a*b+c;}\n' > $P/p.cpp
  $ printf 'double f(double a,double b,double c){return a*b+c;}\n' > $P/n.cpp
  $ clang++ -std=c++17 -O2 -ffp-contract=fast -S -o - $P/p.cpp | grep -c fmadd
  1            # pragma(off) 在 fast 下不生效
  $ clang++ -std=c++17 -O2 -ffp-contract=fast -S -o - $P/n.cpp | grep -c fmadd
  1            # 对照：不带 pragma 相同
  $ clang++ -std=c++17 -O2 -ffp-contract=on -S -o - $P/p.cpp | grep -c fmadd
  0            # 同一 pragma 在 on(默认) 下生效
  $ clang++ -std=c++17 -O2 -ffp-contract=on -S -o - $P/n.cpp | grep -c fmadd
  1
  # 反向不对称（条目未提，我实测）：pragma(on) **能**压过命令行 off
  $ printf '#pragma clang fp contract(on)\ndouble f(double a,double b,double c){return a*b+c;}\n' > $P/pon.cpp
  $ clang++ -std=c++17 -O2 -ffp-contract=off -S -o - $P/pon.cpp | grep -c fmadd
  1            # 对照：无 pragma + off 时为 0
  本机 clang++ = Apple clang version 17.0.0 (clang-1700.4.4.1) Target: arm64-apple-darwin24.6.0，与切片同版本。全部输出已在本机实跑确认（2026-09-22）。
```

**审核给出的修改意见（要点）**：核心主张成立且本机可复现（fast 下 pragma(off) 失效、on 下生效），所以留注入集；但三处要改： 1) 证据换血：「证据」里依赖被截断命令的两条（c/d/e 计数、首轮探针 `with pragma, -ffp-contract=fast --- 1`）改成 minimalRepro 那段自包含命令（同一场景、d/e 不存在的问题一并消失、且当前 /tmp 沙箱已没了，照抄必失败）。 2) 收窄「主张」的限定：把「只要构建里出现 -ffp-contract=fast，该 pragma 就挡不住收缩」前面加「在本机 Apple clang 17.0.0/arm64 上」，别把范围限定只留在「边界」小节——主张句读起来像跨版本一般律，而证据只有单一工具链。 3) 改写「为什么」里的机制句：删掉「pragma 是 TU 级的浮点收缩控制」（措辞不准，pragma 是词法作用域、可写在函数体里；实测函数体内写 contract(off) 在 fast 下同样失效），改成实测到的**不对称**事实——pragma(off) 压不过命令行 -ffp-contract=fast，但 pragma(on) 能压过命令行 -ffp-contract=off（后者我本机跑出 fmadd 计数 1 对对照 0）。这比「命令行压过 pragma」更准确，也避免读者误推「命令行总是赢」。同时

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 「pragma 是 TU 级的浮点收缩控制」——机制描述，切片与产物都没有；clang 的 fp pragma 实为**词法作用域**控制（可写在函数体内），不是 TU 级。
- 「构建 rc 对指令选择零判别力」——一般律化断言；切片只显示 rc=0/rc=2 的各类构建，并没有「变体构建 rc 全 0、仅差一个 pragma」的对照记录（trigger 里说的那种场景在切片里找不到）。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
