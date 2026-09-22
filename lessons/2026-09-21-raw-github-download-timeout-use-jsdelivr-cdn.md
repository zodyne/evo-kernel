---
id: raw-github-download-timeout-use-jsdelivr-cdn
type: playbook
status: candidate
scope: global
domain: web-scraping
tags: [curl, raw-githubusercontent, jsdelivr, cdn, timeout, fetch]
triggers:
  - "curl 从 raw.githubusercontent.com 拉源码/文档超时（失败信号：curl: (28) Operation timed out after N ms with X out of Y bytes received）"
  - "同一个 raw URL 重试、或加大 --max-time 后仍拿不全，甚至 0 字节"
  - "要按 ref/分支抓 GitHub 上的单个文件（含 feature 分支的 etc/NEWS 之类）做 grep 分析"
  - "弱网或代理环境下批量抓 raw.githubusercontent.com 文件，正在写重试循环"
  - "已经只拿到半截内容，纠结继续等同一个源还是换源"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bf4c-dbdb-75a1-a035-327aea85cb14
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [curl-max-time-timeout-empty-looks-like-no-match, curl-o-code-000-no-output-file, arxiv-download-proxy-truncation]
---

# raw.githubusercontent.com 超时拉不全时，换 cdn.jsdelivr.net/gh/<owner>/<repo>@<ref>/<path> 能拿到同一文件

**主张**：`curl` 从 `raw.githubusercontent.com` 拉单个文件时可能中途超时（exit 28、只收到部分字节），
此时不要在同 URL 上继续重试或单纯加大 `--max-time`——把同一条路径改写成 jsDelivr 的 GitHub 镜像
`https://cdn.jsdelivr.net/gh/<owner>/<repo>@<ref>/<path>` 往往能一次拿全，且 `@<ref>` 支持 feature 分支，
不只 tag/release。抓完先用 `wc`/`ls` 确认文件完整，再做 grep。

**为什么**：raw.githubusercontent.com 与 jsDelivr 是同一 GitHub 仓库内容的两条不同 CDN 链路，
单条链路超时不代表文件不可得。本会话里 raw 链路在 150s 内只收到 6429/12440 bytes 就报错退出
（`&& wc -l` 因此根本没执行到），换 jsDelivr 后同一路径的 fetch 直接完成，后续能正常读到 NEWS 正文。

**证据**（本会话切片，命令 ↔ 结果）：
- 失败：`curl -sS -L --max-time 150 "https://raw.githubusercontent.com/emacs-mirror/emacs/feature/igc3/etc/NEWS" -o NEWSigc.txt && wc -l NEWSigc.txt`
  → `curl: (28) Operation timed out after 150004 milliseconds with 6429 out of 12440 bytes received`，`FETCH FAILED`。
- 成功：`curl -sS -L --max-time 120 "https://cdn.jsdelivr.net/gh/emacs-mirror/emacs@feature/igc3/etc/NEWS" -o NEWSigc2.txt ...`
  → `=== feature/igc3 NEWS via jsdelivr ===    12440 NEWSigc2.txt`，并输出可读内容
  （`237- 238-+++ 239-** The transition variable 'current-time-l...`）。

**边界 / 反例**：
- 本会话只对 1 个文件做了 raw→jsDelivr 的对照，不能推广为「raw 超时一定是链路问题」或「jsDelivr 永远可用/无限额」。
- jsDelivr 的成功只证明该 ref 下的文件可被它取到，不代表私有仓库/未公开 ref 也走这条通道。
- 若内容本身是动态生成（非仓库文件），此镜像不适用。
