---
id: xelatex-section-math-hyperref-texorpdfstring
type: lesson
status: candidate
scope: global
domain: latex
tags: [latex, xelatex, hyperref, texorpdfstring, pdf-bookmark]
triggers:
  - "xelatex/hyperref 编译警告 Token not allowed in a PDF string"
  - "\\section 或 \\subsection 标题里含 $...$ 数学公式，PDF 书签/目录出现缺字或乱码"
  - "编译 LaTeX 报 removing math shift，数学内容进不了 PDF 书签"
  - "hyperref 警告里出现 Token not allowed / math shift（失败信号）"
  - "中文 LaTeX 报告的 section 标题带数学表达式，编译后书签文字残缺"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a32b-26e4-7174-9095-5beeb15e80f3
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
---
一句话主张：xelatex 里 `\section{...$...$...}` 这类标题里夹了数学公式时，hyperref 会报 `Token not allowed in a PDF string (Unicode): removing 'math shift'` 警告，并把数学内容从 PDF 书签里剔除；正确写法是用 `\texorpdfstring{<TeX 版>}{<纯文本版>}` 给书签单独提供不含数学的纯文本。

为什么：hyperref 要把 section 标题写进 PDF 书签（bookmark），而书签只吃纯文本，`$...$` 的 math shift、`\oplus`、`\mathrm` 这类宏在 PDF 字符串里都是非法 token，hyperref 只能「removing」掉，导致书签文字缺一块。`\texorpdfstring{}{}` 第一参数给正文排版用（可含数学），第二参数给书签用（必须纯文本），从根上消除这个警告。

边界/证据链接（均来自会话 01a0a32b 的命令 ↔ 结果切片）：
- 切片里 `grep -A2 "Token not allowed" /tmp/tex2.log` 抓到 `Package hyperref Warning: Token not allowed in a PDF string (Unicode): removing 'math shift'`，警告真实出现。
- 触发源被 `grep -n "结构分析：虚拟阵"` 定位到 `104:\section{结构分析：虚拟阵 $=\mathrm{Rx}\oplus\{0,\Delta y\}$}`——标题带 `$...$` 数学。
- 修复落点有命令级证据：`grep -n "texorpdfstring"` 返回 `105:\texorpdfstring{}{}`，即在该标题后插入了 `\texorpdfstring{}{}` 包住数学部分。
- 修复后 `xelatex` 重编，`=== 剩余警告 ===` 里 `Token not allowed` 消失（只剩无关的 float specifier 警告），证明 `\texorpdfstring` 确实消掉了这个警告。
