---
id: gitea-selfhosted-forge-release-api
type: lesson
status: validated
scope: global
domain: research-methodology
tags: [gitea, forge, release-api, curl, research]
triggers:
  - "批查一堆开源项目仓库时，某个老牌项目在 api.github.com 上怎么都找不到"
  - "要查 0 A.D. 这类自建托管的项目最新发布了什么版本、什么时候发的"
  - "手里的批量仓库检查脚本只认 github.com，别的 forge 的仓库全被漏掉（失败信号）"
  - "需要从非 GitHub 的 forge 拿仓库元数据（stars/updated/描述）做筛选"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad13-1d64-710a-b61a-fd28b9b67884
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [github-api-tree-inspect-before-clone]
---

老牌开源项目不一定托管在 GitHub（0 A.D. 就挂在自建 Gitea `gitea.wildfiregames.com`），**只跑打 `api.github.com` 的批量脚本会把这些项目整体漏掉**；对这类项目要改用其自身 forge 的 API，Gitea 的仓库与发布端点路径形如 `/api/v1/repos/<owner>/<repo>` 和 `/api/v1/repos/<owner>/<repo>/releases?limit=N`。

为什么：会话里 `gh_check.sh`（内部 `curl -s "https://api.github.com/repos/$r"`）批查了十余个游戏仓库，0 A.D. 始终不在结果里；换成 `curl -s -m 20 "https://gitea.wildfiregames.com/api/v1/repos/0ad/0ad"` 立刻拿到 `name=0ad/0ad updated=2026-09-16 stars=63 desc=The main repository for pyrogenesis and 0 A.D.: Empires Ascendant`，再加 `/releases?limit=3` 拿到 `v0.28.0 2026-02-15 / a27.1-rc3 2025-07-14`。走 forge 的 API 比抓项目官网（会话里对 `play0ad.com` 做去标签 grep）能直接拿到带日期的版本事实。

边界：得先知道该项目的 forge 地址（从官网/项目页的仓库链接拿），且端点是 Gitea 的 `/api/v1/repos/...` 形态，与 GitHub 的 `/repos/...` 不同，批量脚本要按 host 分支；批查脚本返回空时要先怀疑「这个项目根本不在这家 forge」，再怀疑路径写错。

证据：切片中两条 Gitea 调用各带完整结果——仓库元数据 `name=0ad/0ad updated=2026-09-16 stars=63`，发布列表 `v0.28.0 2026-02-15`、`a27.1-rc3 2025-07-14`。
