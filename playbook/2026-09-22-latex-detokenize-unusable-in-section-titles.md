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
verified_by: command
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

## 为什么

`\detokenize` 的作用是把参数变成 catcode-12 的字符序列再打印，于是 `_` 不是「下标」而是字面字符 ——
在正文里正确，在**会被写进辅助文件再读回**的语境（`.toc`）里就成了裸 `_`，读回时按数学模式解析即报错。
两遍编译的差异正是这个「写入→读回」的往返造成的。

## 证据（本会话实测，含踩坑细节）

- 第二遍报 `Missing $ inserted`，位置在目录/标题。
- 参数内写 `\_` **会原样打印反斜杠**（应用裸 `_`，因为 detokenize 已令其 catcode=12）。
- 参数内写 `\%` 会把整行注释掉 —— 除 `%` `&` `#` 外，`\%` 也是雷。

## 边界 / 反例

- 只针对「会进辅助文件再读回」的语境（标题/目录/交叉引用）；正文里的 `\detokenize` 不受影响。
- 与 `xelatex-section-math-hyperref-texorpdfstring`（标题里夹数学）是**两个不同的成因**，
  都用 `\texorpdfstring` 或换写法不等于互相同解，别互相套用。
