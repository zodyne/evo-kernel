---
id: bsd-grep-empty-subexpression-hard-error
type: lesson
status: validated
scope: global
domain: macos-tooling
tags: [grep, bsd, macos, regex, shell, pipeline]
triggers:
  - "在 macOS 上用 grep -E 过滤 nm / rg / 日志输出，命令零输出（失败信号：grep: empty (sub)expression）"
  - "把一长串候选名字拼成一条 -E 交替式（a|b|c|…），模式里多出一个空分支"
  - "管道里 grep 报错退出，脚本只读 stdout，把『零命中』当成结论"
  - "模式由变量/循环拼出来，末尾或中间留下多余的 | 后直接喂给 grep -E"
created: 2026-09-19
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b754-1b2d-7475-af70-36d1c8e07a6e
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [grep-alternation-count-cannot-prove-single-pattern-present, rg-literal-marker-needs-f-flag]
---

# macOS 的 BSD grep 遇到空分支直接报错退出：`grep: empty (sub)expression`

## 主张

macOS 自带的 BSD grep 在 `-E` 模式里遇到**空分支**（模式中多出一个 `|`，如 `a|b|`、`a||b`）时不是忽略该分支，而是直接报 `grep: empty (sub)expression` 并终止（本机复验退出码 2），**一个字节都不输出**。在核验管道里这极易被读成「没有匹配」——过滤链下游拿到空结果，而实际上 grep 根本没在工作。拼模式时保证每个分支非空，或者干脆不要在 `nm -u` 这类已经足够短的输出上再套一层 `grep -E` 过滤。

## 为什么

这条错误的危险不在报错本身（报错文本就在眼前），而在它与「零命中」的**输出形态完全相同**：stdout 都是空的。若命令嵌在 `$( )`、管道或只看 stdout 的脚本里，错误信息可能被 `2>/dev/null` 吞掉或没被注意，空结果就被当成「符号不在产物里 / 名字没出现过」的否定证据——核验场景下这是一个假的否定结论。

## 证据（切片命令 ↔ 结果）

- 过滤命令（模式体在切片中被截断，可见前缀是 `'exp2|fmin`）：
  `for p in p_unqual p_std; do echo "=== nm -u $p.o ==="; nm -u "$p.o" | grep -E 'exp2|fmin…`
  ↳ `=== nm -u p_unqual.o === grep: empty (sub)expression` / `=== nm -u p_std.o === grep: empty (sub)expression`（两个对象各报一次，零匹配输出，白跑一轮）。
- 随即去掉这层过滤、直接看 `nm` 输出即拿到结果：
  ↳ `=== nm -u p_unqual.o === _exp2f` / `=== nm -u p_std.o === _exp2f`。
- reflector 本机复核（2026-09-19，同一台机器，`grep --version` → `grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`）：
  `echo x | grep -E 'a|'` ↳ `grep: empty (sub)expression`，`$?` = 2；`echo y | grep -E 'a||b'` 同样报错、rc=2。

## 边界 / 反例

- 本条只覆盖 macOS 自带 BSD grep（2.6.0-FreeBSD，切片与复验都在同一台机器）；换 GNU grep 或别的平台前，空分支行为需重新验证，不要直接外推。
- 「模式里有空分支」是这条错误的唯一成因（grep 自己的报错文本说明了这点）；正常的 `a|b` 交替不受影响。
- 即使过滤成功，也别用 `-c` 的联合计数去证明单个分支出现过（见 `grep-alternation-count-cannot-prove-single-pattern-present`）。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
echo x | /usr/bin/grep -E 'a|'; echo "rc=$?"\n# 期望:\n# grep: empty (sub)expression\n# rc=2\n# 对照: echo a | /usr/bin/grep -E 'a|b'  →  "a", rc=0\n# 陷阱: 裸 `grep` 在本 harness 是 ugrep 包装 → `echo x | grep -E 'a|'` 只返回 rc=1、无报错
```

**审核给出的修改意见（要点）**：主张正确、真值稳定（本机 BSD grep 2.6.0-FreeBSD 行为），应留在注入集。仅需加固证据：把第 3 条复现命令改成绝对路径 `/usr/bin/grep`（`echo x | /usr/bin/grep -E 'a|'; echo rc=$?` → `grep: empty (sub)expression`, rc=2），因为裸 `grep` 在本 harness 被包装成 ugrep、裸跑会静默返回 rc=1 从而看起来像反例；并在证据节注明第 1 条命令在切片中被截断、其模式不可复跑，同时补上被省略的第三个对象 p_ctrl。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
