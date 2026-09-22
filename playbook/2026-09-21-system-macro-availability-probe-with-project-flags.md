---
id: system-macro-availability-probe-with-project-flags
type: lesson
status: validated
scope: global
domain: verification
tags: [preprocessor, macro, flags, m-pi, clang, cpp17]
triggers:
  - "审查/清理各 TU 里 `#ifndef M_PI` 这类系统宏兜底，要判它在当前构建下是否还必要"
  - "准备从『严格 C++17 / 无 GNU 扩展』这类构建约束推断某个系统宏不可用（失败信号：没跑过一次探测）"
  - "要回答『这个宏由系统头提供吗』，手上只有标准文档级别的推断，没有带项目 flags 的实测输出"
  - "把各文件重复的常量兜底（M_PI/dPi）合并成共享头之前，要确认系统头不会提供同名宏"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-60a5-7475-af70-36b72f8c98e6
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [inline-constexpr-header-still-needs-include-guard, algommw-plus-core-headers-ifndef-guard-convention]
---

# 系统宏可用性要在项目 flags 下探测后下结论，不能按「严格标准模式」推断

## 主张

要判某个系统宏（本例 `M_PI`）是否可用，必须**用项目自己的 flags** 对目标头（`<cmath>`）做预处理探测（切片里命令是 `printf '#include <cmath>\n' > /tmp/... && <项目 flags 的 clang++ 探测>`），结果输出 `#define M_PI 3.14159265358979323846264338327950288`，即该配置下 `M_PI` 由系统头提供；不能从「C++17 严格、无 GNU 扩展」这类构建约束推断它不可用——宏可用性是 平台 × SDK × flags 的属性，同一份标准约束在不同 libc 上结果不同。

## 为什么

`M_PI` 不是 ISO C/C++ 标准宏，各 libc/SDK 按自己的条件宏（strict-ANSI 开关、feature-test 宏）决定是否暴露。读构建约束只能猜到「可能没有」，而合并不合并那些 `#ifndef M_PI` 兜底（本会话 core 里点出 11 处 `#ifndef M_PI` / `#define M_PI` 块）依赖的是「实际有没有」这个事实。

## 证据（切片命令 ↔ 结果）

- 探测：`=== is M_PI defined by system headers under the project's flags? === #define M_PI 3.14159265358979323846264338327950288` —— 探测命令 `printf '#include <cmath>\n' > /tmp/...`，随后输出里出现该 `#define`，说明宏在本次探测的 flags 下被处理（不是被条件编译跳过）。
- 兜底块规模（同会话另一条统计）：`ifndef M_PI lines: 11  define M_PI lines: 11` —— core 里 11 个 `#ifndef M_PI` 块各自带一个 `#define M_PI`。
- 另一条命令把 guard 行与使用行分开计数（`rg -o 'M_PI' core | wc -l` 与 `#ifndef`/`#define` 行分别统计），说明「哪些 M_PI 是兜底、哪些是使用」也是实测出来的，不靠目测。

## 边界 / 反例

- 切片只回显了探测的**输出行**，没有回显完整 flags 字符串；本条只主张「该次探测下 M_PI 可用」以及「该判据必须实测」这两点。换 SDK、标准级别（严格 ANSI 的 glibc 会隐藏 M_PI）、目标平台或编译器，必须重跑探测。
- 「当前配置下系统头提供 M_PI」不等于「所有目标配置都提供」：C 与 C++、不同 `-std` 是不同配置，合并兜底前要逐配置探测。
- 本条不主张那 11 处兜底该删还是该留——那是按目标编译矩阵决定的事。

## 失败信号（未来命中即该想起本条）

被问「这些 `#ifndef M_PI` 还有必要吗」时，只能答「标准上 M_PI 没保证 / 严格模式应该没有」，拿不出带项目 flags 的宏探测输出；或按这种推断直接删掉兜底。
