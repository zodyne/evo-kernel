---
id: evo-slice-normalize-toolname-case-and-path-field
type: lesson
status: archived
scope: global
domain: tooling
tags: [evo-kernel, evo-slice, claude-code, pi, transcript-parsing, parser, harness]
triggers:
  - "扩展 evo slice 支持新 harness 的会话 transcript（Claude / pi / 其他）"
  - "evo slice 对某 harness 输出的『命令↔结果』对齐为空，或写文件动作整段丢失"
  - "解析 transcript 时假设工具名全小写，或假设路径字段一定叫 path"
  - "给 evo slice 加新 harness 的测试 fixture 后 smoke 报 slice 用例失败"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:fa7187d7-2951-4d30-a0f9-9c30f60229d4
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# evo slice 的每个 harness transcript 解析器，必须各自规整工具名大小写与路径字段别名，不能假设全 harness 一致

## 主张
`evo slice` 按 harness 解析会话 transcript 时，**工具名大小写**和**路径字段名**是 per-harness 的，绝不能写死成某一个 harness 的约定。Claude Code 的工具名是首字母大写（`Bash` / `Write` / `Edit`），路径字段叫 `file_path`；pi 的是全小写（`bash` / `write` / `edit`），路径字段叫 `path`。若解析器只判 `o.name === 'bash'`（小写、pi 约定），Claude 的 transcript 里所有命令/写文件动作都会被整段漏掉，切片出现"命令↔结果对齐为空""写文件动作丢失"。

## 为什么
Claude Code 与 pi 是两个独立 harness，各自的工具命名与字段命名历史不同。`digBlocks` 这类块抽取逻辑如果按单一 harness 的 casing/字段硬编码，换一个 harness 就静默漏块——而 slice 是 Reflector 蒸馏的唯一硬证据来源，漏块等于直接丢证据。修法是两行：工具名比较前统一小写（或显式枚举大小写变体），路径字段同时认 `path` 与 `file_path`。

## 证据（本会话命令 ↔ 结果，切片硬证据）
- 末条 assistant 给出根因：`工具名大小写:Claude 的工具叫 Bash/Write/Edit,代码判的是 o.name === 'bash';附带 Claude 用 file_path 而 pi 用 path`，并指明改在 `bin/evo` 的 `digBlocks` 两行。
- 写/改文件清单含 `bin/evo`、新增 `test/fixtures/sample-session-claude.jsonl`、改 `test/smoke.sh`——即"改实现 + 加 Claude fixture + 加对应 slice smoke 用例"三件套。
- `bash test/smoke.sh 2>&1 | grep -E "slice|PASS=|✗"` → `✓ slice 命令↔结果对齐  ✓ slice Claude 命令↔结果  ✓ slice Claude 写文件  ================ PASS=63 FAIL=0`——新增的两个 Claude slice 用例（命令↔结果、写文件）均绿，回归无破坏。
- `ls test/fixtures/` 显示除既有 `sample-session.jsonl` 外新增了 `sample-session-claude.jsonl`。

## 边界 / 反例
- 本条只主张"工具名 casing 与路径字段名要 per-harness 规整"，不覆盖其他可能的字段差异（如 Claude 的 `tool_use`/`tool_result` 块结构、thinking 块、content block 类型分布）——这些仍需各自核对。
- "统一小写"对纯 ASCII 工具名安全；若未来 harness 工具名含大小写敏感的语义（罕见），应改为显式枚举变体而非盲目 `.toLowerCase()`。
- 修了 casing/字段不等于该 harness 的 slice 100% 正确，仍需用真实会话 jsonl 做 fixture 回归（本会话即用真实 Claude 会话补了 fixture）。

## 失败信号（未来命中即该想起本条）
- 给 evo slice 接新 harness 后，切片里该 harness 的"命令↔结果"段为空或写文件动作缺失。
- 新增 harness fixture 后，smoke 的 slice 用例直接红。
- 解析 transcript 的代码里出现硬编码的 `=== 'bash'` / `.path` 这类单一 harness 约定。
