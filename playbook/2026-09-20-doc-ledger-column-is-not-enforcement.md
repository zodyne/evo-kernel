---
id: doc-ledger-column-is-not-enforcement
type: lesson
status: validated
scope: global
domain: verification
tags: [ledger, enforcement, docs-vs-code, git-hooks, adversarial, code-review]
triggers:
  - "复核『台账/文档里写着某个校验列，但代码里没有强制 ⇒ 冲突/风险』这类发现"
  - "判断台账/清单里的一列（blob 哈希、commit、校验和）是执行边界还是记录溯源"
  - "把 PLAN / handoff 里的 hash 列当成 CI 校验推出风险结论之前"
  - "审计『某校验到底有没有在跑』：rg 非文档代码 + .git/hooks + CI 三处（失败信号：三处都指不出具体机制）"
  - "报告写『台账会拦住这次改动』却指不出拦住它的代码/hook/CI"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b753-55b9-7475-af70-36cbee149f9f
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [approval-gate-written-only-in-prompt-is-not-enforceable, synthetic-sandbox-mechanism-is-not-target-repo-risk]
---

# 主张

文档/台账里出现一列（如 blob 哈希），**不等于**存在一条会执行该校验的机制。判「这是不是执行边界」只能看执行层：`rg <关键词> --glob '!docs/**'` 搜非文档代码、看 `.git/hooks` 是否只有 sample、看 CI 配置。**已查的载体都没有** ⇒ 该列只是记录/溯源字段，据此推出的「冲突/被拦住」是假阳性。（2026-09-22 独立复核收窄：原写「三处都没有」，但当时 CI 一栏的输出被截断、并未展开——稳妥表述是「非文档代码 + hooks 两处无、CI 未展开」，与本节边界一致。另：补 `--hidden` 才搜得到 `.github/`，否则会用一次假阴性去自我印证「无 CI」。）

# 为什么

记录列（blob / commit / hash）在台账里读起来像闸门，但它可能只是「这一步的起点提交」「合成器版本」这类溯源信息。文档自己对该列用途的定义比列名更权威——本例 PLAN.md:608 自述该 blob 列是「合成器**有版本**：改 `frame_source.cpp` …」，且 `ledger.md` 里没有任何比对/强制规则。判定必须落到**会被执行的载体**；否则就是拿纸面当机制。这与 `approval-gate-written-only-in-prompt-is-not-enforceable` 同族：那条的纸面是提示词/SKILL.md，这条的纸面是台账列。

# 证据（切片命令 ↔ 结果）

- `cd /Users/zodyne/Dev/algommw-plus && rg -n 'hash-object|ledger' --glob '!docs/**' …`
  → `=== any blob/hash-object enforcement in scripts/CI? === NONE_IN_CODE === .git hooks (non-sample) === ONLY_SAMPLES`（非文档代码零命中；hooks 只有官方 sample）。
- 台账用途自述 → `=== ledger.md has NO comparison/enforcement rule; declared purpose of blob === 12:608:6. 合成器**有版本**：改 \`frame_source.cpp\``（是版本溯源，不是比对校验）。
- 复核裁决（末条 assistant）：该发现 `isReal = false`——机械事实（台账里确有 blob 列）成立，但把它读成「强制校验 ⇒ 与字节冻结冲突」的定性是误读。

# 边界 / 反例

- 不主张「文档里的校验永远不存在」：真放在 CI 里的校验，`rg` 会在 CI 配置里命中。判据是**能否指出执行层的具体载体**，不是文档里有没有写。
- 否定结论（「没有强制」）要求全量搜：含隐藏目录与本仓实际用的 CI 路径，别只搜 `scripts/`。本切片里 CI 一栏的输出被截断，稳妥表述是「非文档代码 + hooks 两处无，CI 未展开」，不要替它下「无 CI」的定论。
- 与 `synthetic-sandbox-mechanism-is-not-target-repo-risk` 互补：那条查「证据载体是不是合成文件」，本条查「机制载体是不是文档」。

# 失败信号（未来命中即该想起本条）

