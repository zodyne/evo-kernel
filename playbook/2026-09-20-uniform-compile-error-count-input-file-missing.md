---
id: uniform-compile-error-count-input-file-missing
type: lesson
status: validated
scope: global
domain: build-system
tags: [clang, probe, per-tu, error-count, measurement, false-signal]
triggers:
  - "脚本逐 TU 编译并用 `rg -c 'error:'` / `grep -c error:` 统计每个文件的编译错误数"
  - "每个 TU 报出的错误数完全相同且非零（如三个不同源文件整齐地都是 errors=2），准备据此写『每个 TU 都挂』（失败信号）"
  - "编译探针的原始输出里出现 `clang++: error: no such file or directory: '<源文件>'` 或 `error: no input file`"
  - "批量编译探针换了工作目录/少写了路径前缀，但统计出的错误数看着像真实失败"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-ecee-7475-af70-36be1d4ba92f
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [differential-probe-empty-arms-baseline-first, checker-positive-control-or-negative-void]
---

# 逐 TU 统计 `error:` 行数时，「编译器根本没找到输入文件」也会被计成编译错误——指纹是所有 TU 计数完全相同的均匀值

## 主张

用「逐 TU 跑编译命令 + 数 `error:` 行」度量改造前后各文件的编译失败时，若编译命令本身因**输入文件路径不存在**而失败，clang 仍会产出 `error:` 行并被计入——本例 `clang++: error: no such file or directory: 'src/chain/chain.cpp'` 与 `clang++: error: no input file` 恰好 2 行，于是三个互不相同的 TU 全部报出**一模一样的 `errors=2`**。把路径修正为 `core/src/...` 后，同样三个 TU 的 `error lines: 0`。所以「每个 TU 错误数完全相同且非零」是「探针没编到任何东西」的一致指纹，不是「每个 TU 都失败」。

## 为什么

计数口径（`rg -c 'error:'`）对错误来源不做区分：驱动/编译器对「找不到文件」这类调用级失败也是打 `error:` 前缀的，且行数固定（找不到文件 + 没有输入 = 2 行），与源码内容无关。真实编译失败几乎不可能让所有 TU 均匀落在同一个数上（尤其这些 TU 刚在同一棵树上通过了另一条构建路径），均匀值恰恰暴露了计数的是**调用失败**而不是**编译失败**。

## 证据（本会话切片，命令 ↔ 结果）

在 `/tmp/review-refute-literal-first-include-replacement-drops-types/repo_lit` 下（路径少了 `core/` 前缀）：

1. 探针循环（相对路径写在 repo 根下）：`for t in src/chain/chain.cpp src/dpu/doa/snap.cpp src/dpu/doa/geom.cpp …`
   → `REPLACE src/chain/chain.cpp errors=2 REPLACE src/dpu/doa/snap.cpp errors=2 REPLACE src/dpu/doa/geom.cpp errors=2`（三个 TU 均匀 =2）。
2. 同一循环改为打印原始输出 → `clang++: error: no such file or directory: 'src/chain/chain.cpp'`、`clang++: error: no input file`（正好 2 条 `error:`，等于上面的计数）。
3. 把路径改成 `core/src/...` 重跑 → `===== REPLACE core/src/chain/chain.cpp    (error lines: 0) ===== REPLACE core/src/dpu/doa/snap.cpp    (error lines: 0) =====`。

## 边界 / 反例

- 该假计数只发生在**编译命令自身失败**时（路径错、cwd 错、`-I` 之外的可执行/参数问题）；编译器找到了输入文件后，`error:` 行数才是源码诊断数。
- `errors=2` 这个具体数字是 clang 的行为（两条消息），换驱动（gcc、cmake 包装）行数会变——判据是「各 TU 完全相同的均匀值 + 原始输出里含 `no such file or directory` / `no input file`」，不是数字本身。
- 同一次会话里另一层混淆：缺 `-I` 会让探针先报 `fatal error: '<头文件>' file not found`（1 条 `error:`），它同样是探针命令行问题、不是被测改造的失败——计数前先确认探针在**已知能编过的输入**上为 0。
- 本条的修复动作（先核对路径/先看原始输出再读数）不改变被测改造本身的结论：该会话最终仍用 cmake 全量构建（rc + 产物 `libcore.a` 是否存在/字节数）判定 replace 变体失败。

