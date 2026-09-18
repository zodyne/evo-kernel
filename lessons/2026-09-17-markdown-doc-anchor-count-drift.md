---
id: markdown-doc-anchor-count-drift
type: lesson
status: candidate
scope: global
domain: documentation
tags: [markdown, docs, drift, line-number, anchor, sync, stale]
triggers:
  - "代码改了几轮后，流程/导航文档里写的 `文件:行号` 引用对不上源码"
  - "文档里硬编码的数字（参数个数/帧数/条目数）与实际代码对不上"
  - "要同步一份含行号引用或硬编码计数的 markdown 流程文档"
  - "接手后怀疑文档描述的仍是旧状态（单板→双板这类定性词没更新）"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a2fa-50a4-75b4-998b-45eb62b3fbfb
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [nav-doc-pinned-head-goes-stale]
---

流程/导航 markdown 文档里手写的 `文件:行号` 引用（如 `pipeline.py:47-62`）与硬编码计数（"37 项"）、定性词（"单板"）会随代码演进漂移；同步这类文档时不能只改正文，要写小脚本批量校验锚点是否越界、是否仍指向正确符号、是否遗留过时表述。

为什么：肉眼能看出正文描述过时，但看不出几十处行号引用里哪些已经越界或指错符号。本次会话把 `view_tracks_3d_flow.md` 从 589 行同步到 771 行（+381/−200）、`COMPASS.md` +103/−25 才对齐真实状态，说明漂移是实质性的。

反例/边界：与 `nav-doc-pinned-head-goes-stale` 是不同机制——那里漂移的是导航文档里的 HEAD 提交指针（commit hash），这里漂移的是行号锚点 + 硬编码计数 + 定性词。校验手段也不同：前者对 `git rev-parse HEAD`，后者要脚本扫引用边界 + 扫遗留表述。

证据：会话内脚本输出"越界引用: 无"、围栏数校验（20 偶）、遗留过时表述扫描命中"549:三条纪律:"；commit `c55fdff`/`14c21ee` 的 diff 统计（flow doc +381/−200、COMPASS +103/−25）证实漂移幅度。
