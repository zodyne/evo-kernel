---
id: embedded-image-sha256-cross-doc-same-figure
type: lesson
status: candidate
scope: global
domain: document-processing
tags: [pdf, pymupdf, image, sha256, dedup, provenance]
triggers:
  - "从同一项目的多份 PDF（不同版本/不同报告）抽取内嵌图片，要判断两张图是不是同一张"
  - "想把某张图当独立证据/独立来源引用，但怀疑它只是另一份文档里那张图的副本（失败信号）"
  - "图表在文本层抽不到，需要把内嵌位图导出、归集、去重"
  - "同一张图出现在多份文档里，拿不准该以哪一份的分辨率/版式为准"
  - "用 hashlib 给导出的图片归集去重，想确认跨文档的重复图有没有真的抓到"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7de-9a4d-7719-ba82-31f03c7dd2a5
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pdftotext-md5-roundtrip-verify-corpus-integrity, dual-repo-copy-drift-fails-golden-first-diff]
---

# 跨文档判「是不是同一张图」：导出内嵌位图后比 SHA-256

## 主张

要判断两份 PDF（同一项目的不同版本/不同报告）里的图是不是同一张，把各自的页内嵌图导成 PNG 后比 SHA-256：hash 完全相同即同一张位图被两份文档共用（复用/派生关系）。这时不能把这张图当成两份独立证据，也不该按文档数量重复计数。

## 为什么

文档族里常见「新报告沿用旧报告的图」。凭文件名、页号、图注都判不出来，凭肉眼看也容易把「同一张图被重排版」误判成两张；而位图字节是可判定的：同 hash 就是同一份像素数据，不同 hash 只能说明字节不同。抽取时顺手 `hashlib` 归集（脚本里 `seen={}` 按 hash 去重）就能把「文档数」与「独立图数」分开，避免把同一张图当两次独立佐证。

## 证据（切片命令 ↔ 结果）

- 抽取脚本（heredoc）逐字含 `import fitz, os, hashlib` 与 `seen={}`（按 hash 归集），每张导出图打印 `tag pXX imgN -> 路径 宽x高`：
  - `SPC p4 img0 -> /tmp/spc865_x/img/SPC_p04_0_x41.png 564x615`
  - `SPC p5 img0 -> /tmp/spc865_x/img/SPC_p05_0_x47.png 1920x1092`
- 另一份文档的页级清单：`matlab page 3 imgs 1 size [(564, 615)]`（该文档这一页只有一张 564×615 图）。
- 跨文档比对：`cd /tmp/spc865_x/img && shasum -a 256 SPC_p04_0_x41.png MAT_p03_0_x32.png | awk '{print $1}' | uniq -c`
  → `2 5ffc9a8bce049843d85867008288654e7f85c782fe1e8f9aa1e60ba49f5209e7`
  —— 文件名标为 SPC 第 4 页 / MATLAB 第 3 页的两张图逐字节相同（尺寸同为 564×615），即同一张位图被两份文档共用。

## 边界 / 反例

- hash 相同只证明「同一张位图被复用」，**不**证明两份文档的图注/结论一致，也**不**说明哪一份文档权威。
- 反向不成立：同一张图若被重新导出、重压缩或缩放（DPI/编码不同），hash 就不同——不能凭 hash 不等断言「两张图内容不同」，只能断言字节不同。
- 只适用于内嵌位图（raster）。矢量绘制（vector drawings）没有位图可 hash，需另判（可先看页级 `raster=` / `vector_drawings=` 计数区分两类页）。
- 图与正文/图注的矛盾是另一类问题（图复用不等于结论沿用），需回正文核对。
