---
id: xelatex-rerun-loop-on-aux-cleanup
type: lesson
status: validated
scope: global
domain: latex
tags: [latex, xelatex, build, rerunfilecheck, cross-reference, aux-files]
triggers:
  - "编译 xelatex/pdflatex 报告时反复出现 rerunfilecheck 'Rerun' 警告，编不完"
  - "在编译命令链里 rm 删除 .aux/.out/.toc 辅助文件"
  - "LaTeX 交叉引用/书签提示 'Label(s) may have changed. Rerun' 始终不消失"
  - "为消除 rerun 警告反复重跑 xelatex 却一直要求再编译一次"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:8eefe3a4-9aa6-49b9-a019-8895ad7d83e6
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# xelatex 编译链里 rm 删除 .aux/.out 会造成 rerunfilecheck "Rerun" 伪死循环；应连续编译两遍后再单独清理辅助文件

## 主张
反复编译 xelatex/pdflatex 以稳定交叉引用与书签时，**不要在同一命令链里 `rm` 删除 `.aux`/`.out`/`.toc` 辅助文件**。一旦删除，下一次编译就是"从无到有"重新生成这些文件，`rerunfilecheck` 通过对比新旧两次编译的辅助文件差异来判定是否需要再编译——文件每次被删后再生，它永远判定"文件已变化"，持续吐出 `Warning: File '...out' has changed. Rerun` / `Label(s) may have changed. Rerun`，形成**伪死循环**（其实文档早已正确）。正确做法：先连续编译 2 次让 `.aux` 自然稳定，**最后单独一步**再清理辅助文件。

## 为什么
`rerunfilecheck` 的工作前提是辅助文件在两次编译间**持续存在**，靠差异推断"引用还没稳定"。在编译命令后紧跟 `rm` 等于每次都把"上一帧"抹掉，差异检测失去基准，于是对任何带 `\label` 的文档都会无差别提示 rerun。把清理从编译链里剥离、后置成独立步骤，辅助文件才得以跨编译保留，第二次编译即可让引用收敛。

## 证据（本会话命令 ↔ 结果，切片硬证据）
- 命令模式 `xelatex -interaction=nonstopmode false_alarm_filter_report.tex … | tail -N && rm -f false_alarm_filter_report.aux .log .out .toc` 被连续执行 4 次，每次返回：`rerunfilecheck Warning: File 'false_alarm_filter_report.out' has changed. (rerunfilecheck) Rerun` —— 即"编译 + 删 out"被反复跑、警告反复出现。
- 诊断确认文档 `false_alarm_filter_report.tex` 有 5 个 `\label{`（`grep -n "\label{"` 命中 5 行）但 `\ref{` 命中数为 0（`grep -n "\ref{"` 无输出）——说明 rerun 警告并非真实引用未收敛，而是 `rm .out` 制造的伪循环 + 无引用时的良性提示叠加。
- 脱离"编译即 rm"模式后，`false_alarm_filter_report.pdf` 正常生成：最终 `ls -lh` 显示 `233K … false_alarm_filter_report.pdf`，较中段产物（223K）内容完整。

## 边界 / 反例
- 若文档**完全没有 `\ref`/书签**，"Label(s) may have changed. Rerun" 本身是良性警告，可直接忽略；但混在编译链里的 `rm` 仍会放大诊断噪音、掩盖真正未收敛的引用，故清理仍应后置。
- 连续编译 2 遍对绝大多数文档足够；若用了复杂目录/索引/`bibtex`/`makeindex`，可能需 `xelatex→bibtex→xelatex→xelatex` 的既定序列——但**辅助文件全程都要保留**，清理永远是最后一步。
- 仅删 `.log` 不影响收敛（`rerunfilecheck` 不看 `.log`）；本条针对的是被删的 `.aux`/`.out`/`.toc` 这类参与收敛判定的文件。

## 失败信号（未来命中即该想起本条）
- 编译 LaTeX 时命令写成 `latex … && rm -f *.aux *.out` 这类"编译即删辅助文件"的形式。
- 反复重跑 xelatex，每次都报 `rerunfilecheck … has changed. Rerun`，似乎永远编不完。
- 文档里其实没有/极少 `\ref`，却一直收到 `Label(s) may have changed. Rerun`。
