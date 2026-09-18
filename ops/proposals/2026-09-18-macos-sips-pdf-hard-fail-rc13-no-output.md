---
id: macos-sips-pdf-hard-fail-rc13-no-output
type: lesson
status: candidate
scope: global
domain: pdf-tooling
tags: [macos, sips, pdf, coregraphics, silent-failure, pdftoppm]
triggers:
  - "sips -s format png --out x.png in.pdf 报 CoreGraphics PDF has logged an error / Error 13，且 x.png 不存在"
  - "同一台机器同一个 sips 命令，某份 PDF 转出 PNG、另一份完全转不出（失败信号：结果随输入文件而异）"
  - "脚本用 sips 批量 PDF→PNG，只当命令跑过就算成功、没校验输出文件"
  - "要可靠地栅格化 PDF，不确定 sips 是否总能产出图片"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-5329-73b1-bdd8-c2d793d48f94
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [macos-sips-pdf-first-page-use-pdftoppm]
---

`sips -s format png` 转 PDF 并不是「总能拿到一张图（首页）」：有些 PDF 会让它直接失败——stderr 打 `CoreGraphics PDF has logged an error. … Error 13: an unknown error occurred`，命令以非零码退出且**完全不产出**目标 PNG；所以转换后必须校验输出文件是否存在（不能只看「命令跑过了」），需要可靠栅格化时用 `pdftoppm`。

**为什么**：本会话在**同一台机器、同一条命令**上得到相反结果，说明失败取决于输入 PDF 而不是环境写错：

- 失败：`sips -s format png --out /tmp/sipsprobe2.png /Users/zodyne/Documents/mmWave-Radar-Interface-Control.pdf` → `CoreGraphics PDF has logged an error. Set environment variable "CG_PDF_VERBOSE" to learn more.`（切片处被截断；2026-09-18 复跑同一命令得 rc=13、`/tmp/sipsv.png` 不存在、错误行补全为 `Error: Cannot extract image from file. / Error 13: an unknown error occurred`）。
- 成功：`P="…/waveform.pdf"; pdfinfo "$P" | rg -i '^Pages'; sips -s format png --out /tmp/sp.png "$P"` → `Pages: 3`、`sips rc=0`、`/tmp/sp.png PNG 595x842 … 72392B`。

也就是说，把 sips 当「PDF→PNG 的第一跳」写进脚本，遇到这些 PDF 时下游拿到的是「文件不存在」，而不是「只有首页」。

**反例/边界**：
- 本条只证明「sips 会整份转不出来、且不落盘」，不解释根因（该 PDF 2.7 MB，是否含 sips/CoreGraphics 不支持的编码或加密未验证）——不要据此推断「大文件必失败」。
- 与 related 的分工：related 讲成功路径下 sips **只有首页、没有页码维度**；本条讲**连首页都拿不到**的失败档。要指定页/要稳定产物，两条都指向 `pdftoppm`（`brew install poppler`）。
- rc 与产物要一起看：本例 rc=13 非零，但流水线里 rc 常被 `;`/管道吞掉，所以校验 `[ -s out.png ]`（或转换后用 `identify` 验图）比只看 rc 稳。

**证据（本会话切片命令 ↔ 结果）**：
- `ls -la /tmp/sipsprobe.png 2>&1; sips -s format png --out /tmp/sipsprobe2.png /Users/zodyne/Documents/mmWave-Radar-Interface-Control.pdf; echo "rc=$?";` → `✗ … CoreGraphics PDF has logged an error. Set environment variable "CG_PDF…`（整条命令被判非零）。
- `P="/Users/zodyne/Documents/桌面归档-2026-09-16/01-项目文档/waveform.pdf"; pdfinfo "$P" 2>/dev/null | rg -i '^Pages'; sips -s format png --out /tmp/sp.png "$P"` → `Pages: 3  /private/tmp/sp.png sips rc=0 /tmp/sp.png PNG 595x842 … 72392B`。
