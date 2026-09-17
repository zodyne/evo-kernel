---
id: backtick-in-double-quoted-grep-pattern-breaks-shell
type: lesson
status: validated
scope: global
domain: shell
tags: [shell, grep, quoting, markdown]
triggers:
  - "用 grep/sed 过滤含反引号的文本（markdown 代码围栏 ``` 或行内 `code`）"
  - "grep pattern 用双引号包裹后报 unexpected EOF while looking for matching backtick"
  - "命令行报 syntax error: unexpected end，且 pattern 里含反引号"
  - "写 shell 过滤 markdown 代码块时 pattern 该用单引号还是双引号"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0adf4-ceb2-74bd-bb26-429decdd2fa3
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [2026-07-27-zsh-unquoted-glob-arg-no-matches]
---

用 grep/sed 的 pattern 过滤含反引号的文本时，pattern 若用**双引号**包裹，shell 会把反引号解析成命令替换，报 `unexpected EOF while looking for matching `` ` ``；含反引号的 pattern 应改用**单引号**包裹。

为什么：双引号内反引号仍触发命令替换（双引号只屏蔽空格分词和 glob，不屏蔽 `$`/`` ` ``）。本会话实测命令
`grep -v "^  \|^```\|^%\s*=="` 想过滤 markdown 代码围栏（三个反引号），结果报
`/bin/bash: -c: unexpected EOF while looking for matching `` ` `` + syntax error: unexpected end`；
把 pattern 换成单引号 `'^  \|^```\|^%\s*=='` 即解。

反例/边界：不含反引号的 pattern 用双引号没问题（正则里的 `\s`、`\|` 无需单引号保护）；只有 pattern 里出现反引号才会踩坑。单引号内不能再直接写单引号，若 pattern 本身含 `'` 需用 `'\''` 拼接或改 heredoc。

证据：session 切片命令↔结果第 6 条，命令含 `^``` ` 双引号 pattern，结果为 shell 语法错误。
