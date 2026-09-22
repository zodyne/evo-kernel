---
id: cast-auto-rewrite-pollutes-comments-audit-diff
type: lesson
status: validated
scope: global
domain: refactoring
tags: [cpp, static-cast, comments, clang-tidy, diff-audit]
triggers:
  - "clang-tidy / 脚本批量改完全树 cast 后要提交，想确认改动面只有代码没有别的"
  - "代码注释里写了 (T) 形态的示例，自动 cast 改写把注释文本也改了（失败信号）"
  - "批量文本替换后需要一条可执行的审计命令，证明注释行零改动"
  - "评审一份大范围纯重构 diff，想快速定位被误改的注释/字符串"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4a3-ae96-7475-af70-36ad39adaba4
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [mass-cast-rewrite-macro-holes-need-handfix, cast-rewrite-must-absorb-function-call-parens]
---

**主张**：批量 `old-style-cast → static_cast` 改写会**改到注释（和字符串）里的文本**；收尾必须跑一条 diff 审计——统计改动行里属于纯注释行的数量，要求为 0，发现污染后逐行恢复。本会话自动改写污染了注释（恢复 21 行），且切片里留有一处被改坏的注释样本。

**为什么**：这类改写常常是「正则 + 文本替换」或 clang-tidy fix-it 边界处理不完美；注释里的 `(double)`、`::sin(double)` 之类文本与代码 token 无法靠词法区分。注释被改坏不会导致编译失败，只会静默腐蚀文档，最终评审时很难回溯是哪一步改的。

**证据（本会话切片，命令 ↔ 结果）**：

- 审计命令与输出标题：`=== 注释行改动数(应为 0;结尾注释的代码行除外) ===`（用 `git diff -U0` 逐行判定）。
- 污染样本（git diff）：`- * <math.h> 的 ::sin(double) 两个精确匹配二义。 */` 被改成 `+ * <math.h> 的 ::sinstatic_cast<double>( 两个精确匹配二义 )。 */`。
- 修复记录：`恢复注释行 21`；之后复查 `注释行改动数` 归零（仅剩「结尾注释的代码行」被豁免）。

**边界 / 反例**：

- 代码行尾注释（`code(); /* (T) ... */`）会随代码行一起被计入「代码行」，审计脚本专门豁免这种；若注释污染正好发生在行尾注释里，该审计可能漏报，需要人眼抽查。
- 字符串字面量里的 `(T)` 同样可能被改；本会话另有 printf 字符串被脚本改坏（换行问题）的记录，属同一类文本污染。

**失败信号（未来命中即该想起本条）**：纯重构 diff 里出现只改注释文本的行；或报告声称「零行为改动」却说不出注释行改动数。
