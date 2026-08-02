---
id: doc-drift-fix-grep-by-concept
type: lesson
status: candidate
scope: global
domain: documentation
tags: [doc-drift, grep, rename, cleanup, contract, authoritative-docs]
triggers:
  - "修一处被指出的文档过时描述（review 报告/自己发现）"
  - "删了文件、改了 API 名、改了 target 名之后要同步文档"
  - "reviewer 标出某文档某一行漂移，准备只改那一行"
  - "重命名/删除符号后担心文档断链或新旧措辞不一致"
created: 2026-08-02
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fc28c-b27f-7ef1-a2dc-4882a3c48ba7
last_verified: 2026-08-02
superseded_by: null
schema_version: 1
related: [doc-selfreported-counts-drift, nav-doc-pinned-head-goes-stale]
---

**主张**：修文档漂移时，拿漂移的**概念**（已删文件名 / 旧 API 名 / 旧 target 名 / 旧技术栈词）**全仓 grep，不要只修被标记的那一行**——漂移按概念聚簇、不按位置。reviewer 指出一处，几乎总意味着同一过时概念还躺在同文件别处和其他文档里。

**证据**（algommw，2026-08-02）：reviewer 只标了 `visualization_contract.md:88` 的 pybind11 一处。按概念 grep（`C++|cpp|pybind|bindings|dump_writer|eDpm|dpm.h`）发现同文件共 **6 处**残留：标题「C++ ↔ Python」、`dump_writer.{h,cpp}`（该文件早已被 hal_sink_csv 取代）、`eDpmProcessFrame`/`dpm.h`（ADR 0003 已删 dpm 层）、pybind11/bindings；外加 `CLAUDE.md:251` 也引用 `dump_writer.c`。只改 :88 会留下 5 处自相矛盾。

**配套纪律（同样重要）**：只改**活着的权威文档**（数据契约 / CLAUDE.md / COMPASS / architecture），**历史设计文档与 ADR 保持原样**——它们记录的是当时为真的状态（本会话有意不动 `PHASE3_TRACKING_DESIGN.md`、`LIBRARY_ARCHITECTURE_STUDY.md`、ADR 0003 里对 dump_writer 的历史引用）。改完用同一 grep 确认零残留再提交。

**边界**：「概念」要选已消失的符号名而非泛词（如「配置」「测试」无法 grep）；改名类任务在改名 commit 里就该顺手跑此 grep（worker 本会话对 `freertos_preview` 正是这么做的），文档漂移修只是补课。与 `doc-selfreported-counts-drift`（自述数字漂移）同族不同型：那条管「数字」，本条管「已消失符号的引用」。
