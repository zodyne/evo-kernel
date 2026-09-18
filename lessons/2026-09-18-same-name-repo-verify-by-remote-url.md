---
id: same-name-repo-verify-by-remote-url
type: lesson
status: candidate
scope: global
domain: git
tags: [git, remote, dedup, migration, dotfiles]
triggers:
  - "搬迁目录时目标位置已存在同名仓库目录"
  - "准备删除一个看起来重复的仓库副本（失败信号：只按目录名判重）"
  - "一台机器上出现两个同名仓库（dotfiles 这类通用名）"
  - "判断某目录是正牌仓库还是别人仓库的副本"
  - "搬迁后 remote 对不上、担心推错仓"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a8c1-5e3e-710a-b61a-fd2478c30f87
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: []
---

**主张**：目录名相同 ≠ 同一个仓库。桌面迁移时 `~/Desktop/dotfiles/` 与已有的 `~/Dev/dotfiles/` 撞名，但两者根本不同源——前者是第三方仓库 `github.com/patricorgi/dotfiles.git`，后者是自己的 `git@github.com:zodyne/dot-files.git`；**判重/删除前必须用 `git remote get-url`（或 `git remote -v`）核对仓库身份**，确认非同一仓库就只能保留双份（加后缀），不能按目录名当重复项删掉。

**为什么**：`dotfiles`、`workspace`、`Code` 这类通用目录名极易撞车；仓库的权威身份是 remote URL，不是目录名，也不是 HEAD/分支名。本会话 23 个桌面仓库搬进 `~/Dev`，3 个撞名，全部加 `-desktop-2026-09-16` 后缀并存；删除存疑副本前正是靠 remote 比对（第三方 vs 自己）才敢下结论。

**边界/反例**：只有**无 remote** 的本地仓库才谈得上「用内容判断」；有 remote 时 remote URL 就是身份，别再用 mtime/HEAD 猜。反过来，remote 相同也可能内容分叉（本地领先/落后），那是「同一仓库的两份工作树」，与「不同仓库」是两类问题，处理方式不同。

**证据**（session 01a0a8c1，evo slice 「命令 ↔ 结果」）：
- `A="$HOME/Dev/dotfiles"; B="$HOME/Dev/dotfiles-desktop-2026-09-16"` → `两者 remote`：`A(dotfiles): origin git@github.com:zodyne/dot-files.git`，`B` 为另一 remote。
- 删除前最终校验：`✓ remote = https://github.com/patricorgi/dotfiles.git （第三方仓库，确认是 B）`，随后才删除 B。
- 终态核验：`~/Dev` 下带后缀残留 `gtrack-desktop-2026-09-16 / OpenRadar-desktop-2026-09-16`，正牌 `dotfiles` 保留，23 个仓库 `.git` 完好。
