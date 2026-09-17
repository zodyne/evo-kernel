---
id: generated-tex-lint-gate-tab-swallows-macro
type: lesson
status: validated
scope: global
domain: code-generation
tags: [latex, codegen, lint, tex, report-generation, silent-corruption]
triggers:
  - "程序生成 .tex/LaTeX 报告，PDF 印出裸字宏名（如 extbf）"
  - "生成的 .tex 含 TAB 导致 LaTeX 宏失效"
  - "LaTeX 编译通过但 PDF 内容不对（失败信号）"
  - "给报告生成脚本加 .tex 门禁校验"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a4ee-6d56-777c-a410-3236022192ef
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: []
---

# 生成 .tex 的门禁：TAB 会吞掉紧跟的宏名，且无报错

## 主张

程序（Python）拼 .tex 时，源码里一个 TAB 紧跟宏名会让该宏失效：`\textbf` 在 PDF 里印出裸字 `extbf`（反斜杠被 TAB 吃掉），且 LaTeX 编译不报错、不告警——属于静默损坏。应在生成脚本里加一道 .tex 门禁 lint，检查 TAB 与被吃掉的宏名（如裸 `extbf`/`extbf{`）。

## 证据

- 审查发现 `tex 里的 TAB（PDF 印出裸字 extbf）`，把 1 个 TAB 换成反斜杠后修复。
- `make_report.py` 新增 `lint_tex()`：检查 `\t`（TAB）与裸宏名（`extbf` 等）。
- 修复后每次生成末尾打印 `.tex 门禁：无 TAB / 无被吃掉的宏名 ✓`；也出现过 `.tex 门禁未过` 的拦截（`bpm_2t8r_report.tex:36 出现裸字 extbf（宏被吃掉）`）。

## 边界

- 静默损坏类：编译退出码 0、无 warning，只能靠 lint 门禁在生成侧拦截。
- 同类隐患不止 extbf：任何「反斜杠 + 宏名」前误插 TAB/控制字符都可能复现。
