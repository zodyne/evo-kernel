---
id: git-empty-commit-check-stdout-not-message
type: lesson
status: candidate
scope: global
domain: tooling
tags: [git, error-handling, exec, stdout, stderr, tolerance]
triggers:
  - "用 exec/spawn 包装 git 命令并做错误容错"
  - "容错分支从未生效（失败信号：同样的失败反复出现）"
  - "匹配 CalledProcessError 的 message 字段判断错误类型"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:dc63fb24
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
---
# 容错 exec 包装的 git 命令要并查 stdout/stderr：e.message 只有 "Command failed"

**主张**：对 exec 异常做错误类型匹配（如"空提交容错"）时，必须并查 `e.stdout`/`e.stderr`，不能只看 `e.message`——Node `execSync` 抛错时 `e.message` 只有 `Command failed: …`，git 的 `no changes added to commit` 实际写在 **stdout**。只查 message 的容错**从未生效过**，且因为没有报错会长期潜伏。

**为什么**：这类 bug 的特点是"容错代码存在、测试缺失、失败路径无人走"——直到真实空提交出现才暴露。配套教训：发现 bug 时先查仓库是否已被后续提交修复（本例 fix 已在 `cc3ff21` 落地且带了回归测试，重写反而会覆盖更完整的实现）。

**边界**：不同语言 exec 封装字段位置不同（Python `CalledProcessError.output/.stderr`、Node `e.stdout`），原则相同：匹配真实输出流而非异常摘要。

**证据**：session dc63fb24 考古 `bin/evo` gitCommitWithRetry；smoke.sh:280「空提交容错」回归测试。