- 复核一条「台账/文档会拦住 X」的发现时，指不出拦截发生在哪段代码 / 哪个 hook / 哪条 CI。
- `rg` 非文档代码零命中、`.git/hooks` 只有 sample，却仍把某记录列写进「冲突/阻塞」结论。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含最小复现（2026-09-22 在本机跑过，输出如下）。它不依赖 algommw-plus 或任何 /tmp 沙箱，只演示「主张真值」：文档里的记录列 ≠ 执行层强制；判据是能否指出执行层载体。\n\nʼʼʼsh\nset -e\nT=$(mktemp -d); mkdir -p \"$T/docs\"; cd \"$T\"; git init -q\ncat > docs/ledger.md <<'EOF'\n# 闸门台账（一步一行，只追加不改）\n`commit` 列 = 该步的**起点**提交。\n| 日期 | 步 | commit(起点) | frame_source.cpp blob |\n|---|---|---|---|\n| 2026-09-18 | P0 | 1a0ae80 | 49d5e8874bb4960f2c1c4930c16da4159f6b41d0 |\n注：该 blob 列 = 合成器**有版本**（改 `frame_source.cpp` 就是改闸门输入），是溯源，不是比对校验。\nEOF\nrg -n 'hash-object|blob' --glob '!docs/**' . || echo NONE_IN_CODE   # 期望 NONE_IN_CODE\nls .git/hooks/ | grep -v '\\.sample$' || echo ONLY_SAMPLES        # 期望 ONLY_SAMPLES\nls -d .github/workflows 2>/dev/null || echo NO_CI                  # 期望 NO_CI\n# 正对照：真把校验放进 CI 后，执行层就该被指出来\nmkdir -p .github/workflows\nprintf 'on: [push]\\njobs:\\n  g:\\n    runs-on: ubuntu-latest\\n    steps:\\n      - run: grep -q 49d5e887 docs/ledger.md\\n' > .github/workflows/gate.yml\nrg -n --hidden '49d5e887' --glob '!docs/**' .                       # 期望命中 ./.github/workflows/gate.yml\nʼʼʼ\n\n实跑输出：\nNONE_IN_CODE / ONLY_SAMPLES / NO_CI，正对照命中 `./.github/workflows/gate.yml:7: - run: grep -q 49d5e887 docs/ledger.md`。\n\n副产（这正是条目边界节说的「含隐藏目录」那个坑，值得写进证据）：`rg` 默认跳过隐藏目录，不补 `--hidden` 时正对照里的 `.github/workflows/` 搜不到——即用不补 `--hidden` 的搜索去下「无 CI」的否定结论，会自我印证成假阴性。\n\n补充核对（2026-09-22，直接跑在 /Users/zodyne/Dev/algommw-plus）：`.git/hooks` 仍 ONLY_SAMPLES、无 `.github/workflows`（`no .github`）；目标仓确实没有强制 blob 列的执行载体——主张真值仍成立，只是引用它的那条命令与行号需换。
```

**审核给出的修改意见（要点）**：主张与判据本身成立且是稳定的通用方法（真值不绑 algommw-plus，已用自包含复现独立证成），故留在 playbook；只改三处证据/口径：\n1) 换证据：删掉那条被截断、且现在已不复现 NONE_IN_CODE 的 algommw-plus rg 命令（实测重跑会命中仓根 PLAN.md、tools/check/check.sh、core/src/types/layout_gate.cpp——后两者是会话之后才增改的），改用 minimalRepro 里的自包含脚本作为可复跑证据，并把「补 --hidden 否则漏掉 .github/ 而自我印证成假阴性」这条坑写进边界节。\n2) 去快照：把「PLAN.md:608」这类行号引用改掉——该自述现于 PLAN.md:754，规则行的 R17 在 :800（PLAN.md 已从 937 行涨到 1594 行，:608 现在是无关内容）。行号型引用一律改成引文本身 + 文件，不带行号。\n3) 收窄主张节：把「三处都没有 ⇒」改成与边界节一致的「非文档代码 + hooks 两处无、CI 未展开 ⇒」，消除主张节与边界节的自相矛盾。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 主张节：「三处都没有 ⇒ 该列只是记录/溯源字段」——切片只支持两处（非文档代码无、hooks 只有 sample），CI 一栏输出在 '=== CI' 处被截断，'三处都没有' 超出切片；条目自己的边界节也承认稳妥表述应是「非文档代码 + hooks 两处无，CI 未展开」，故主张节与边界节自相矛盾。
- 为什么节：「在台账里读起来像闸门」「文档自己对该列用途的定义比列名更权威」——前者是切片刻意没有的修辞化定性，后者是规范性原则而非切片中的机械事实（切片只提供 commit 列=起点提交、blob=合成器有版本两个实例）。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