## 失败信号（未来命中即该想起本条）

一张「逐 TU 错误数」表里所有 TU 的数字完全相同（尤其都等于一个小常数）→ 先看原始编译输出里有没有 `no such file or directory` / `no input file`，再决定这张表能不能当证据。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
# 本机实测（Apple clang 17.0.0）。1) 驱动对「输入文件不存在」也打 error: 前缀且固定 2 行，与源码无关：
clang++ -c /no/such/file.cpp -o /dev/null 2>&1 | rg -c 'error:'    # => 2
clang++ -c /no/such/file.cpp -o /dev/null 2>&1                     # => clang++: error: no such file or directory: '/no/such/file.cpp'
                                                                   #    clang++: error: no input files   （本机为复数；切片所记单数，仅措辞差异）
# 2) 于是逐 TU 数 error: 行，在路径写错时得到均匀非零假值（对照组，文件都不存在）：
mkdir -p tu/a tu/b tu/c && for t in tu/a/x.cpp tu/b/y.cpp tu/c/z.cpp; do echo "$t errors=$(cd /tmp && clang++ -c $t -o /dev/null 2>&1 | rg -c 'error:')"; done   # => 三者都 errors=2
# 3) 反例：均匀非零并非该情形专属——不同源文件共用一张坏头文件也得均匀值，但属真·源码失败
printf '#pragma once\nint gBad = ;\n' > /tmp/ce.hpp && printf '#include "/tmp/ce.hpp"\nint a(void){return gBad;}\n' > /tmp/a.cpp && printf '#include "/tmp/ce.hpp"\nint b(void){return gBad;}\n' > /tmp/b.cpp
for t in /tmp/a.cpp /tmp/b.cpp; do echo "$t errors=$(clang++ -c $t -o /dev/null 2>&1 | rg -c 'error:')"; done   # => 两者都 errors=1（无 no such file）
```

**审核给出的修改意见（要点）**：核心可操作判据（先看原始输出里有没有 no such file or directory / no input file，并先确认探针在已知能编过的输入上为 0）站得住、可复现，保留注入。但需收窄一般律：一是把标题「…的指纹是所有 TU 计数完全相同的均匀值」与「主张」里「『每个 TU 错误数完全相同且非零』是…的一致指纹」改为「是值得先怀疑的**可疑信号**，而非判据」——本机反例证明均匀非零值同样来自真·源码失败（所有 TU 共用一张坏头文件，errors 均匀=1，原始输出无 no such file），与本条「边界」第3点自认的缺 -I 情形（均匀值 + fatal error … file not found）亦自相矛盾；二是把「真实编译失败几乎不可能让所有 TU 均匀落在同一个数上」同幅收窄，或删去；三是对「换驱动（gcc、cmake 包装）行数会变」标注为未实测的推断。建议在「边界」补入反例：均匀值本身不是判据，唯一判据是原始输出标记 + 已知能编过的输入上为 0。frontmatter 的 type 为 lesson 而条目位于 playbook/，如两处语义不同请一并核对。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 「每个 TU 错误数完全相同且非零」是「探针没编到任何东西」的一致指纹，不是「每个 TU 都失败」（标题与「主张」同调）——被反例证伪：本机实测两个不同源文件共用一张坏头文件时同样得到均匀的 errors=1，且那是真·源码失败，原始输出无 no such file/no input file；本条「边界」第3点自认的缺 -I 情形（fatal error … file not found）也会产生均匀值，与标题自相矛盾。
- 真实编译失败几乎不可能让所有 TU 均匀落在同一个数上——同为过度一般化；共用头文件/公共 -I 缺失即反例。
- 换驱动（gcc、cmake 包装）行数会变——切片只观测了 clang，未对 gcc 做过任何实测，属推断（虽以告诫口吻写出）。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
