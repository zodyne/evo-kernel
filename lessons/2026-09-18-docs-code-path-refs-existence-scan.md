---
id: docs-code-path-refs-existence-scan
type: lesson
status: candidate
scope: global
domain: documentation
tags: [docs, dead-reference, existence-check, code-review, ripgrep]
triggers:
  - "审查文档/设计稿/README 里引用的源码路径是否还有效"
  - "删了或搬了源文件后，担心文档里仍留着指向它的路径"
  - "文档里 grep 得到路径，test -e 却报文件不存在（失败信号）"
  - "要一次性盘清『文档引用了哪些代码文件』并逐个验存在性"
  - "人眼抽查文档引用，漏掉了不存在的文件（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a5f0-9954-7353-8a3d-42d3da5cbafa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [doc-drift-fix-grep-by-concept, markdown-doc-anchor-count-drift]
---

**主张**：审查"文档引用的代码路径是否还有效"时用机器穷举、不靠人眼抽查：从文档里正则抽出所有路径形 token，逐个做存在性检查（`test -e`），一步得到**完整**的 `MISSING` 清单，再对每个缺失路径反查"哪些文档还在引用它"。

**为什么**：文档对源码路径的引用会随删文件/重构静默腐烂，人眼只能抽查，漏掉的恰恰是没人再看的那几份文档。机器扫描的增量在于**不需要事先知道哪个符号已经死了**——这一点区别于"按已知概念 grep"（见 related `doc-drift-fix-grep-by-concept`：那条处理"reviewer 已指出一处漂移后按概念全仓找同类"）。

**做法**：
1. 从文档语料抽路径 token，模式按仓库目录结构定制，例如
   `rg -oN '(core/(src|include)/[A-Za-z0-9_/]+\.(c|h)|tests/[a-z]+/[A-Za-z0-9_]+\.c|python/[A-Za-z0-9_/]+\.py)' --glob '!build/**' docs CLAUDE.md`
2. 去重后逐个 `test -e`，输出 `MISSING:` 行（筛选范围排除 build/、缓存目录）。
3. 对每个 MISSING 路径反查引用出处：`for p in <missing...>; do rg -lF "$p" docs CLAUDE.md; done`，得到"缺失路径 → 引用它的文档"配对。
4. 抽样单点复核一条（`test -e <path> && echo EXISTS || echo MISSING` + `ls` 该目录），确认不是正则截断造成的假阳性。

**证据（session:01a0a5f0…，algommw 仓库审查）**：
- 扫描输出（切片原样）：`MISSING: core/include/core/dpm/dpm.h`、`MISSING: core/include/core/dpu/cfar/ca.h`、`MISSING: core/include/core/dpu/tracking.h` 等。
- 反查出处：`### core/include/core/dpm/dpm.h  ./docs/archive/TRACK_MERGING_DESIGN.md`、`### core/include/core/dpu/cfar/ca.h  ./python/core…`。
- 单点复核：`test -e core/include/core/dpu/cfar/ca.h && echo EXISTS || echo MISSING` → `MISSING`；`ls core/include/core/dpu/cfar/` 只列出 `cfar.h`，确认 `ca.h` 是该目录下确实不存在的头，而非路径写错。

**边界**：扫描结果必须按"文档是否仍权威"分诊——`docs/archive/`、ADR、历史设计稿里的引用是当时为真的记录，**不必**改（与 `doc-drift-fix-grep-by-concept` 的"只改活文档"纪律一致）；清理对象是 CLAUDE.md / architecture / 现行契约这类活文档。token 正则按仓库目录结构定制，否则会漏掉简写引用（如正文只写 `dpm.h`、不写全路径）。
