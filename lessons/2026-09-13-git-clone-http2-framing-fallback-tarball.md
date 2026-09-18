---
id: 2026-09-13-git-clone-http2-framing-fallback-tarball
type: lesson
status: candidate
scope: global
domain: devtools
tags: [git, clone, http2, tarball, fallback]
triggers:
  - "git clone GitHub 报 Error in the HTTP2 framing layer"
  - "代理环境下 clone 反复失败（失败信号）"
  - "只需要读/评审仓库源码，不需要 git 历史"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a099a8-07d2-766c-b240-9eaed5f6ca6d
last_verified: 2026-09-13
superseded_by: null
schema_version: 1
---

**主张**：代理环境下 `git clone` GitHub 报 "Error in the HTTP2 framing layer" 时，不值得修 git/代理参数——若只是要读源码，改从包管理器 registry 拉 tarball（`curl https://registry.npmjs.org/<pkg>` 取 dist tarball URL 解包）秒级等效。

**为什么**：HTTP2 framing 错误出在代理对 HTTP/2 的处理，与目标仓库无关；npm registry 的 tarball 端点走普通 HTTPS，同一网络环境下稳定。

**反例/边界**：要提交历史、分支、子模块时 tarball 不够，仍需 clone 或换网络路径；registry 未收录的仓库此路不通。

**证据**（session:01a099a8-07d2-766c-b240-9eaed5f6ca6d）：`git clone --depth 1 -q https://github.com/jjuraszek/pi-gauntlet.git` → `✗ fatal: … Error in the HTTP2 framing layer`；紧接的替代命令从 registry tarball 提取 pi-gauntlet 与 gentle-pi 均成功（"extracted … ok"）。
