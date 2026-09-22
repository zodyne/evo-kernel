---
id: bsd-grep-mixed-ere-bre-repetition-operand
type: lesson
status: validated
scope: global
domain: macos-tooling
tags: [grep, bsd, macos, regex, git-diff, shell]
triggers:
  - '在 macOS 上用 git diff | grep -E "^\+" | grep -v "^\+\+\+" 提取新增行，只回一行 grep: repetition-operator operand invalid（失败信号）'
  - '同一条管道里有的 grep 带 -E、有的没带，模式里又用反斜杠转义了 + 号'
  - 'grep 零输出且 rc=2，被当成「git diff 没有新增行 / 没有改动」的否定证据'
  - '要过滤或统计 diff 里 + 开头的新增行与 +++ 文件头'
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bca0-8603-71a7-918d-287a6ee55dfd
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [bsd-grep-empty-subexpression-hard-error]
---

# macOS BSD grep：同一管道混用 -E 与 BRE，`^\+\+\+` 报 repetition-operator operand invalid

## 主张

在 macOS 自带 BSD grep（本机 2.6.0-FreeBSD）上，从 `git diff` 里抽新增行时如果把 `-E` 只加在第一个 grep 上：

`git diff … | grep -E '^\+' | grep -v '^\+\+\+'`

第二个 grep 会以 rc=2 硬失败并打印 `grep: repetition-operator operand invalid`，**整条管道零输出**——看起来像「diff 里没有新增行」，实际是过滤器根本没工作。修复只需统一写法：每个 grep 都带 `-E`（`grep -vE '^\+\+\+'`），或干脆不用反斜杠（BRE 下 `+` 就是字面量：`grep '^+'`、`grep -v '^+++'`）。

## 为什么

第二个 grep 没带 `-E`，BSD grep 按 BRE 把模式里的 `\+` 当重复算子解析，`^\+\+\+` 这种连写触发 `repetition-operator operand invalid`（不是「零命中」，是解析失败）。危险不在报错文本本身（它就在眼前），而在**第一个 grep 是好的、错误来自后一个 grep**：一旦只看 stdout / 聚合退出码，空输出会被读成「git diff 没有新增行」的否定证据。同类「BSD grep 硬错误 + 零输出」的坑见 related 条目 `bsd-grep-empty-subexpression-hard-error`（那个是空分支报 empty (sub)expression，成因不同）。

## 证据（切片命令 ↔ 结果）

session:01a0bca0（`/Users/zodyne/Dev/algommw` 审计会话），两条同型命令各失败一次：

- `git diff core/src/chain/chain.c core/src/types/waveform.c | grep -E '^\+' | grep -v '^\+\+\+' | head -40`
  ↳ `grep: repetition-operator operand invalid`
- `git diff python/radar_viz/pipeline.py python/radar_viz/session.py | grep -E '^\+' | grep -v '^\+\+\+' | head -50`
  ↳ `grep: repetition-operator operand invalid`
- 会话随后放弃这层过滤，改为直接 `git diff … | head -80`（证据链止于报错，没拿到新增行清单）。

## 本机复核（reflector，2026-09-21，同一台机器）

`grep --version` → `grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`；输入为三行文本 `a` / `+b` / `+b+++x`：

- `grep -E '^\+'` → 命中 `+b`、`+b+++x`，rc=0（第一个 grep 确实没问题）。
- `grep -v '^\+\+\+'`（无 -E）→ `grep: repetition-operator operand invalid`，rc=2，零输出。
- `grep -vE '^\+\+\+'` → 正常输出；`grep -v '^+++'` → 正常输出，均 rc=0。
- `grep '^\+'`（BRE，单个转义加号）→ 正常命中；错误只在 `\+\+\+` 连写且缺 `-E` 时出现。

## 边界 / 反例

- 本条只覆盖 macOS 自带 BSD grep 2.6.0-FreeBSD；换 GNU grep 或别的平台前需重新验证，不要直接外推。
- 触发点是**同一管道里 ERE/BRE 混用 + 反斜杠转义 `+`**；全部带 `-E` 或全部用无转义 BRE 写法都能避开。
- 别把 rc=2 与 `grep` 正常的「无命中 rc=1」混为一谈：rc=2 说明命令没在工作，此时空输出不能当结论。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
本机 /usr/bin/grep = BSD grep 2.6.0-FreeBSD，以下已实测：
  printf 'a\n+b\n+b+++x\n' > /tmp/gt.txt
  /usr/bin/grep --version            # → grep (BSD grep, GNU compatible) 2.6.0-FreeBSD
  /usr/bin/grep -v '^\+\+\+' /tmp/gt.txt
      # stderr: grep: repetition-operator operand invalid ; 零 stdout ; rc=2
  /usr/bin/grep -vE '^\+\+\+' /tmp/gt.txt
      # → a / +b / +b+++x ; rc=0（修复用 -E 即可）
  /usr/bin/grep '^zzz' /tmp/gt.txt   # rc=1（无命中，与 rc=2 区分）
机制旁证：`^\+\+` rc=0 命中、`^\+\+\+` 报错、`a\+\+` 报错——即前导原子后接两个及以上 `\+` 算子时解析失败。
```

**审核给出的修改意见（要点）**：无

**判定**：keep · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
