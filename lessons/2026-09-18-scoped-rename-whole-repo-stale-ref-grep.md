---
id: scoped-rename-whole-repo-stale-ref-grep
type: lesson
status: candidate
scope: global
domain: refactoring
tags: [refactor, rename, grep, stale-reference, parallel-lanes]
triggers:
  - "只被授权改单/少数文件，却要删改本模块的公开类名"
  - "重命名后收尾自查还有没有别处 import 旧名（失败信号：`grep -rn <旧名>` 仍有源码命中）"
  - "`grep -rn <旧名>` 输出里混着 `Binary file .../__pycache__/*.pyc matches`，分不清源码还剩几处引用"
  - "残留引用落在自己无权改的模块（并行 lane / 他人文件）里，不知该不该动、怎么收尾"
  - "交付报告想写『改动仅限 X 文件』但其他模块仍引用被删符号"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a851-cb20-7719-ba82-32042e03799e
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [parallel-lane-boundary-proof-by-mtime, stale-pyc-preserves-pre-edit-co-names, 2026-07-27-zsh-unquoted-glob-arg-no-matches]
---

# 单文件范围内的重命名：收尾要全仓 grep 旧符号，越界残留必须显式交接

**主张**：任务只允许改少数文件（本次只有 `spc865/ui/views.py` 与 `tests/python/test_ui_views.py`）时，删/改本模块的公开类后仍要跑一次全仓 `grep -rn "<旧类名>" <包>/ tests/`；命中要分清「源码引用」与 `__pycache__/*.pyc` 的二进制匹配；残留若落在无权修改的其他模块（本次 `spc865/ui/workbench.py`，属并行他人范围），把它作为交接项写进交付，而不是「我只改了自己那几个文件、自己范围已清」就收尾。

**为什么**：单文件内的重命名，影响面由**全仓引用**决定，不由授权范围决定。并行 lane 各改一个模块时，别人模块里的旧名 import 不会因为自己那几行删干净或自己文件的测试全绿而消失；`__pycache__` 里改前的字节码也会命中同一条 grep（`Binary file ... matches`），让「还剩几处引用、在哪」更难判断。

**怎么做**：
1. 收尾跑全仓 grep（含 `tests/`）：`grep -rn "<旧名1>\|<旧名2>" <包>/ tests/`（交替式 grep 只看有没有命中，不要用它的计数下结论）。
2. 把缓存命中从源码命中里分出来：加 `--include='*.py'`（zsh 下给 glob 加引号，见 related）或 `--exclude-dir=__pycache__`。
3. 对每条源码命中判归属：在自己可改范围内 → 改；在他人 lane 文件里 → 保留，并在报告里点名「该模块仍需更新」。
4. 报告把「本 lane 已清空」与「待他人更新」分开写，别把越界残留并进「改动仅限 X 文件」的结论。

**证据（本会话命令 ↔ 结果，切片原文）**：
- 收尾命令自带预期标注：`echo "=== 剩余引用（应只有 workbench.py，属他人改动范围）==="; grep -rn "RangeProfileView\|DopplerProfileView" spc865/ tests/ 2>/dev/null`；切片的「写/改文件」清单为 `spc865/ui/views.py`、`spc865/ui/selection.py`、`tests/python/test_ui_views.py`。
- 结果为两类命中并存：`Binary file spc865/ui/__pycache__/workbench.cpython-314.pyc matches` 与 `spc865/ui/work...`（workbench.py 源码）——旧类名既留在他人源码里，也留在缓存字节码里。

**边界 / 反例**：
- 若源码层已无命中、只剩 `.pyc` 命中，说明源码引用已清，残留只是缓存（见 related 的 stale pyc），不要为此改文件、也不要据此继续找引用。
- 本条不主张「越界也要顺手改掉」：只被授权改少数文件时，越界修改本身违规；正确动作是交接。
- 该 grep 的前提是旧名足够独特、能作为符号搜索；若旧名是 `View` 这类泛词，命中会淹没在噪声里，需配合 `--include='*.py'` 与 `^class` / import 行上下文精筛。
