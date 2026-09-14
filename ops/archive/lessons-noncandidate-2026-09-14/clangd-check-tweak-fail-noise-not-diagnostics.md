---
id: clangd-check-tweak-fail-noise-not-diagnostics
type: lesson
status: deprecated
scope: global
domain: tooling
tags: [clangd, diagnostics, noise, grep, c]
triggers:
  - "clangd --check 报 N errors，但翻输出找不到像样的诊断行"
  - "clangd 输出里出现 tweak: ... ==> FAIL / replacement overlaps 字样的 E[ 行（失败信号）"
  - "写脚本统计 clangd 诊断数，把 tweak/IncludeCleaner 噪音算进去了"
  - "想判断某文件在 clangd 下是否真有编译诊断"
created: 2026-08-10
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019febc9-0500-7400-b95e-bb526bd26016
last_verified: 2026-08-10
superseded_by: skill:nvim-lsp-troubleshooting
schema_version: 1
related: [clangd-check-headless-repro-editor-diagnostics]
---

**主张**：`clangd --check` 输出里 `E[...] tweak: <名字> ==> FAIL: ...`（如 `SwapBinaryOperands ==> FAIL: The new replacement overlaps with an existing replacement`）是 refactor tweak 的内部失败日志，**不是该源文件的诊断**；结尾摘要的 `N errors` 与真实诊断数可能对不上。判"文件是否真有诊断"不要数 E[ 行或只看 errors 计数，要按诊断码模式过滤：`grep -E '\[pp_|\[-W|fatal'`。

**实测**（algommw pipeline.c）：`clangd --check=platform/freertos/pipeline.c | grep '^E\['` 打出的全是 tweak FAIL 行，摘要称 `All checks completed, 6 errors`；改用 `grep -E '\[pp_|\[-W|fatal'` 过滤后零命中——该文件没有真实诊断，6 这个数字来自噪音。

**边界**：tweak FAIL 本身无害（只是某个自动重构动作不适用），但若脚本拿 errors 计数当门禁会误判；真实诊断行带诊断码（`[pp_file_not_found]`、`[-W...]`）或 `fatal` 字样。
