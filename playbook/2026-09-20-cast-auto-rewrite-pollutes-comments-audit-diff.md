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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含、本机可重跑（已实跑，输出如下）：

D=$(mktemp -d) && cd "$D" && git init -q . && \
printf '/* 说明: <math.h> 的 ::sin(double) 两个精确匹配二义。 */\ndouble f( float y )\n{\n    double x = (double)y;   /* 旧式转换 */\n    return x;\n}\n' > a.cpp && \
git add a.cpp && git commit -qm base && \
python3 -c "import re;p='a.cpp';t=open(p).read();open(p,'w').write(re.sub(r'\(\s*double\s*\)','(static_cast<double>(',t))" && \
git diff -U0 | python3 -c "
import sys
n=0
for l in sys.stdin:
    if l[:1] in '+-' and not l.startswith(('+++','---')) and l[1:].lstrip()[:2] in ('/*','* '):
        print('  污染:', l.rstrip()); n+=1
print('纯注释行改动数 =', n)"

实测输出：
  污染: -/* 说明: <math.h> 的 ::sin(double) 两个精确匹配二义。 */
  污染: +/* 说明: <math.h> 的 ::sin(static_cast<double>( 两个精确匹配二义。 */
纯注释行改动数 = 2

（把该注释行还原后再跑，末行变为 `纯注释行改动数 = 0`，与条目主张的「审计→恢复→归零」闭环一致；这同时证明主张真值不绑外部环境。注意：同一次替换还会弄坏代码行 `(double)y` → `(static_cast<double>(y`，即污染不止注释。）
```

**审核给出的修改意见（要点）**：主张真值稳定、方法通用，够格留注入集，但三处要改： 1) 证据节第 3 条：删去无据的「复查归零」，改成可复跑的最小复现（见 minimalRepro：造一个注释里含 `::sin(double)` 的小文件 → 同一正则替换 → `git diff -U0` 审计得「纯注释行改动数 = 2」→ 还原注释行后归零）；并注明「恢复注释行 21」那次尝试随后被 `git checkout -- .` 回滚、且紧接着仍是「残余注释污点复查 + 注释行改动: 15」——原记载把两次尝试拼成一条线。 2) 主张收窄：把「这类改写」限定为**正则/文本替换式**批量改写（本次污染样本 `::sinstatic_cast<double>(` 即文本替换所致，机制在所引样本里直接可见）；「为什么」里删掉「或 clang-tidy fix-it 边界处理不完美」——clang-tidy fix-it 是 AST 级、本就不该动注释，无据的并列会误导，建议改为边界句「若用 clang-tidy fix-it 则风险低、性质不同」。 3) 字符串那半句：要么换成同期 printf 换行样本并注明是另一支脚本所致，要么降为旁注「同会话另见字符串被批量脚本改坏」，不与 old-style-cast 改写直接绑定。 证据节第 1 条补一句：审计命令的 python 体在切片中被截断（只到 `for l in 

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 之后复查 `注释行改动数` 归零（仅剩「结尾注释的代码行」被豁免）
- 改写会**改到注释（和字符串）里的文本** ——「（和字符串）」这半句：本切片中字符串被批量脚本改坏的样本（`printf 字符串里的真实换行 → \n 转义`，line 2002）是另一支脚本/另一阶段的产物，并非本次 old-style-cast 改写所改，绑定到 cast 改写上超出证据
- 或 clang-tidy fix-it 边界处理不完美 —— 本会话的污染样本来自 python 正则脚本（`::sinstatic_cast<double>(`），clang-tidy 是否也污染注释在切片里没有证据

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
