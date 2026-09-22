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
