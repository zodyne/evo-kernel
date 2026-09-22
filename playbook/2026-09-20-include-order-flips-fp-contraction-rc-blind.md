---
id: include-order-flips-fp-contraction-rc-blind
type: lesson
status: validated
scope: global
domain: build-system
tags: [clang, fp-contract, fma, include-order, assembly-diff, acceptance-gate]
triggers:
  - "挪动 include 顺序（把带 pragma/宏的头移到使用点之前或之后）后要声称『数值路径没变』"
  - "变体构建全部 rc=0，就拿编译通过当『include 位置变化无副作用』的证据（失败信号）"
  - "clang 生成的浮点指令是单条 fmadd 还是分离的 fmul+fadd，要判有没有做 FMA 收缩"
  - "逐位/golden 闸门失败，但源码 diff 里只有一行 include 的位置变化"
  - "改完 core 头的 include 位置跑构建，rc 与 before 相同，不知道还该比对什么"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-ee02-7475-af70-36c7ee72ff22
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [fma-contraction-invalidates-bitwise-acceptance-gates, cpp-mode-libm-symbol-diff-per-tu]
---

**主张**：同一条浮点表达式，只因带 FP 收缩控制（pragma/宏）的头在 TU 里的 **include 位置**不同，clang 生成的指令就从融合的 `fmadd` 变成以 `fmul` 开头的分离序列；而两个变体的构建 **rc 都是 0**。所以「编译通过 / 退出码 0」对 include 顺序这一维**零判别力**——要判「只挪了 include、行为未变」必须比对生成的汇编。

**为什么**：退出码只反映语法/链接是否通过，对「哪条指令被选中」不敏感；FP 收缩属于代码生成层，只有产物（汇编/符号）才带这个信息。把 rc 当无副作用证据，等价于用存在性判据回答等值性问题。

**证据（切片命令 ↔ 结果）**：

- 合成 TU 三变体（`Apple clang version 17.0.0 (clang-1700.4.4.1) Target: arm64-apple-darwin24.6.0`）：
  - `=== control (no pragma) === 8:	fmadd	s0, …`
  - `=== alone === 8:	fmadd	s0, s1, s2, s0`
  - `=== before_fp === 8:	fmadd	s0, s1, s2, s0`
  - `=== after_fp === 8:	fmul	s1, s1, s2 9:	f…`（切片在后续指令处截断）
  —— 同一段代码，fp 头在 `before_fp` 位置时仍是单条 `fmadd`，挪到 `after_fp` 位置后变成 `fmul` 开头。
- 目标仓库副本上的同名变体：`=== variant skip === rc=0 OK === variant add === rc=0 OK` —— 两个变体的 rc 都为 0，返回码完全分辨不出上面那条指令差异。

**边界 / 反例**：

- 切片把命令原文截断了：头部具体是 `#pragma STDC FP_CONTRACT` 还是等价宏/开关，本条未取证；只主张「include 位置会改变 FP 收缩产物」这一现象。
- 与 `-ffp-contract=off`（见 related）是**不同的触发面**：那条走构建 flag，本条走 TU 内 include 位置/pragma 作用域；只锁住构建 flag 不能消除本条。
- 仅 arm64 + Apple clang 17 实测；x86 / 其他 clang 版本未复验。
- 只对「有逐位/数值等价承诺」的验收有意义；统计容差级判据不必比汇编。

**失败信号（未来命中即该想起本条）**：变体构建 rc 全 0 就被当成「无副作用」；或报告声称「只动了 include 顺序」却拿不出产物级（指令/符号）差异清单。
