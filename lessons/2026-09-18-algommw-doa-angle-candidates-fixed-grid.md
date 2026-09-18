---
id: algommw-doa-angle-candidates-fixed-grid
type: fact
status: candidate
scope: project:algommw
domain: codebase-map
tags: [algommw, doa, 角度网格, 正弦格, music]
triggers:
  - "移植 algommw 测角，角度候选是怎么量化的（多少点、什么格）"
  - "对拍测角结果对不上，怀疑两侧角度网格密度不一致（失败信号）"
  - "想提高 algommw 测角分辨率，找角度步进参数在哪"
  - "MUSIC 谱搜索的角度范围与步进定义在哪"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af3a-ab1b-7097-91f3-80f1eaca1bbd
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
---

algommw 两条 DOA 路径的角度候选都是**固定网格量化**，不是连续估计：
谱峰快路径候选 = az/el 各 64 点的规范正弦格（`beam.c:24`，bDirect=0 角度 FFT 快路径）；
MUSIC 谱搜索按 `xAzDeg = MUSIC_AZ_MIN_DEG + iAz * MUSIC_AZ_STEP_DEG` 步进格扫描
（`core/src/dpu/doa/music.c:165`，随后 :167 做 xNorm 归一）。

为什么：移植/对拍时角度分辨率由网格决定，
两侧网格点数或步进不同会表现为固定量化差，容易误判成测角算法误差；
且结果精度上限就是格距，不要期待亚格连续输出。

边界：64 点与 MUSIC 步进的具体数值常量本次切片未展开（只见到命名与公式），
移植时需进 beam.c/music.c 头部确认常量定义。
证据：会话切片 2 组 rg 命令及输出（beam.c:24 / music.c:165,167）。
