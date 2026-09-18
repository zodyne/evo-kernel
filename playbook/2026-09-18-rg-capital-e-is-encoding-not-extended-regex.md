---
id: rg-capital-e-is-encoding-not-extended-regex
type: lesson
status: validated
scope: global
domain: tooling
tags: [ripgrep, rg, cli, flags, grep-migration]
triggers:
  - "写 rg 命令时按 grep 习惯带上 -E（扩展正则）"
  - "rg 报 error parsing flag -E: grep config error: unknown encoding: <你的正则>（失败信号）"
  - "从 grep 迁移到 ripgrep，不确定哪些 flag 同名不同义"
  - "rg 命令零命中并报编码错误，第一反应怀疑模式本身写错"
  - "要显式区分模式参数与文件参数（模式以 - 开头，或要同时传 -F/-e）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e662-725c-a75a-f9843c02cafa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

主张：ripgrep 的 `-E` 是 `--encoding`（声明输入文件编码），**不是 grep 的扩展正则开关**。
`rg -E '<正则>'` 会把 `<正则>` 当编码名整条吃掉，命令以
`rg: error parsing flag -E: grep config error: unknown encoding: <你的正则>` 终止（exit 2），**一个命中都不产出**。
ripgrep 的模式默认就是正则，无需开关：显式给模式用 `-e '<pat>'`，纯字面量用 `-F`。

**为什么**：来自 `grep -E` 的肌肉记忆；同名短选项在两套 CLI 里语义完全不同。
"unknown encoding" 后面跟着你刚写的正则，是这个坑的最强指纹——错误里那个"编码名"就是你的模式。

**证据（本会话命令 ↔ 结果，同一模式改 flag 后 before/after）**：
- `cd /Users/zodyne/.pi/agent/sessions && echo "=== nvim.NNN socket ===" && rg -l --no-messages -E 'nvim\.[0-9]+\.0' -g '*.jsonl' . | sort`
  → `=== nvim.NNN socket === rg: error parsing flag -E: grep config error: unknown encoding: nvim\.[0-9]+\.0`（无任何搜索结果）。
- 去掉 `-E` 后同一正则照常工作：`rg -l --no-messages 'nvim\.[0-9]+\.0' -g '*.jsonl' . | sort`
  → `./--Users-zodyne--/2026-09-14T08-48-49-247Z_01a09f1a-ce5f-74d6-aeb7-1ea49cc22f12.jsonl …`（命中正常列出）。
- 本机复验（ripgrep 15.2.0，2026-09-18）：`rg -E 'foo' /dev/null` → `rg: error parsing flag -E: grep config error: unknown encoding: foo`，exit 2；
  `rg --help` 里只有 `-E ENCODING, --encoding=ENCODING`，没有扩展正则语义。

**边界/反例**：真正要读非 UTF-8 文件时 `-E gbk` 是正当用法（本条不主张"永远别用 -E"）；
判据是**报错里的 encoding 名是不是你自己的正则**。另外，只有当模式本身以 `-` 开头时才有必要写 `-e`/`--`，
平时直接 `rg '<pat>'` 就够。未在其他 rg 版本（<14）上复验，但 `-E`＝`--encoding` 是 ripgrep 的既有长期语义。

**失败信号（未来命中即该想起本条）**：命令报 `unknown encoding:` 而你没有故意选编码；或迁移期"grep 能跑、rg 报错"。
