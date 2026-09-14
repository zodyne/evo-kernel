---
id: docx-oxml-xpath-not-lxml-native
type: lesson
status: candidate
scope: global
domain: docx
tags: [python-docx, lxml, ooxml, xpath, namespaces, api-mismatch]
triggers:
  - "用 python-docx 下潜到 OOXML 层读 w:fldChar / w:instrText / w:numPr 等节点"
  - "报 TypeError: BaseOxmlElement.xpath()（失败信号）"
  - "想按 lxml 习惯给 element.xpath 传 namespaces= 或自定义命名空间前缀"
  - "python-docx 高层 API 读不到的 docx 内容，要自己写 XPath 去取"
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e9b77b86-b6b5-441e-a133-e72516849e75
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
---
# python-docx 元素的 .xpath() 不是 lxml 原生 xpath，自定义命名空间要绕回 lxml.etree

## 主张
`python-docx` 的 oxml 元素方法 `BaseOxmlElement.xpath()` 与 lxml 原生 `Element.xpath()` **签名不兼容**，
按 lxml 习惯调用会直接抛 `TypeError: BaseOxmlElement.xpath()`。
要做带自定义命名空间的查询，改成 `from lxml import etree` + 自建 `NS = {'w': 'http://schemas.openxmlformats.org/...'}` 走原生 lxml 路线，同一查询一次跑通。

## 为什么
python-docx 在 oxml 层包了一套自带 nsmap 的便捷 `xpath`，牺牲了原生签名。
这类"看着像 lxml、其实是包装层"的 API 最容易踩：报错是 `TypeError` 而不是 XPath 语法/命名空间错误，
容易被误读成"XPath 写错了"，进而去改表达式而不是换调用路径。

## 证据（本会话命令对照）
- 脚本 A（从评估报告抽 TOC 域指令与缓存结果，`import re, zipfile` + `from docx ...`）：
  `Traceback ... File "<stdin>", line 13, in <module> TypeError: BaseOxmlElement.xpath()`，exit code 1。
- 脚本 B（同一目标，改用 `from docx import Document` + `from lxml import etree` + `NS = {'w': 'http://schemas.openxmlformats.org/wo...'}`）：
  一次成功，输出 `FIELD-INSTR: TOC \o "1-3" \h \z \u`、`FIELD-INSTR: HYPERLINK \l _Toc31693  PAGEREF _Toc31693 \h`。

## 边界 / 反例
- 切片只捕获到 `TypeError` 首行，**未记录**被拒的具体关键字参数名；可确定的是"同一 XPath 目标改走 lxml.etree 即成功"，
  而不是"XPath 表达式本身有问题"。想精确定位参数需再复现一次。
- 只用 `w:` 前缀、不需要额外命名空间时，python-docx 自带的 `element.xpath('.//w:t')` 是可用的——本条针对的是需要自定义 nsmap 的场景。

## 失败信号（未来命中即该想起本条）
- `TypeError: BaseOxmlElement.xpath()` → 别改 XPath，换 lxml.etree。
