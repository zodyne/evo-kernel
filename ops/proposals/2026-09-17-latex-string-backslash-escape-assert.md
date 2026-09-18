---
id: latex-string-backslash-escape-assert
type: lesson
status: candidate
scope: global
domain: document-processing
tags: [latex, transcription, escaping, backslash, python, json]
triggers:
  - "把公式/LaTeX 命令写成字符串存进 JSON 或 Python 字典，出现反斜杠丢失或解析报错"
  - "转写的 LaTeX 字符串里单个反斜杠没转义，导致字符串坏掉或加载后不对"
  - "JSON 里的 LaTeX 公式加载后反斜杠不对（失败信号）"
  - "批量检查转写的 LaTeX 字符串有没有漏转义的反斜杠"
created: 2026-09-17
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: session:01a0ad4f-ca92-7710-933f-0b52f3bd31a2
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related:
  - formula-region-crop-upscale-before-vision-transcribe
---

# latex-string-backslash-escape-assert

## 一句话主张

把公式转写成 LaTeX 字符串（存进 JSON/Python 字典）时，源码里的反斜杠必须成对写成 `\\`；
用断言 `assert '\\' not in l.replace('\\\\', '')` 批量检查有没有「落单」的反斜杠（漏转义），
把「含落单反斜杠 = 坏字符串」变成可定位的失败信号。

## 为什么

公式 LaTeX 满屏 `\frac`、`\sqrt`、`\sum` 这类带反斜杠的命令，转写进 Python 字符串/JSON 时
漏转义的反斜杠会被当作转义符吃掉或解析错，且坏在哪一条不易定位。
该断言先把成对的 `\\` 替换掉，再检查剩余的单个 `\`——剩一个就说明有漏转义。
会话内跑这个断言直接触发 Traceback，坐实 chunk01.json 里确有落单反斜杠。

## 边界

这是**字符串转义层**（Python/JSON 存储）的坑，与 LaTeX 语法无关；
真正的 LaTeX 语法错误要靠 xelatex 编译门去抓（见 scanned-book-formula-latex-compile-validation）。
断言只查「有没有落单反斜杠」，不查公式语义/内容对错。

## 证据

命令：python3 读 chunk01.json 后逐条执行 `assert '\\' not in l.replace('\\\\', '')`，
结果触发 `Traceback ... assert '\\' not in l.replace('\\\\', '')`（失败信号，证明存在漏转义的落单反斜杠）；
修复后后续 `42 equations exit=0` 编译通过，反证该断言定位的正是转义问题。
