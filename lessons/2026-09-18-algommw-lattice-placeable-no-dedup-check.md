---
id: algommw-lattice-placeable-no-dedup-check
type: fact
status: candidate
scope: project:algommw
domain: radar-doa
tags: [algommw, doa, 摆格, 2d-fft, 判据未实现, 重复坐标]
triggers:
  - "在 algommw 里找/补『不重位』判据（同一格只放一个阵元），想知道它在哪一层实现"
  - "2D 角度 FFT 快路径角度不对，怀疑两个阵元 lround 后落进同一格（失败信号：core/ 里搜不到去重/占用检查）"
  - "审查/移植 bDoaLatticePlaceable 与 xGrid 摆格路径，要判断它到底校验了什么"
  - "发现方声称『不重位判据未实现』，要复核这条否证断言"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a704-a66c-7353-8a3d-42fd6dab14e3
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [algommw-sparse-3z-array-needs-dbf2d-full-grid, algommw-doa-angle-candidates-fixed-grid]
---

# algommw 2D 摆格的「不重位」判据没有实现：bDoaLatticePlaceable 只判界与整数

**主张**：algommw 2D 摆格路径里「不重位」（同一格只应放一个阵元）**没有代码层判据**。`core/src/dpu/doa/geom.c:95-107` 的 `bDoaLatticePlaceable` 只调 `prvIsLatticeCoord`（判界 + 判整数），不查去重/占用；而 2D 后端是按 `xGrid[lround(xPosZ)][lround(xPosX)]` 直接落格的（`beam.c:176` 注释、`beam.c:271` memset 清零），所以两个坐标取整后相同的阵元不会被这条判据拦下。该要求在代码侧只以注释/要求的形式出现，没有实现落地。

**证据**（对抗式验证会话切片，命令 ↔ 结果；裁决 refuted=false）：

- `rg -n '不重位|重位|去重|重复坐标|duplicate' --glob '!build' docs/ core/ tests/ python/ | head -40` → 切片里可见的命中只有 `python/radar_viz/boards.py:28`（采集目录去重）、`python/radar_viz/view_tracks_3d.py:82`（按帧号去重），都是查看器逻辑，与 DOA 摆格无关。
- `sed -n '88,110p' core/src/dpu/doa/geom.c` 配 `grep -n 'bDoaLatti…'`（"=== 行号核对 ==="）→ 读到 `bDoaLatticePlaceable` 的谓词函数体（返回 0U/1U），行号与发现方的引用对上。
- `rg -n 'xGrid' core/src/dpu/doa/beam.c | head -30` → `176: /* 摆格安全性(2D):写 xGrid[lround(xPosZ)][lround(xPosX)],而方位 FFT 只遍历…`、`271: memset(pxCtx->xWork.x2D.xGrid, 0, …`。
- 末条 assistant 的逐条核对表：「geom.c『不重位』判据未实现」**成立**；`bDoaLatticePlaceable` 只调 `prvIsLatticeCoord`（判界+整数），**无去重/占用检查**；「不重位」只出现在 beam 侧注释。结论 `refuted=false`（仅修正了 why 的措辞与严重度解释）。

**边界 / 反例**：

- 本条只证明「这条代码判据缺席」，不等于「实际一定出现两阵元同格」：是否真的重复取决于各 profile 的几何表（如 `profiles/sr61_tdm/sr61_aop.csv` 给的是逐天线坐标）；切片未展开 xGrid 写入的完整调用链，也未确认上游是否另有去重环节。
- 判据缺席本身就是静默行为：摆格是 memset 后逐格写入，重复落格只会覆盖、不会返回错误码。要量化影响必须另做数值复算——本切片里 `/tmp/dupprobe/probe.py`、`probe2.py` 复刻摆格+FFT 的输出（如 `peak u=0.1875` vs 真值 `0.1730`）只够给量级线索，不足以单独定严重度。
