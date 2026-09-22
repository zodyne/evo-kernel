---
id: line-regex-cannot-decide-token-in-comment-or-string
type: lesson
status: validated
scope: global
domain: verification
tags: [grep, false-positive, comment, string-literal, lexical-scan, source-audit]
triggers:
  - "用 `rg token | rg '/\\*|\\*/|//|\"'` 这类行级筛选判断 token 是否在注释或字符串里"
  - "审计报告要写『某符号只在注释里出现』或『注释里还有旧符号』，手上只有行级 grep 命中"
  - "同一行既有代码又有注释/字符串标记，行级筛把代码里的 token 也选中（失败信号）"
  - "机械改写后要证明注释/字符串零改动，准备用 grep 命中清单代替解析结果"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-60a5-7475-af70-36b72f8c98e6
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [grep-lint-gate-calibrate-before-enforce, cast-auto-rewrite-pollutes-comments-audit-diff, substring-matcher-cannot-tell-exec-from-mention]
---

# 行级 grep 的命中不能证明 token 在注释/字符串里

## 主张

「行里含注释/字符串标记」的行级正则（如 `rg '/\*|\*/|//|"'`）不能回答「token 是否在注释或字符串里」：同一行既有代码又有注释/字符串标记时，代码里的 token 也被选中。本会话 `rg -n 'M_PI' core | rg '/\*|\*/|//|"' | rg 'M_PI'` 命中的是 `core/src/math/fft.cpp:86: double dAngStep = -2.0 * M_PI / ( double )`——该 `M_PI` 在表达式里，是代码；随后用解析式检查得到的结论是 `bad: (none)`（没有任何 M_PI 落在注释/字符串里）。行级 grep 只能粗筛候选行，「在不在注释/字符串里」要交给能区分标记位置的词法/语法解析。

## 为什么

注释/字符串的边界是**列级**信息，而行级匹配把整行压成一个布尔：只要行内任意位置出现 `//`、`"` 或 `/*`，该行的所有 token 都被打上「可能在其中」的标签。反过来，跨行注释 `/* ... */` 里的 token 也可能落在没有标记的行上而被漏掉——两个方向都说明行级 grep 不具备回答成员关系的能力。

## 证据（切片命令 ↔ 结果）

- 行级筛（假阳性）：
  `rg -n 'M_PI' core | rg '/\*|\*/|//|"' | rg 'M_PI'`
  → `core/src/math/fft.cpp:86:        double            dAngStep = -2.0 * M_PI / ( double )`
  —— 被标出的 `M_PI` 是除法表达式的一部分（代码），不是注释/字符串内容。
- 解析式检查（真值）：
  `=== M_PI occurrences that are inside a comment or string literal === bad: (none)`
  —— 同一批 `M_PI` occurrence 无一在注释/字符串里，与行级筛的命中相反。

## 边界 / 反例

- 本会话的解析式检查只回显了输出（`bad: (none)`），其实现细节未在切片里回显；复用时用自己信任的 tokenizer/AST，而本条只主张「行级同现 ≠ 成员关系」。
- 行级 grep 仍是合法的**粗筛**（缩小候选行范围）；错在把粗筛结果直接写成结论。
- 解析器自身有边界（原始字符串、续行、宏拼接），但那是下一步的精度问题，不影响本条结论。

## 失败信号（未来命中即该想起本条）

审计/改写报告写「这些 token 只在注释里」「注释零改动」，依据却是 `grep token | grep 注释标记` 的命中/零命中清单；被追问时拿不出能区分列位置的解析结果。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
d=$(mktemp -d); cd "$d"; printf '/* block\nM_PI in a block comment\n*/\ndouble a = -2.0 * M_PI / 3.0; // uses M_PI\nconst char* s = "M_PI";\n' > t.cpp
rg -n 'M_PI' t.cpp | rg '/\*|\*/|//|"' | rg 'M_PI'
# 实测输出（rc=0）:
#   4:double a = -2.0 * M_PI / 3.0; // uses M_PI
#   5:const char* s = "M_PI";
# 第4行 = 假阳性：M_PI 在除法表达式里(代码)，只因行尾 // 被选中；
# 第5行 = 真阳性(字符串)；
# 第2行 `M_PI in a block comment`(块注释内、该行无任何标记) 未被选中 = 假阴性。
# 同一行级筛既漏又误，故『行内同现』既不证明也不排除成员关系——不依赖任何仓库环境。
```

**审核给出的修改意见（要点）**：主张成立且真值稳定（grep/行级工具 vs 词法解析的通用属性，非绑 algommw-plus HEAD），留在注入集。但证据节要换：现有一条『解析式检查 bad: (none)』被摆成可复跑的命令，实为截断的示意（python 实现不在切片），易被误当可复跑证据——应显式降级为『示意，不可复跑』。更好的做法：用 minimalRepro 那条自包含命令替换对 algommw-plus 现场的引用，它在一个临时文件上同时给出假阳性(第4行)与假阴性(第2行)，一条命令覆盖两个方向、零仓库依赖、可当场重跑。另补一句：切片里现场结果行被截断在 `( double )`，使行级筛命中它的标记不可见——引用原现场时要么补上能被看见的标记，要么干脆不引原现场。verified_by: command 保留（换证据后确有确定性可复跑命令）。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
