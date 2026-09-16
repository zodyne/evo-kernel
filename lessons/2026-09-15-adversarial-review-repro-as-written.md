---
id: adversarial-review-repro-as-written
type: lesson
status: candidate
scope: global
domain: code-review
tags: [code-review, adversarial, verification, repro]
triggers:
  - "对抗式/怀疑式复核别人的审查发现、bug 报告或重构声明"
  - "判 refuted/confirm 之前，先逐字复现发现方声称的 repro 命令"
  - "自己重写了一个『等价』命令去跑，结果与声称的对不上（失败信号）"
  - "复核代码 review 结论，需拿行号/计数与声称值逐字对照"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a736-c1c3-7353-8a3d-4313be973fae
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
---

对抗式复核审查发现时，先逐字复现发现方声称的 repro 命令（"as written"），再用其输出与发现里引用的行号/数量对照，最后才判 refuted 与否；改过 flag/正则的「等价」命令会制造误判。

为什么：本例发现方称 `core/src/math/eig.c` 有 ~30 个无前缀裸变量。验证方没有直接写自己的 grep，而是显式先跑 `echo "--- claimed repro (as written) ---" && rg -n '<原始正则>'`，得到逐文件计数（complex.c 3 / eig.c 20 / fft.c 24 / …），再与引用行号 eig.c:26-28（`uint32_t i/j/sweep`）、:48-49（`uint32_t p/q`）逐字核对，最终 refuted=false、confidence=high。把「验证」锚定在发现方自己的命令上，而非验证方重写的版本，才能区分「发现本身错了」和「我重写命令时引入的偏差」。

边界：只适用于发现方给出了可复现 repro 字符串的情况；若没有，只能自己构造 repro 并显式标注「非原样复现」。行号核对要容忍空行/注释造成的 ±1 偏移，以「变量名 + 类型」为准而非死对行号。
