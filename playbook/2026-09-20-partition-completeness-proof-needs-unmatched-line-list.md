---
id: partition-completeness-proof-needs-unmatched-line-list
type: lesson
status: validated
scope: global
domain: verification
tags: [grep, diff-classification, completeness, acceptance-criteria, false-positive]
triggers:
  - "验收判据写『diff 的每一行属于且仅属于 N 个类之一』，要判这条完备性断言成立不成立"
  - "复核『每行都被归类』类证明：各类计数相加等于总行数，就准备结案"
  - "配对结构的收尾行（`extern \"C\" {` 的 `}`、`#if`/`#ifdef` 的 `#endif`）在类表里没有对应条目（失败信号）"
  - "类表按特征串只写了开头一侧（`extern \"C\"`、`#ifndef M_PI`），没有写闭合一侧"
  - "要证明『没有未被覆盖的行』，手上只有各分类的计数、没有『不属于任何类』的行清单"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b753-2b87-7475-af70-36c9e8959d50
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [grep-alternation-count-cannot-prove-single-pattern-present, verify-numbered-list-full-coverage-by-regex-count]
---

**主张**：「diff 的每一行属于且仅属于 N 个类」这类**完备性**断言，只能靠一条「列出不属于任何类的行」（`grep -vE '类1|类2|…'`）的命令证实或证伪；各类计数之和等于总行数**不是**证明——计数只回答「命中了什么」，永远不回答「还有什么没被命中」。

**为什么**：类表是按特征串定义的，而代码里的结构是**成对**的：`extern "C" {` 有配对的 `}`，`#if`/`#ifdef` 有配对的 `#endif`。类表通常只为「开头一侧」写了模式，配对收尾行就成了无人认领的行——它们既在 diff 里真实存在，又落不进任何一类。只看分类计数时，缺口完全不可见。

**证据（切片命令 ↔ 结果）**：

- 卡片原文要求逐行完备分类：`grep -n 'diff 分类证明' PLAN.md` → `879:… 的每一行属于且仅属于：\`namespace\` 开/闭、\`#include\`、\`#ifndef M_PI` …`。
- 会话用"不属于任何类"的过滤直接证伪：`=== core/src diff lines matching NO class (strict: NS/INC/MPIBLK/DPI/EXTC/CAST) ===` → `-#endif -#endif -#ifdef __cplusplus …` —— 确实存在落不进 6 个类中任何一类的行，该完备性断言不成立。
- 同一批 diff 里的相关计数（各自单独成立、但回答不了完备性）：`## #ifndef M_PI / #define M_PI deletion lines in core/src diff: 22`、`## dPi USAGE (+) lines … : 37`、`## extern"C" lines visible in core/include diff: 30`。

**边界 / 反例**：

- 断言若是「只看 `+` 行」或「只看某几个类」，那要写明范围，别把「全部行」和「关注的类」混在一句里——本条反对的是用计数给"全部行"背书。
- `grep -vE` 的类正则写错会制造**假缺口**，也会因转义（`extern "C"` 里的引号）漏掉真命中；列出的缺口行要逐条归类为「真空缺」或「类表漏写」，而不是直接当结论。
- 单条模式的存在性另有更强的做法（`rg -n` 看行号 / `rg -o | wc -l` 看次数），别用 `-c` 配交替式下判断（见 related）。

**失败信号（未来命中即该想起本条）**：完备性证明只有「N 类各 M 行、合计 = 总行数」这种对账；类表里的 `extern "C"`、`#ifndef M_PI` 只有开没有闭；被问「还有没有没覆盖的行」时，拿不出那张缺口行清单。
