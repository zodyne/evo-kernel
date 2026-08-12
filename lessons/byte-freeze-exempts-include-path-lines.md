---
id: byte-freeze-exempts-include-path-lines
type: lesson
status: candidate
scope: global
domain: verification
tags: [byte-identical, freeze-constraint, git-mv, include-path, review]
triggers:
  - "任务同时要求『某文件内容一个字节不动』和『移动/改名该文件』"
  - "有 byte-identical / MD5 输出锚的仓库里做目录搬迁"
  - "review 时判断 diff 里的 #include 路径行变化算不算违反冻结约束"
  - "给 worker 写『零改动』类硬约束，担心约束与移动操作自相矛盾"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fc28c-b27f-7ef1-a2dc-4882a3c48ba7
last_verified: 2026-08-03
superseded_by: null
schema_version: 1
related: [bytes-exact-oracle-gate-for-pipeline-port, restructure-request-diagnose-load-bearing-first]
---

**主张**：「算法文件内容零改动」的冻结约束与「移动该文件」并存时，文件内部的 **#include 路径行是路径机制的强制伴生，不属于逻辑改动**——冻结约束应在任务定义里**明文豁免**此类行。否则执行者为守字面约束会放弃合理移动，或 reviewer 每轮都围绕这一行重新争论一次。

**证据**（algommw flatten `freertos/tasks/`，2026-08-03）：`pipeline.c` 上移一层后唯一变化是 `#include "tasks/pipeline.h"` → `#include "pipeline.h"`（rename 相似度 99%），`pipeline.h` blob hash 两侧逐字节相同；B1 输出锚 MD5（`cb6afb4b…`/`0160e270…`）逐字符吻合。reviewer 结论：此类行应被约束明文豁免，「它会在未来任何搬目录 + 字节冻结并存的场景复现，提前立约可省一轮争论」。

**判定方法**（三步闭环）：① `git diff --find-renames` 确认显示为 rename 且相似度 ≥99%；② 差异行全部是 include/路径行，无逻辑行混入；③ 输出锚（MD5/byte-identical 闸门）复核不变。三者全过即合规。

**边界**：豁免仅限「路径行」——include 路径、CMake 里的源文件路径行、文档里的文件引用行；任何触及表达式/常量/控制流的 diff 行都不在豁免内。写任务约束时的推荐措辞：「内容零改动（因移动产生的 include/引用路径行除外，需附 rename 相似度证据）」。
