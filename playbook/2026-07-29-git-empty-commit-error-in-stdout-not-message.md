---
id: git-empty-commit-error-in-stdout-not-message
type: lesson
status: validated
scope: global
domain: git
tags: [git, execSync, nodejs, automation, error-handling]
triggers:
  - "脚本/CLI 里用 execSync 跑 git commit 并在 catch 里判失败原因"
  - "自动化提交把『无实际变更』误判成失败、记降级日志（失败信号）"
  - "git commit 空提交时报 Command failed，但工作区其实是干净的"
  - "给 curate/commit 类自动化加空提交容错"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: test
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [git-add-untracked-source-path-aborts-staging]
---

# Node execSync 跑 git 空提交：判据 "no changes" 在 e.stdout 不在 e.message

## 主张

`execSync('git commit ...')` 遇空提交（nothing to commit）抛出的 error 对象里，`e.message` 只有 `"Command failed: git commit ..."`，git 的真正输出 "no changes added to commit" 在 `e.stdout`。自动化提交做空提交容错时必须查 `e.stdout`（必要时连同 e.stderr），只看 e.message 会把无害的空提交误判为失败。

## 为什么

evo-kernel curate 的空提交场景探针实测：

```
e.message 含 no changes ? false
e.stdout  含 no changes ? true
--- e.message ---
"Command failed: git commit -qm probe"
```

修复后 smoke 用例锁定行为：`✓ curate 空提交（无实际变更）判成功，非失败`，并用回退对照验证过该用例确实为修复而转红（stash 修复版后同一用例 FAIL，PASS=93→FAIL=1 对应项）。

## 反例/边界

- 不同 git 版本/locale 下文案可能不是 "no changes"（如本地化输出），匹配前固定 `LC_ALL=C` 或放宽匹配。
- 空提交判成功的前提是"确实无变更预期"；若流程上本该有变更（如刚写过文件），空提交反而是异常信号，不能一概吞掉——先 `git status --porcelain` 确认再定性。
- `execFileSync`/`spawnSync` 的 error 结构同理，stdout 都在 error 对象的 stdout 字段。

## 证据

- 命令：临时 git 仓库探针（`node -e` 打 execSync 空提交 error 三字段）输出如上对照；`npm test` 中 `✓ curate 空提交（无实际变更）判成功，不记降级`，全量 PASS=93 FAIL=0。
