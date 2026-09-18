---
id: spc865-bin-frame-layout-verified
type: fact
status: candidate
scope: project:spc865
domain: radar-data-format
tags: [spc865, awr2944, lvds, bin, frame-format, ground-truth]
triggers:
  - "解析 /Users/zodyne/Dev/SPC865 下的 *.bin 采集文件，要确定帧边界/帧长/帧数"
  - "写 SPC865 .bin 读取脚本，不确定每帧多少字节、帧头魔数是什么"
  - "文件字节数不是 2 097 160 的整数倍，或按固定步长读出来数据错位（失败信号）"
  - "SPC865 数据的帧数/总量与仓库文档对不上（失败信号）"
  - "跑批处理前要估算 63 个 .bin 的帧数与数据量"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7de-9a07-7719-ba82-31efaa0ea03c
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [known-angle-holdout-validates-doa-geometry]
---

**主张**：SPC865（TI AWR2944 LVDS）`.bin` 是定长帧格式——每帧 `2 097 160` B = 8 字节帧头（字节序列 `AA 55 TT 00 00 00 55 AA`，`TT` 为 1..4 循环的帧号）+ 4096×256 个 16-bit 采样字（`8 + 4096*256*2`）。因此 **帧数 = 文件字节数 / 2 097 160**：本会话 63 个文件全部无残缺尾帧（`trail=0`），全库 3 816 831 200 B = 1820 帧，帧头同步字节在 1820/1820 帧命中。

**为什么**：帧长固定且无尾帧时，文件大小本身就是一个可机读的帧数断言——不用先解析内容就能算出帧数，也能用「大小 % 2 097 160 == 0」当读取前的完整性闸门；`trail != 0` 则说明读法或文件本身有问题。

**证据（本会话命令 ↔ 结果）**
- 仓库自带 `MatlabSpc865/spc865_field_report.py` 首行注释：`# 帧格式：8 字节帧头 + 4096 x 256`；分析脚本用 `FS = 8 + 4096*256*2` / `FRAME = 2_097_160`。
- 帧头字节 dump：`#### data/20260605/SPC865_OK_2021-12-07-04-10-22_0.bin   frame header bytes: aa 55 01 00 00 00 55 aa`。
- 帧数 = 大小 / 帧长：`41943200 → frame_count 20`、`209716000 → frame_count 100`；扫描记录 `[(41943200, 20, 0), (209716000, 100, 0)]`（第三项 `trail=0`）。
- 全库汇总：`files 63 frames 1820 bytes 3816831200`；报告 §1：`63 .bin files, 3 816 831 200 bytes (3.8168 GB / 3.5547 GiB), 1820 frames`。
- 报告头部：`* Frame header: bytes AA 55 TT 00 00 00 55 AA, sync bytes hold in **1820/1820 frames**`。
- 复现口径：`FRAME = 8 + 4096*256*2`；对每个文件断言 `os.path.getsize(p) % FRAME == 0`，帧数 = `size // FRAME`。

**边界 / 反例**
- `TT` 只有 4 个取值，不能当唯一帧号，且相位不一定从 1 开始——见 `spc865-frame-counter-tt-phase-not-always-1`。
- 本条只覆盖 `*.bin` 采集文件：`MatlabSpc865/data/` 下另有 787 个 CSV 等非 `.bin` 产物，不走此帧格式。
- 4096/256 两维的物理含义（采样维、chirp 维）来自仓库既有脚本与实测 reshape 口径，本会话未独立验证其物理定义。
- 同一次取证里还发现仓库既有 `SPC865_real_adc_data_contract_report.md` 与实测有 10 处出入（报告 §13，`D-rows: 10`），所以「以实测字节为准」而非以该契约文档为准。
