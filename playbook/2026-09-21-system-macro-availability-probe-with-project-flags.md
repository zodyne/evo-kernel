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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
printf '#include <cmath>\n' | clang++ -std=c++17 -E -dM -x c++ - | grep -w M_PI
# 期望输出: #define M_PI 3.14159265358979323846264338327950288   (rc=0)
# 本机实测（Apple clang 17.0.0, arm64-apple-darwin24.6.0）与条目输出逐字一致。
# 补充实测：-std=gnu++17 与 -std=c++17 结果相同；-std=c++17 下 __STRICT_ANSI__ 确为 1 但 M_PI 仍被定义
#   => macOS SDK 不按 strict-ANSI 隐藏 M_PI，本机无法演示『flags 决定可用性』，该点需 glibc 环境才能演示。
```

**审核给出的修改意见（要点）**：保留入库，但收窄主张并换证据：(1) 把《证据》第 1 条换成上面 minimalRepro 的自包含探测命令（可在本机直接复跑，不依赖消失的 /tmp 沙箱），并明确标注：原切片命令在 flags 处被截断、沙箱已不存在，故原命令不能照抄。(2) 主张首句去掉/降级「必须用项目自己的 flags」这一由截断命令臆测的措辞，改为「必须对真实构建配置下的目标头做预处理探测，不能从标准模式推断」——这才是切片支持的点；「项目 flags」作为期望做法保留在《边界》里。(3) 《为什么》的跨 libc 机制解释标注为『一般性背景，本次未做对照实验』。(4) 保留 11 处兜底与 59 次 M_PI 出现等仓内统计时，注明绑定 algommw-plus 当时 HEAD、会随仓漂移，不作为本条真值。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 必须用项目自己的 flags 对目标头（<cmath>）做预处理探测（切片里命令是 printf '#include <cmath>\n' > /tmp/... && <项目 flags 的 clang++ 探测>）—— 切片命令恰好在 flags 处截断，看不出用了项目 flags；且探测跑在 /tmp 沙箱、不在项目目录。证据只支持『做了一次探测』，不支持『用了项目 flags』。
- 宏可用性是 平台 × SDK × flags 的属性，同一份标准约束在不同 libc 上结果不同 —— 切片里没有任何跨 libc / 换 flags 的对照实验，该机制解释是作者补的（方向正确但非本次观测所得）。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
