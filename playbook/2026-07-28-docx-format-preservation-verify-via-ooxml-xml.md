---
id: docx-format-preservation-verify-via-ooxml-xml
type: lesson
status: validated
scope: global
domain: docx
tags: [docx, ooxml, python-docx, format-preservation, verification, zipfile]
triggers:
  - "改 .docx 内容但要求保留原文件格式（字体/字号/表格框线/段落样式）"
  - "验证 docx 编辑后格式是否真的没变，纯文本或肉眼对比不可靠"
  - "用 python-docx 改完 docx，需要硬证据确认格式逐项保留"
  - "确认 docx 里某章节/表格改完和原文档逐字节一致"
  - "docx 内容更新任务，担心格式转换/LibreOffice 往返丢失原排版（失败信号）"
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:b4705404-11d9-41aa-89ed-740c2fedfb2b
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
---
# 验证 docx「改内容保格式」要落到 OOXML 的 XML / run 属性级，不能只看纯文本或渲染

## 主张
.docx 本质是 OOXML 的 zip 包，**格式信息（字体/字号/加粗/表格框线/段落样式）全在 `word/document.xml` 的标签和 run 属性里，纯文本里完全没有**。所以"改内容保格式"任务的验证必须落到 XML / run 层，用两套互补手段：(a) 用 python-docx 逐 run dump 出字体/字号/粗体等属性；(b) 把 docx 当 zip 解开，按章节/段落对 `word/document.xml` 做字节级 diff——未改动的章节 XML 必须逐字节一致（这是 ground truth）。只对比纯文本 dump 或肉眼开文件看，无法发现格式被悄悄改掉。

## 为什么
- docx = zip(OOXML)。`unzip` 后 `word/document.xml`（正文+内联格式）与 `word/styles.xml`（命名样式）是格式的全部来源；文本只是标签之间的字符数据。
- python-docx 的 `paragraph.runs[*]` 能拿到 run 级 `font.name / font.size / font.bold`，dump 成 `[P0]<Normal> runs=[宋体,asc=宋体,14.0pt,B]` 这种行，可逐段核对格式元数据是否还在。
- 但 run 属性 dump 仍可能漏（比如表格 `tblStyle=Table Grid` 框线、`tblW` 列宽这类结构属性不在 run 上），所以未改动章节还要用原始 `word/document.xml` 字节级对比兜底：XML 完全一致 → 格式一定没动。

## 证据（本会话命令对照）
- `unzip -o -q "<原.docx>"` → 解出 `word/document.xml`(44574B) / `word/styles.xml`(349594B)，证明 docx 即 zip，格式在 XML 里。
- `python3 dump.py`（python-docx）→ 输出 `[P0]<Normal> [CENTER (1)] runs=[宋体,asc=宋体,14.0pt,B] :: 湖南纳雷科技有限公司`，证明 run 级字体/字号/粗体可逐段 dump 核对。
- `python3 -c "import zipfile; ..."` 按章节切段对比 → `第五章 XML 完全一致: True | 长度 12202 12202`，证明未改动章节可做字节级一致性验证。
- 末条 assistant 据此逐项核验通过：封面 18pt 宋体加粗标题、10.5pt 正文、9pt 表格字号、`Table Grid` 框线样式均保留。

## 边界 / 反例
- 本会话只验证了"未改动章节 XML 字节一致"和"run 属性 dump"两套手段有效；**改动过的章节无法用字节 diff**（内容变了 XML 必然不同），那部分只能靠 run 属性 dump + 人审。
- 若用 LibreOffice/Word 往返转换（docx→docx 或跨格式）来"保格式"，转换器会重写 XML，字节 diff 会全段不一致——此时字节 diff 失去意义，只能回到 run 属性级对比。
- 本会话未实测 `textutil`（macOS 自带）能否处理 .docx；它主要面向旧格式，docx 任务实际走的是 python-docx + 直接操作 XML，未依赖任何格式转换器。

## 失败信号（未来命中即该想起本条）
- 改完 docx 只用纯文本 diff 或打开看一眼就交付，后来发现字体/字号/框线被改了。
- 用 python-docx 改内容后，不确定原格式（尤其表格样式、命名样式）有没有被库默认值覆盖。
- 想"证明"格式没变但只能给视觉截图，拿不出 XML/run 级的硬证据。
