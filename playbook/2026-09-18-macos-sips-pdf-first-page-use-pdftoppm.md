---
id: macos-sips-pdf-first-page-use-pdftoppm
type: lesson
status: validated
scope: global
domain: pdf-tooling
tags: [macos, sips, pdftoppm, poppler, pdf, visual-check]
triggers:
  - "在 macOS 上要把多页 PDF 的某一页渲染成 PNG 做视觉复核"
  - "sips -s format png 转 PDF 只拿到首页，找不到页码参数（失败信号）"
  - "检查 PDF 报告里中文 / 表格排版是否正常"
  - "不确定本机有没有 pdftoppm / poppler"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a80b-0eeb-7719-ba82-31f86fbaeaa7
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# macOS 上渲染 PDF 指定页：`sips` 只给首页，要用 poppler 的 `pdftoppm -f N -l N`

**主张**：macOS 自带的 `sips -s format png --out x.png in.pdf` 对多页 PDF **只产出第一页**一张图（没有页码 / 页范围参数）；要复核第 N 页必须用 poppler 的
`pdftoppm -f N -l N -r <dpi> -png in.pdf outprefix`（输出文件名带真实页号，如 `outprefix-3.png`）。

**证据（会话 01a0a80b）**：
- 想核对 PDF 第 3 页的表格排版，先用系统自带工具：
  `sips -s format png --out /tmp/pdfpage.png /tmp/spc865_w2/report.pdf` → 只得到一张 21 KB 的 PNG（首页），拿不到第 3 页。
- `which pdftoppm mutool qpdf` → 只有 `/opt/homebrew/bin/pdftoppm`（poppler 由 brew 安装，qpdf/mutool 未装）。
- `pdftoppm -f 3 -l 3 -r 80 -png /tmp/spc865_w2/report.pdf /tmp/pdfp3` → `/tmp/pdfp3-3.png`，据此确认该页表格与中文渲染正常。
- 本机复验（2026-09-18，同一份 7 页 PDF）：`pdfinfo` → `Pages: 7`；`sips` → 单张 842×595 PNG（首页，21 027 B）；`pdftoppm -f 3 -l 3 -r 80 -png` → `evo-p3-3.png`，51 441 B（字节数明显不同，确为另一页）。

**边界 / 反例**：`sips` 能做格式转换但没有"页"这个维度；`pdftoppm` 属 poppler（`brew install poppler`），未装时 `qpdf`（结构化变换，不栅格化）与 `mutool`（若装了才可用）不能按同一条命令替代。高 dpi 渲染大页时注意产物体积与耗时；输出后缀是真实页号，脚本里不要假定 `-1`。

另有一档是完全失败（2026-09-18 补）：`sips -s format png` 并非「总能拿到首页」——有些 PDF 会让它直接失败，stderr 打 `CoreGraphics PDF has logged an error. … Error 13: an unknown error occurred`，**rc=13 且完全不产出目标 PNG**；同一台机器同一条命令换一份 PDF 就成功（本机 rc=0、`PNG 595x842`），故失败取决于输入 PDF 而非环境写错。所以转换后要校验产物（`[ -s out.png ]` 或 identify 验图），别只看「命令跑过了」，也别只看 rc（流水线里 rc 常被 `;`/管道吞掉）；要稳定栅格化一律走 `pdftoppm`。

**失败信号（未来命中即该想起本条）**：想核对"第 N 页"却总看到首页内容；或批量循环里 `sips` 反复覆盖出同一张图。
