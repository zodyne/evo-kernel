---
id: 2026-09-16-docker-desktop-dockerraw-sparse-reclaim-restart
type: lesson
status: validated
scope: global
domain: docker
tags: [docker-desktop, disk, sparse, reclaim]
triggers:
  - "删了一堆 docker 镜像/容器，宿主磁盘却几乎没变小"
  - "Docker.raw 文件 ls 报几百 G，担心磁盘被吃满"
  - "docker system df 显示大量 reclaimable 但磁盘没回收"
  - "清理 Docker Desktop 磁盘占用"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7f9-4ced-73b3-8cfc-3829cc92108c
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: []
---

Docker Desktop (macOS) 的 VM 磁盘文件 `Docker.raw` 是稀疏文件：`ls -lh` 报的 460G 是上限而非实占，真实占用看 `du -sh`（本会话清理前 `ls` 报 460G、`du` 报 25G）。删镜像/容器后宿主空间不自动回收，必须 `docker desktop restart` 触发 VM trim + `docker builder prune -af` 清构建缓存，本会话 Docker.raw 从 25G 降到 13G、宿主可用从 82Gi 提到 83Gi。

为什么：Docker Desktop 的 VM 磁盘是懒分配稀疏文件，删掉的对象只是标记为可复用，物理块要等引擎重启后的 trim 才归还宿主；构建缓存（builder cache）是独立的另一块占用，`docker system df` 里单列。

边界/反例：清完镜像别只看 `docker images` 数量下降就宣布「空间回收成功」，要等 restart 后再 `du -sh` Docker.raw 复测；`docker system df` 的 RECLAIMABLE 是理论可回收值，不代表已归还宿主。
