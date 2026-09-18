---
id: rg-literal-marker-needs-f-flag
type: lesson
status: validated
scope: global
domain: shell
tags: [ripgrep, regex, literal-search, log-search, parse-error]
triggers:
  - "用 rg/grep 搜日志或文档里原样复制来的片段（含括号、竖线等）"
  - "rg 报 regex parse error: … unopened group（失败信号）"
  - "想确认某段文字是否在文件里出现过"
  - "把报错信息/输出里的片段直接当搜索模式，结果一条都不返回"
  - "搜索命中数与肉眼预期不符，怀疑模式被当正则解释了"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e572-725c-a75a-f97ded032a7c
last_verified: 2026-09-18
superseded_by: null
related: [grep-alternation-count-cannot-prove-single-pattern-present]
---
搜日志/文本里的**原样片段**（从输出里复制来的标记，常带 `)`、`(`）直接用 `rg '<片段>'` 会被先当正则解析：括号不成对时 `rg` 报 `regex parse error: … unopened group` 并且一条都不返回；要按字面检索必须加 `-F`（fixed-strings）。
**为什么**：`rg` 默认开启正则，模式会被包进 `(?: … )` 再编译，片段里原本用来编号的 `)` 就成了多余的右括号而编译失败。日志里的分段标题（`1) 真实配置能否加载`、`2) 免疫验证` 这类）是最常见的中招来源。
**做法**：只做"这段文字有没有出现过"的检索一律 `rg -F`；只有确实需要正则语义（字符类、交替、量词）时才去掉 `-F`。`-F` 可与 `-n` / `-A` / `-B` 同用，不影响上下文展示。
**边界**：本例只验证了括号触发的**硬报错**。若片段里的元字符（`.` `|` `*` 等）单独看仍是合法正则，不会报错而是**静默按正则语义匹配**——此时"搜到了"也不能证明原样文本存在，同样要 `-F`。
**证据**：切片命令 `rg -n -A 22 '1) 真实配置能否加载' /tmp/zres.txt | cut …` → `rg: regex parse error: (?:1) 真实配置能否加载) ^ error: unopened group`（同一批的第二条 `rg -n -A 20 '2) 免疫验证'` 同样报错、无命中）；同一命令加 `-F` 重跑即命中：`rg -n -F -A 22 '1) 真实配置能否加载' /tmp/zres.txt` → `4273:=== 1) 真实配置能否加载 + no_files 钩子是否生效 === …`。
