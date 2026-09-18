---
id: curl-o-code-000-no-output-file
type: lesson
status: validated
scope: global
domain: shell-scripting
tags: [curl, download, silent-failure, http_code, jina]
triggers:
  - "用 curl -o 下载内容后立刻 grep/sed 解析，报 No such file or directory"
  - "经 r.jina.ai / reader 代理抓付费墙全文，curl 返回 code=000 且 -o 输出文件不存在"
  - "写『下载-解析』脚本，网络失败被伪装成文件缺失"
  - "curl 连接失败 code=000 时不落盘输出文件，解析前要先校验 http_code 与文件存在"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a55a-7277-777c-a410-3256578ab619
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [arxiv-download-proxy-truncation]
---

# curl -o 连接失败（code=000）不写输出文件，解析前必须校验 http_code 与文件存在

## 主张

用 `curl -o <file>` 下载内容并随后解析时，连接失败（`-w "%{http_code}"` 返回 `000`）不会创建输出文件；写「下载 → 解析」脚本必须先检查 http_code 和文件存在性再进入解析，否则下游 `grep`/`sed` 报 `No such file or directory`，把真实的网络失败伪装成文件缺失。

## 为什么

`code=000` 是 curl 未收到任何响应的统一出口（DNS 失败 / 连接拒绝 / 超时 / reader 代理拉取目标页失败都会落到它），此时 `-o` 目标文件不落盘。若脚本拿到 http_code 后仍无脑去 grep 该文件，报错信息停在「文件不存在」，既掩盖了「网络/代理挂了」这个真实根因，也浪费一轮定位。一次 `-w` 取值 + 一个 `[ -s file ]` 判断就把失败从假文件错误改判成真网络错误。

## 边界

- 本条目讲「code=000 不落盘」；「下载成功但内容被截断/损坏」是另一类（见 related: arxiv-download-proxy-truncation），判据不同（前者文件不存在，后者文件存在但缺页/缺字节）。
- r.jina.ai 这类 reader 代理对目标站超时或目标站反爬时，容易整体返回 000，属于高频触发点而非偶发。

## 证据（命令 ↔ 结果，本会话切片）

- `code=$(curl -s -m 60 -o /tmp/jina.txt -w "%{http_code}" "https://r.jina.ai/https://ietresearch.onlinelibrary.wiley.com/doi/full/10.1049/rsn2.12063"); grep ... /tmp/jina.txt` → 输出 `✗ /bin/bash: /tmp/jina.txt: No such file or directory jina code=000 bytes=`，即 http_code=000 且 `/tmp/jina.txt` 未被创建，后续 grep 报 No such file。
