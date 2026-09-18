---
id: rg-o-window-search-in-jsonl-transcripts
type: lesson
status: candidate
scope: global
domain: forensics
tags: [rg, ripgrep, jsonl, transcript, context, pi]
triggers:
  - "在 pi/Claude 会话 jsonl（一条记录一行）里搜关键词，想看命中处的前后文"
  - "用 rg -A/-B/-C 搜 jsonl 后输出被整条记录淹没、刷屏还看不出上下文（失败信号）"
  - "要从会话转录里摘一段原文当证据（引文核对、溯源、审计）"
  - "对 minified JSON / 单行超长的日志做跨行上下文检索"
  - "需要在几百个会话文件里反复搜同一个关键词，要求每次输出体量可控"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7af-25c7-725c-a75a-f990cf4e0e58
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pi-jsonl-toolresult-toolcallid-pairing, pi-transcript-tool-args-encoding-is-per-tool]
---

# 在会话 jsonl 里搜关键词要用 `rg -o '.{N}<pattern>.{M}'` 裁定长上下文，别用行级上下文

**主张**：会话 jsonl 是 NDJSON——**一条记录就是一行**，而单行可以几 KB（含完整 content 块、长命令、长输出）。在这类文件里找关键词的上下文，用 `rg -o` 把命中裁成定长窗口：`rg -o '.{60}api-info.{60}'`（前文 N 字 + 命中 + 后文 M 字），只想要前文就用 `.{0,120}`；不要用 `-A/-B/-C` 的行级上下文。

**为什么**：行级上下文在 NDJSON 上的语义是"把整条记录倒出来"，一个命中就是几 KB 的 JSON，多个命中直接把上下文预算烧光；`-o` 只输出**匹配到的那段文本**，窗口长度由正则写死，所以每次命中的输出体量可预期，还能把多次命中并排比较。

**证据（本会话命令 ↔ 结果，全库取证时成对使用 `echo "=== … ===" ; rg -o …`）**：
- `rg -o '.{60}api-info.{60}' --glob '*.jsonl' …` → `=== api-info actual command context ===` 后直接给出 `api-info` 前后各 60 字（命中窗口即输出行）。
- `rg -o '.{0,120}guest\.lua:[0-9' …` → `…zy/flatten.nvim/lua/flatten/rpc.lua:36: in function 'exec_on_host'\n\t...local/share/nvim/lazy/flatten.nvim/lua/flatten/`（从 Lua 栈帧里裁出定位所需的那一小段）。
- `rg -o '.{150}[Ff]latten.{250}' …` → 命中窗口的前 150 字前文可见（证明窗口按预期裁出，同时暴露了一个无关命中）。
- 规模背景：同批取证里有 380 KB / 457 KB / 1.9 MB 的会话 jsonl，以及 27 行的 34 KB 文件——即单行体量与记录数完全不成比例。

**边界 / 反例**：
- 窗口是**定长**的，会切断语义边界：本会话多个窗口只截到半句（切片自身在 120/250 字处再次截断）。要完整句子/整条记录时，补一次 `sed -n '<行>p'` / jq 整条抽取。
- "行级上下文不可用"是**从 NDJSON 行长推出的机制性理由**，本会话**没有**跑 `rg -C` 做对照实验，别把它当成实测对比。
- 要的是计数、字段、配对关系时改用 jq（见 related 的 `pi-jsonl-toolresult-toolcallid-pairing` / `pi-transcript-tool-args-encoding-is-per-tool`），`rg -c` 数不出"调用是否成对"。
- 命中文本可能是**别处引用**而非真的执行/存在（见 related 的 `subagent-transcript-exec-vs-mention`）；`-o` 只解决"看得清"，不解决"是不是它干的"。

**失败信号（未来命中即该想起本条）**：搜完 jsonl 屏幕上是一坨 JSON 而你要的上下文还得再去读一遍；或为了看上下文把 `-C` 开大到 5 结果输出几十万字符。
