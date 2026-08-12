---
id: transcript-parser-normalize-tool-names
type: lesson
status: candidate
scope: global
domain: transcript-parsing
tags: [transcript, parser, claude-code, cross-harness]
triggers:
  - "解析 Claude Code 会话 jsonl 提取为 0"
  - "跨 harness 解析 transcript"
  - "tool_use 提取不到命令"
  - "Claude 和 pi 会话格式对齐"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:fa7187d7
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---

**主张**：写跨 harness（Claude Code / pi）的 transcript 解析器时，工具名要 `toLowerCase()` 后再比较、字段名要兼容两套：Claude 的工具名首字母大写（`Bash`/`Write`/`Edit`），pi 全小写；Claude 文件参数叫 `file_path`，pi 叫 `path`。不做这层归一化，Claude 会话提取结果就是 0 条——而且是静默的 0。

**为什么**：`evo slice` 判 `o.name === 'bash'`，985KB 的 pi 会话能提取 72 条命令↔结果，874KB 的 Claude 会话 0 条，只 fallback 出首 user/末 assistant。静默空输出比报错更危险——下游会拿「凭记忆写经验」冒充蒸馏。

**边界**：Claude 结构是 `message.content[].type=tool_use/tool_result`；修完要用真实会话回归（改前 0 条 → 改后有提取），并保留原 harness 的既有测试防回归。

**证据**：2026-07-27 agent-evo 会话修复 `bin/evo` digBlocks，smoke 63 PASS，真实 Claude transcript 验证通过。
