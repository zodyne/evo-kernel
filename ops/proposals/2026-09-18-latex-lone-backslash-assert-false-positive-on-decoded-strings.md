---
id: latex-lone-backslash-assert-false-positive-on-decoded-strings
type: lesson
status: candidate
scope: global
domain: document-processing
tags: [latex, escaping, json, python, assertion, false-positive, transcription]
triggers:
  - "用『把成对反斜杠替换掉后不应再有单个反斜杠』的断言检查 LaTeX 字符串有没有漏转义"
  - "json.load 读进来的 LaTeX 公式被这类断言判为坏字符串（失败信号：合法公式也全红）"
  - "给转写 JSON / Python 字典里的 LaTeX 加批量转义检查，犹豫该在原始文本层还是解码后的对象层做"
  - "把 Python 源码里的 LaTeX 字面量（合法转义）拿去做『无单反斜杠』自检，断言照样触发（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-5266-73b1-bdd8-c2d0c6a8eec4
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [latex-string-backslash-escape-assert, transcription-json-balanced-escape-gate]
---

# 「无落单反斜杠」断言在解码后的字符串层是恒红的伪判据

**一句话主张**：用 `assert '\\' not in s.replace('\\\\','')` 这类「成对反斜杠替换掉后不应再有单个反斜杠」
的断言检查 LaTeX 转义，**只在 JSON 原始文本（未解码）层有效**；对 `json.load` 之后或源码字面量得到的
Python 字符串，合法 LaTeX 本身就是单反斜杠，断言必然触发——实测 `l = "$$\\frac{a}{b}$$"` 就把它踩响。

**为什么**：Python 源码里的 `"$$\\frac{a}{b}$$"` 解出来是 `$$\frac{a}{b}$$`（每个 `\\` 变回一个反斜杠），
而 `'\\\\'` 表示的是「两个反斜杠」这个两字符串——对只有单反斜杠的已解码字符串 `replace` 不删任何东西，
于是剩下的单反斜杠让断言必失败。在 JSON **原文**里，合法转义写作两个反斜杠字符，才会被这次 replace 吃掉，
判据在那里才有区分力。换句话说：解码层把「转义是否合法」这条信息已经消费掉了，事后再查必然是假阳性。

**证据**（命令↔结果，会话 01a0b2ce）：
命令 `python3 - <<'PYEOF'` … `l = "$$\\frac{a}{b}$$"` … `assert '\\' not in l.replace('\\\\','')` …；
结果 `↳ '$$\\frac{a}{b}$$' assertion triggered (lone backslash) x repr '\\frac{1}{2}' lone? True`
——合法 LaTeX 字符串被判为「有落单反斜杠」，断言触发。

**边界**：本条不否定在 JSON 原始文本层做转义检查，只界定「解码后的对象层不能用这条判据」；
要证明转写 JSON 的转义/结构完整，走 `json.load` 全量解析这道结构门 + 键集合/花括号配平（见 related）。
