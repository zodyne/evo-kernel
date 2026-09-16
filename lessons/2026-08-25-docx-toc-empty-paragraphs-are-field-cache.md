---
id: docx-toc-empty-paragraphs-are-field-cache
type: lesson
status: candidate
scope: global
domain: docx
tags: [python-docx, ooxml, toc, field, document-review, false-negative]
triggers:
  - "用 python-docx 审阅/校对带目录的 Word 报告"
  - "遍历段落发现目录区全是空文本段落（失败信号：误判『目录被删/没有目录』）"
  - "要核对 docx 目录覆盖到几级标题（TOC \\o 开关）"
  - "改完标题文字后要判断目录是否会同步"
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e9b77b86-b6b5-441e-a133-e72516849e75
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
---
# docx 目录读出来是一串空段落，不等于文档没目录

## 主张
python-docx 遍历段落时，`toc 1 / toc 2` 样式的目录条目 `paragraph.text` 可能**全为空**——目录是 TOC 域（field），
条目文本属于域缓存结果，段落文本层看不到。
判断"有没有目录、覆盖几级"要去读域指令：本次读到 `TOC \o "1-3" \h \z \u` 与逐条 `HYPERLINK \l _TocNNNNN  PAGEREF _TocNNNNN \h`，
证明目录存在且配置为 1–3 级；空文本只说明缓存没内容。

## 为什么
文档审校任务里，"段落文本为空"极易被当成内容缺失并写进审查意见（假阴性）。
域结构与域缓存是两层东西：域在、缓存空，是 Word 未刷新/未渲染的常见状态，不是文档缺陷。
把这两层混为一谈，会给出错误的整改要求。

## 证据（本会话命令对照）
- dump 评估报告段落：`P1 [标准文件_目录]: '目 录'`，随后 `P2 [toc 1]: (EMPTY TOC LINE)`、`P3 [toc 1]: (EMPTY TOC LINE)`、`P4 [toc 2]: (EMPTY TOC LINE)` …（连续多条空目录行）。
- 同一文件抽域指令（lxml.etree + w: 命名空间）：`FIELD-INSTR: TOC \o "1-3" \h \z \u`，后接多条 `FIELD-INSTR: HYPERLINK \l _Toc31693  PAGEREF _Toc31693 \h`。
- 两组输出同时成立 → 目录域存在、层级 1–3 级；段落文本空只是缓存态。

## 边界 / 反例
- 本会话只观察到"域指令存在 + 段落文本为空"这一状态，**没有做**"用 Word 打开刷新后缓存是否填充"的实验，
  所以不要据本条断言"打开就一定正常显示"。
- 反向也成立：有些 docx 的目录是被人手打成普通段落的死文本（无域），那时段落文本非空但改标题不会同步——判断前先看有没有 TOC 域指令。

## 失败信号（未来命中即该想起本条）
- 段落遍历里出现连续空段落且样式名是 `toc N` → 去查域指令，别写"缺目录"。
