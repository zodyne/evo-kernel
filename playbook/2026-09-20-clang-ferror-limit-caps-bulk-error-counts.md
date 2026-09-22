---
id: clang-ferror-limit-caps-bulk-error-counts
type: lesson
status: validated
scope: global
domain: build-system
tags: [clang, ferror-limit, error-count, bulk-edit, diagnostics]
triggers:
  - "批量改完 C/C++ 源码后用 grep -c 'error:' / rg -c 'error:' 统计构建日志，准备把数字写进影响面或报告"
  - "构建日志末尾出现 fatal error: too many errors emitted, stopping now [-ferror-limit=]（失败信号：报错被截断）"
  - "同一批改动在两轮复核里报出的错误数不一致（本会话同一批二义错误 136 处被更正为 176 处）"
  - "要声明一次全树改写的真实编译影响面（哪些 TU、多少处），需要可信总数而不是截断值"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4a3-ae96-7475-af70-36ad39adaba4
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [uniform-compile-error-count-input-file-missing]
---

**主张**：clang 对单个 TU 的报错有上限，达到上限后日志以 `fatal error: too many errors emitted, stopping now [-ferror-limit=]` 结束。此时用 `grep -c 'error:'` / `rg -c 'error:'` 数出来的错误数是**截断后的下限**，不能当作影响面总数写进报告或据此做范围决策。需要可信总数时用 `-ferror-limit=0` 重跑，或逐 TU 单独调用编译器统计。

**为什么**：批量脚本改写（命名、类型、转换）一次动几十上百个文件时，构建日志里的 `error:` 行数是最顺手的量化指标；但 clang 默认在单个 TU 的错误上限处停止后续诊断，日志只保留前缀。计数脚本无法区分「只有 20 个错」和「错到被截断」。

**证据（本会话切片，命令 ↔ 结果）**：

- 多次构建日志以固定计数 + 截断行结尾：`err=20 fatal error: too many errors emitted, stopping now [-ferror-limit=]`（如 io/profile.cpp:242、tools/parity/decoder.cpp:101/103/111），另有 `err=31 fatal error: too many errors emitted ...`（tests/unit/test_postproc.cpp:194）。
- 同一批二义错误的两次计数：REPORT/预检初稿为 `合计: 20/24 个测试 TU 受影响, 136 处二义错误`、`受影响面 20/24 TU、136 处`；随后在 `docs/ledger/2026-09-18-P1.0b/preflight_blockers.log` 追加更正 `## 2026-09-19 多 agent 复核更正: 测试二义计数 136 → 176`。
- 切片把该更正的原因行截断了（只到 `原因: cla`），所以本条**不主张** 136→176 的差值一定全部来自 `-ferror-limit`；只主张「grep 日志计数会偏低，必须复核口径」。

**边界 / 反例**：

- 上限是 per-TU 的，`err=20` 这类数字只覆盖该 TU 的前若干条，不是工程总错误数。
- 若统计脚本本来就是逐 TU 独立编译、且每个 TU 的错误数低于上限，`grep -c` 可以准确。
- `-ferror-limit=0` 会让日志显著变大，只在需要精确影响面时用；日常迭代看「是否为零」不受影响。

**失败信号（未来命中即该想起本条）**：报告里的错误数恰好停在一个固定小整数（本会话为 20）并伴随 `too many errors emitted` 截断行；或同一批改动不同人复核报出的总数不一致。
