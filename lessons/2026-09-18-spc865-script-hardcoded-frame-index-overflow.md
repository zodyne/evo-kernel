---
id: spc865-script-hardcoded-frame-index-overflow
type: lesson
status: candidate
scope: project:spc865
domain: radar-data-format
tags: [spc865, awr2944, matlab, 帧数, 硬编码, 索引越界, getrawdataadc]
triggers:
  - "拿 SPC865 的 MATLAB 脚本（awr294x_spc865_v1.m）处理一份新的 .bin 采集件，脚本里帧循环上界是写死的"
  - "跑 SPC865 MATLAB 脚本报索引越界 / filetable 下标超界（失败信号）"
  - "采集件的帧数比脚本里硬编码的值少（脚本写 20，文件实际只有 10 帧）"
  - "getRawDataAdc 里 `fileIndex = ceil(帧号/每文件帧数)` 算出的下标超出 filetable 长度（失败信号）"
  - "要把新采集件接进 SPC865 处理链路，先核对文件帧数与脚本常量是否匹配"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a819-cfaa-7485-9b7c-35a2cf425d94
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [hardcoded-data-dir-rot-fails-late, spc865-bin-frame-layout-verified]
---

**主张**：`awr294x_spc865_v1.m` 把帧循环上界写死成 `for i = 20`，遇到帧数不同的采集件就炸——本次的 .bin 只有 10 帧，第 20 帧根本不存在，`getRawDataAdc` 会算出 `fileIndex = ceil(20/10) = 2`，而 filetable 里只有 1 个文件 → 直接索引越界。跑新采集件前必须先按其字节数算帧数，不能假定脚本里的常量成立。

## 为什么

这类厂商/实验室 .m 脚本的帧数常量是**按当时那份采集件写死的**（本例 20 帧），与数据本身没有绑定关系；同一台雷达不同长度的采集件（本文件 20,971,600 B = 10 × 2,097,160 B/帧）会让常量失效。失效点还不在循环头，而是在 `getRawDataAdc` 内部的文件索引换算（`ceil(i/每文件帧数)`），报错现场离真正的错误假设（帧数）很远。

本会话实证：
- Python 直接解析该文件：`frames 10`（同次输出还有 `frame 0 hdr ['0x55aa','0x1','0x0','0xaa55']`、`runs(beam,len): [(2, 64), (3, 64), (1, 128)]`）。
- 末条 assistant（同切片）：帧数 10 来自 `20,971,600 B ÷ 2,097,160 B/帧 = 10.0`；脚本硬编码 `for i = 20`；`fileIndex = ceil(20/10) = 2` 撞上只有 1 个文件的 filetable，报索引越界；改成 `for i = 1` 后跑通。
- 写/改文件记录：`/Users/zodyne/Dev/SPC865/awr294x_spc865_v1.m`。

## 怎么做

1. 跑之前先量：`frames = 文件字节数 / 每帧字节数`（本机每帧 2,097,160 B），把它和脚本里的循环上界对齐；不一致就改上界（或改成由文件推导）。
2. 更稳的做法：帧数做成函数入参/由 `dir()` 出的文件列表推导，并在 `getRawDataAdc` 里对 `fileIndex > numel(filetable)` 显式报"帧数超出该文件表覆盖范围"，而不是让它自然越界。
3. 复用同一脚本处理多个采集件时，把"每文件帧数/总帧数"当配置而不是常量——这与 `hardcoded-data-dir-rot-fails-late` 是同一类腐烂。

## 边界

- 本证据只覆盖这一份 10 帧采集件 + 该脚本当时的 `for i = 20`；其他 .m（batch_865_1.m 等）可能有各自的硬编码常量，需各自核对。
- 只把上界改成 `for i = 1` 只是让本次跑通；换成另一份帧数不同的采集件仍会犯同样的错。
- 帧长/帧数口径的独立证据见 `spc865-bin-frame-layout-verified`。
