---
id: bulk-archive-dry-run-empty-set-assertions
type: lesson
status: candidate
scope: global
domain: tooling
tags: [batch-processing, dry-run, mv, archive, reconciliation]
triggers:
  - "写批量归档/搬迁脚本，按规则把文件分类移动到目标目录"
  - "准备执行批量 mv（失败信号：没先跑 dry-run 对账）"
  - "dry-run 计划数与源目录实际文件数不一致"
  - "同一文件被多条规则匹配，清单里出现重复条目"
  - "脚本打印『成功』但担心漏搬或重复搬"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a8c1-5e3e-710a-b61a-fd2478c30f87
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [derived-list-read-back-against-source-before-use, git-mv-bulk-verify-byte-identical-renames]
---

**主张**：批量归档/搬迁脚本必须**先在 DRY 模式跑，并用四条断言把错误挡在执行前**：① 计划条数 == 源目录实际文件数；② 未被归类的 == 0；③ 计划里源不存在的 == 0；④ 目标重名 == 0。四项全过才允许 `DRY=0` 实搬。本会话首轮 dry-run 计划 **69** 个而桌面实际只有 **59** 个（清单开头编号 1、2 是同一源文件映射到同一目标目录，重复记账），修规则后才 `59 == 59` 且三项为空，随后搬运一次成功。

**为什么**：批量 `mv` 没有事务，重复条目会第二次搬一个已不在原处的文件（报错或搬错），漏项则在脚本打印「成功」后静默留下——两者都只有对账能发现。断言必须是「空集合」这种可判定的形式，而不是靠人扫清单。

**边界/反例**：与 related 的 `derived-list-read-back-against-source-before-use` 不同：那条管**事后**对派生清单做集合回读（解决清单漏项），本条管**执行前**的闸门（解决规则重复/幽灵导致的计划数虚高）；两条都做才闭环。另外本条的 ④「目标重名=0」针对规则内重名，跨批次撞名仍需人工决定改名策略。

**证据**（session 01a0a8c1，evo slice 「命令 ↔ 结果」）：
- 首轮 `bash /tmp/desktop-archive.sh` → `==== 归类清单（共 69 个） ==== 1 01-项目文档/无人机远距避障雷达技术研究 <- 无人机远距避障雷达技术研究`、`2 01-项目文档/无人机远距避障雷达技术研究 <- 无人机远距避障雷达技术研究`（同名同目标重复）。
- 修正后 → `==== 归类清单（共 59 个，无匹配规则 0 条） ====`。
- 实搬前对账：`桌面现有松散文件 : 59`、`计划归档数量 : 59`、`--- 未被归类的（应为空） ---`、`--- 计划里桌面没有的（应为空） ---`、`--- 规则内重名（应为空） ---` → `==== 开始搬运 ==== 成功`。
- 搬运后归档区分类计数（`01-项目文档 18 个`、`04-代码与脚本 10 个` …），桌面随后为 0 条目。
