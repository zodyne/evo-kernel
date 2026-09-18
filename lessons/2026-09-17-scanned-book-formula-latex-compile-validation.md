---
id: scanned-book-formula-latex-compile-validation
type: playbook
status: candidate
scope: global
domain: document-processing
tags: [latex, xelatex, amsmath, transcription, validation, scanned-book]
triggers:
  - "把扫描书/扫描 PDF 里的公式图片转写成 LaTeX，要验证转写是否正确"
  - "公式 LaTeX 转写后不确定语法对不对，不敢往下写"
  - "批量转写公式后需要一个硬验证门，靠人眼看不放心"
  - "xelatex 编译不过，报某条公式转写有语法错（失败信号）"
  - "公式转写 JSON 里某条编译报错，要定位是哪一条"
created: 2026-09-17
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: session:01a0ad4f-ca92-7710-933f-0b52f3bd31a2
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related:
  - formula-region-crop-upscale-before-vision-transcribe
  - tikz-figure-reproduction-raster-diff-verification
  - generated-tex-lint-gate-tab-swallows-macro
---

# scanned-book-formula-latex-compile-validation

## 一句话主张

扫描书公式转写成 LaTeX 后，逐批把公式拼进一个最小 `\documentclass{article}` + `amsmath` 文档，
用 xelatex 编译，`exit=0` 作为「转写语法正确」的硬验证门；编译不过就说明某条公式转写有语法错。

## 为什么

公式转写对不对不能靠人眼——几十条公式满屏 `\frac`/`\sqrt`/`\sum`，反斜杠和上下标极易漏。
编译是确定性门：exit=0 客观证明每一条都进了 amsmath 环境且 LaTeX 语法合法，比逐条目视快且不漏。
会话内 chunk01 的 42 条公式（式 2.16–2.54，8 页 40 区域）全部经此编译通过。

## 边界

编译通过只证明 LaTeX **语法**正确，不证明转写的**内容/语义**与原图一致；
内容忠实度要另走数值化比对（见 tikz-figure-reproduction-raster-diff-verification）。
也不是 lint：编译抓不到「编译通过但 PDF 内容错」的宏吞吃问题（见 generated-tex-lint-gate-tab-swallows-macro）。
本方法验证的是转写字符串的语法合法性，属 transcription 管线后段的验证门。

## 证据

命令：python3 读 meta/latex/chunk01.json，把 42 条 LaTeX 拼成最小 xelatex+amsmath 文档编译，
结果 `42 equations exit=0`，产物 `/tmp/chk01.pdf`（34729 字节）；矩阵子集另编译得 `exit=0`，产出 `/tmp/mat-1.png` 等 4 张。
