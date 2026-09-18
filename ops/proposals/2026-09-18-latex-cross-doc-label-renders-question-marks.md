---
id: latex-cross-doc-label-renders-question-marks
type: lesson
status: candidate
scope: global
domain: latex
tags: [latex, xelatex, cleveref, label, cross-reference, pdf-verify, silent-breakage]
triggers:
  - "ref/cref 指向另一个 .tex 里定义的 label（或被引用的 label 不在本编译单元里）"
  - "latexmk 报 Latex failed to resolve N reference(s) / Reference `xxx' undefined，但仍写出了 PDF（失败信号）"
  - "从 PDF 抽出的文本里 grep 到 ?? 或「见 ??。」（失败信号）"
  - "把大文档拆成多份 .tex 各自编译，或把章节从另一份文档搬过来"
  - "构建成功、页数正常，但要确认交叉引用真的都解析了"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2d9-e94b-7323-8254-c19b2aefb87d
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [generated-tex-lint-gate-tab-swallows-macro]
---

# 跨文档引用不解析：latexmk 照写 PDF，正文里留 `??`

## 主张
LaTeX 的 `label`/`ref`/`cref` 只在**一次编译的同一个文档**内解析。被引用的 label 如果定义在另一个 `.tex`（另一份 PDF）里，构建不会失败：latexmk 照常写出 PDF，只在日志里留 `LaTeX Warning: Reference ... undefined` / `Latex failed to resolve N reference(s)`，PDF 该处渲染成 `??`。所以「构建成功 / 写出了 PDF」不能当作"引用解析成功"的证据，收尾必须从 PDF 抽文本 grep `??`。

## 为什么
标签解析是编译单元内的：latexmk 只会重跑本文件的 job 去收敛 `.aux`，别的文档的 `.aux` 不在它的输入里——这不是"多编一次就好"的临时未收敛，而是**结构性**不解析。而它同时又是"构建成功"的：字节写出了、页数也正常，只有一行 warning 和正文里的 `??` 泄露真相；warning 混在 `tail -8` 的构建摘要里极易被当噪音放过。

## 证据（session 01a0b2d9，suc221-pointcloud-2.0）
- 构建：`bash docs/build_docs.sh pointcloud_filter_theory 2>&1 | tail -8` → `1724546 bytes written`（写出产物）**同时** `Latexmk: Summary of warnings from last run of *latex: Latex failed to resolve 1 reference(s)`。
- 查 label 归属：会话专门跑了"sec:gate-safety 引用/定义"与"全 docs 搜 sec:gate-safety"两轮 `rg -n 'sec:gate-safety' docs/*.tex`，命中的**定义**是 `docs/dbf_filter_spec.tex:286:\subsection{一级门什么时候是安全剪枝}\label{sec:gate-safety}` —— 即被查的 label 定义在另一份文档里。`docs/pointcloud_filter_theory.tex` 自身加载了 cleveref（`\usepackage{cleveref}`、`\crefname{table}{表}{表}` 等）。
- 产物核对：对新 PDF 抽出的文本 `grep -an '??' /tmp/theory.txt` → 命中 `1468:剪枝，而是第二个判别器，见 ??。`；HEAD 版本旧 PDF 无 `??`。新旧页数 29 → 30 —— 页数本身说明不了问题，能定位问题的是文本里的 `??`。
- 旁证（不是孤例）：同一轮批量构建里另一份文档也报 `LaTeX Warning: Reference 'sec:dead' on page 1 undefined`、`Reference 'sec:hpr' on page 1 undefined`。

## 边界 / 反例
- 切片未展示 theory.tex 里那一行引用原文，label 归属是按 `rg` 命中的定义位置判定的；本条主张的是"label 不在本编译单元 → 编译过、正文 `??`"这一机制。
- 真要跨文档引用（在一份 PDF 里引另一份 PDF 的章节号）得上 `xr` / `xr-hyper` 把外部 `.aux` 拉进来；本条是**没上这些包时的默认行为**。
- `??` 还有别的成因（label 拼错/从未定义、同文档缺第二次编译）。所以看到 `??` 先 `rg` 这个 label **定义在哪**：定义在本文件 → 收敛问题（再编一次）；只定义在别的 `.tex` → 跨文档问题，要么把 label 搬进本文件，要么上 `xr`。
- 同族不同坑：`generated-tex-lint-gate-tab-swallows-macro` 是"编译无 warning、PDF 静默损坏"（TAB 吞宏），门禁查生成侧；本条是"有 warning 但构建成功"，门禁应设在"抽 PDF 文本查 `??`"，而不是查退出码。

## 失败信号（未来命中即该想起本条）
- 构建日志出现 `Latex failed to resolve N reference(s)` 或 `Reference 'xxx' undefined`，但退出码 0、PDF 也照常写出来了。
- 从 PDF 抽出的文本里 grep 到 `??` / `见 ??。`。
- 拆文档重构（把章节搬进另一个 `.tex`）之后，PDF 里出现指不到东西的引用。
