---
id: latex-detokenize-unusable-in-section-titles
type: playbook
status: validated
scope: global
domain: latex
tags: [latex, xelatex, detokenize, section, toc, hyperref]
triggers:
  - "xelatex 第一次编译通过、第二次报 'Missing $ inserted'，报错指向目录/章节标题"
  - "想在章节标题里显示带下划线的标识符（如命令名、文件名）"
  - "在 \\detokenize 参数里写了 \\_ 结果打印出反斜杠"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:inbox/capture-2026-09-21-02-50-31-391-qy1t
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [xelatex-section-math-hyperref-texorpdfstring, generated-tex-lint-gate-tab-swallows-macro]
---

# `\detokenize` 不能用在章节标题里：第一遍过、第二遍读 `.toc` 才炸

**主张**：`\detokenize` 宏**不能**用在 `\section` / `\subsection` 标题里：它写 `.toc` 时留下**裸下划线**，
第一遍编译通过，**第二遍读目录**才报 `Missing $ inserted`。正确做法是正文用
`\newcommand{\id}[1]{\texttt{\detokenize{#1}}}` 且参数内一律用**裸下划线**；
章节标题里不要用该宏。

## 证据

- 第二遍编译报 `Missing $ inserted`，位置在目录/标题。
- 参数内写 `\_` **会原样打印反斜杠**（应用裸 `_`，因为 detokenize 已令其 catcode=12）。
- 参数内写 `\%` 会把整行注释掉 —— 除 `%` `&` `#` 外，`\%` 也是雷。

三条都是「报了错 → 改写法 → 错误消失」的观测链。**成因（为什么裸 `_` 会在读回时炸）capture 未记录**
——本条不解释机制，只记「什么写法会炸、什么写法不炸」。

证据等级：`verified_by: human` —— 来源是会话内的 prose 摘要（`capture:…`），无命令转录。
一次两遍 xelatex 编译即可复现，跑通后可升回 `command`。

## 边界 / 反例

- 观测范围是**章节标题 + `.toc`**（`\section`/`\subsection`）。其它「会进辅助文件再读回」的语境
  （如交叉引用）**本次未测**，不要替它们下结论。
- 正文里的 `\detokenize`（不经辅助文件往返）不受影响——这一半是本次的对照观测。
- 与 `xelatex-section-math-hyperref-texorpdfstring`（标题里夹数学）是**两条独立记录**，
  本次没有比过两者的成因异同，也没有验证过修法能否互换。
