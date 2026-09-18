---
id: algommw-cluster-mode-off-per-cell-points
type: fact
status: candidate
scope: project:algommw
domain: radar-dsp
tags: [algommw, cluster, pointcloud, profile-toml, cfar]
triggers:
  - "在 algommw 里找点云聚类/目标连通（DBSCAN/欧氏聚类之类）的实现"
  - "问 algommw 为什么点云里每个 CFAR 单元都是一个点、没合并成目标"
  - "移植 algommw 点云链路，拿不准要不要自己补一层聚类"
  - "想打开/关闭 algommw 聚类，找 profile.toml 里的 cluster 开关"
  - "在 C 核里 grep cluster 找不到目标级合并逻辑，怀疑自己漏看了"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae37-a909-77c1-a593-51c0d61c185c
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [algommw-profile-single-config-source]
---

algommw 当前点云不做目标级聚类/连通：AFM761 profile 的 `[cluster] mode = "off"`（`profiles/afm761_ddm/profile.toml:62-63`），CFAR 链路（`eChainCfar` → `eCfarProcess` → cfar.c）输出 `Cloud_t` 是逐 cell 一个 `Point_t` 的数组（`radar.h`，字段 `usRangeBin/usDopplerBin/xRa…`）——"把离散检出点连成目标/簇"这一步在现配置下不发生，点云即 CFAR 单元级。

**为什么**：研究或移植 algommw 连通逻辑的人，若预设 C 核里有现成 cluster/目标合并实现，会在源码里白找；行为应从 profile.toml 的 `[cluster]` 段读起（配置开关在 profile，不在代码路径选择）。

**边界**：切片只证明 AFM761 profile 配置关闭 + `Cloud_t` 逐 cell 结构；SR61 profile 的 cluster 开关值未取证；C 核里有无 cluster 实现代码（mode 非 off 时会怎样）未取证，不得断言"功能不存在"。证据限于 2026-09-17 会话时点的仓库 HEAD。

**证据**：slice 命令↔结果第 5 条：`grep -n "cluster\|mode =" profiles/afm761_ddm/profile.toml` ↳ `62:[cluster] 63:mode = "off"`；末条 assistant：`eChainCfar`(`core/chain/chain.c:236`) 调 `eCfarProcess`→`cfar.c`，输出 `Cloud_t`（`radar.h` 的 `Point_t` 数组），逐 cell 一个 `Point_t`。
