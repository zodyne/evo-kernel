---
id: macos-bsd-cat-no-dash-a
type: lesson
status: candidate
scope: global
domain: shell
tags: [macos, bsd, gnu, cat, invisible-chars, shell]
triggers:
  - "macOS 上想查看文件名/文本里的不可见字符（空格、tab、特殊 Unicode）"
  - "cat -A 报 cat: illegal option -- A（失败信号）"
  - "从 Linux 习惯照搬 cat -A / cat --show-all 到 macOS"
  - "怀疑目录名带尾随空格或全角字符，要 dump 原始字节确认"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fab8d-651f-7df8-8d1d-29c7d2f71bce
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [macos-no-timeout-command]
---

**主张**：macOS 自带的是 BSD `cat`，**没有 GNU 的 `-A`（`--show-all`）选项**。要检查文件名/文本中的不可见字符，用 `cat -etv`（BSD 等价：行尾 `$`、tab 显形、非打印字符转义）或直接 `ls | od -c` dump 原始字节。

**证据**：会话中怀疑暗室数据目录名有异常字符，执行 `ls "20260508暗室角度采集/俯仰角/" | cat -A | head -25`，立即报 `cat: illegal option -- A` + `usage: cat [-belnstuv] [file ...]`——usage 行列出的合法选项证实了 BSD 全集（无 -A）。

**边界**：BSD `cat` 的 `-e` 等价 GNU `-E`（行尾显形）、`-t` 等价 `-T`（tab 显形）、`-v` 显形非打印字符；`-etv` 组合即 GNU `-A` 的效果。若处理的是含多字节 UTF-8 的中文目录名，`od -c` 按字节 dump 更可靠。
