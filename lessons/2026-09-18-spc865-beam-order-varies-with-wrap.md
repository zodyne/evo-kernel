---
id: spc865-beam-order-varies-with-wrap
type: fact
status: candidate
scope: project:spc865
domain: radar-data-format
tags: [spc865, bin, beam-order, frame-layout, wraparound]
triggers:
  - "写 / 审 SPC865 .bin 解析代码，把帧内三波束顺序按固定的 远-中-近(1-2-3) 硬编码"
  - "spc865_cli.py scan 输出里的 beam orders / wrapped 字段看不懂，不知道要不要处理"
  - "同一批采集文件里各文件的波束标号对不上、测角 / 距离结果像串了波束（失败信号）"
  - "要统计一个 SPC865 数据集的文件数 / 帧数与波束排列，准备做逐波束对齐"
  - "移植 MATLAB 侧波束重排逻辑，发现帧内顺序不是单一排列"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a977-6e7b-77c1-a593-51a2cfa0a8bf
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [spc865-bin-frame-layout-verified, spc865-frame-counter-tt-phase-not-always-1]
---
# SPC865 帧内波束顺序不固定（三种排列 + 回绕），解析必须按帧读顺序

**主张**：SPC865 采集文件帧内的三波束顺序不是固定的 `远-中-近`，同一批 40 个文件里出现三种循环排列、且分「回绕 / 不回绕」两类。`spc865_cli.py scan` 直接把它当一等字段报出来：`beam orders: Counter({(2, 3, 1): 20, (1, 2, 3): 12, (3, 1, 2): 8})`（计数按文件，20+12+8=40），以及 `wrapped: 20`（切片把多行结果压成一行，后接 `frames per f...`）；按文件细分可见 `(2, 3, 1)` 不回绕 8 / 回绕 12、`(1, 2, 3)` 不回绕 8 / 回绕 4。所以做波束归因（测角 / 距离 / 能量）时必须按帧读实际顺序，或复用 `spc865/io.py` 已有的子帧旋转归一化，不能硬编码第 1/2/3 个波束是哪束。

**为什么**：波束标号串位是静默错误——结果仍在合理范围内，但归因错束，后续按波束下的结论（哪束脱靶、逐波束零偏）全部不可信。scan 把它列为常规字段、git 历史里也有 `子帧旋转归一化（spc865/io.py）` 的修复，说明这是数据的常态而不是异常样本。

**证据（本会话命令 ↔ 结果）**
- `D=.../20260916_暗箱不良雷达&正常雷达采数/角反20m; ./spc865_cli.py scan "$D" --json` → `files 40 frames 400 MB 838.9 beam orders: Counter({(2, 3, 1): 20, (1, 2, 3): 12, (3, 1, 2): 8}) wrapped: 20 frames per f...`
- 进程内用解析器统计 → `波束顺序 (1, 2, 3) 不回绕 → 8 个文件`、`(1, 2, 3) 回绕 → 4 个文件`、`(2, 3, 1) 不回绕 → 8 个文件`、`(2, 3, 1) 回绕 → 12 个文件`、`(3, 1, 2) ...`
- 单文件解析输出带顺序：`波束顺序 2-3-1`（CS-60/V1.1.5 与 QD-1/V1.2.0 的代表文件都如此）。
- `git log` 提交 23ca1895 标题：`修正四处数据口径缺陷：子帧旋转、JSON 输出、逐波束检验、CFAR 门限下发`，正文含 `子帧旋转归一化（spc865/io.py）`。

**边界 / 反例**
- 切片只给了 `wrapped` 的计数（20），没有给它的判定机制；本条只主张「存在两类、顺序有三种」，不要据此推断回绕的物理含义。
- 40 文件样本来自 20260916 角反 20 m 数据集，三种排列的比例可能随批次变；但「顺序会变」应作为解析前提。
- `beam orders` 的计数是文件数不是帧数（20+12+8=40 与文件数吻合）；别把它读成 40 帧的分布。
