---
id: rg-default-engine-rejects-lookaround
type: lesson
status: validated
scope: global
domain: cli-tools
tags: [ripgrep, rg, regex, lookaround, pcre2]
triggers:
  - "在 rg 里写 `(?<=X)` / `(?<!X)` 前后断言做标识符边界匹配（如排除 asin( 只留 sin(）"
  - "rg 报 regex parse error: … look-around …（失败信号：模式看着没错却解析失败）"
  - "把 grep -P / perl / python re 里的 look-around 正则照搬到 ripgrep"
  - "想按『前面/后面不是某字符』过滤命中，准备改写模式或手工二次过滤绕开"
  - "rg 报错后第一反应怀疑模式本身写错，没意识到是正则引擎方言不支持"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b3e7-baa1-7475-af70-36a51eb6849d
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [rg-literal-marker-needs-f-flag, rg-capital-e-is-encoding-not-extended-regex]
---

# rg 默认正则引擎不支持 look-around，报的是 `regex parse error` 而不是零命中

**主张**：ripgrep 默认正则引擎不认 look-around（`(?<=…)` / `(?<!…)` / `(?=…)` / `(?!…)`），带这类断言跑 `rg` 会直接报 `regex parse error: … error: look-around, …` 退出，命令零输出。这不是模式写错，而是引擎方言不支持；要跑原样的断言式，得换支持 look-around 的引擎（ripgrep 的 PCRE2 模式 `-P` / `--pcre2`，或 python `re` / perl / grep -P），或改写成不含断言的等价模式。

**证据（本会话命令 ↔ 结果，切片逐字）**：

- 想排除 `asin(` / `_sin(` 这类子串、只统计独立 `sin(` 调用，直接套负向后顾：
  `rg -n -o -e '(?<![A-Za-z0-9_])sin\s*\(' core/src | head -50`
  ↳ `rg: regex parse error:` / `(?:(?<![A-Za-z0-9_])sin\s*\()` / `^^^^` / `error: look-around, in…`（切片在此截断）
  —— 命令没有返回任何命中行，直接解析失败。
- 同一条负向后顾稍后原样放进 python 就工作（同为统计 `sin|cos|atan2|…` 的逐文件调用数）：
  `python3 -c "import re,os; pat=re.compile(r'(?<![A-Za-z0-9_])(sin|cos|tan|asin|…')"`
  ↳ `15 core/src/dpu/track/unit.c 14 core/src/dpu/doa/beam.c 14 core/src/dpu/doa/dml.c 13 core/src/math/fft.c …`
  —— 相同断言、相同语义，说明问题出在引擎而非模式。

**为什么**：ripgrep 默认走 Rust `regex` 引擎，为可证明的线性时间匹配放弃了 look-around 这类需要回溯/上下文的特性；它把这当成正则解析错误当场报出，而不是降级或零命中。所以从 `grep -P` / perl / python 迁移过来的断言式模式，第一处就会在这里撞墙，容易被误判为「模式写错了」。

**边界 / 反例**：

- 没有 look-around 的模式在默认引擎下照常工作；本条只针对断言类语法。
- 修法 `rg -P/--pcre2` 依赖发行版编译时带 PCRE2（本次会话未实测，切片里是改用 python `re` 完成的统计）；`-P` 会放弃默认引擎的线性时间保证，大目录扫描前先想清楚代价。
- 若把 `(?<!…)` 改写成 `(^|[^A-Za-z0-9_])` 之类的普通分组，捕获组会把边界字符一起吃进 `-o` 输出，需要额外处理分组/边界，不能直接等价替换。

**失败信号（未来命中即想起本条）**：`rg` 报 `regex parse error` 且错误里提到 `look-around`，却准备从头改模式；或把同一断言模式在 python/perl 下的成功当成「rg 也能跑」。

## 复核证据（2026-09-22，本机重跑 —— 本条据此进注入集）

原提案的命令证据绑在别仓工作树、且切片里被截断；下列是最小自包含复现，**现在仍可逐字重跑**：

```
$ echo x | rg '(?<=a)b'
rg: regex parse error:
    (?:(?<=a)b)
       ^^^^
error: look-around, including look-ahead and look-behind, is not supported

Consider enabling PCRE2 with the --pcre2 flag, which can handle backreferences
and look-around.
$ echo $?
2
```

**范围**：主张就是「rg 默认引擎不认 look-around，且以解析错误 + rc=2 退出，零输出」——上表即全部。
原提案「为什么」里那句「Rust regex 引擎为可证线性时间而放弃 look-around」属**外部知识**，非本次观测，
已按此定位保留（错误文本自身已声明该限制）。原证据节第 2 条（python 命令、15/14/14/13 计数）
绑在已变的 algommw-plus 工作树上，是辅助佐证，**不能当主证**。
