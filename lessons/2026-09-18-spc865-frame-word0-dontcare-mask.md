---
id: spc865-frame-word0-dontcare-mask
type: fact
status: candidate
scope: project:spc865
domain: radar-data-format
tags: [spc865, bin, flag-decode, bit-mask, chirp, beam]
triggers:
  - "解析 SPC865 每 chirp 的 w0 标志字，要把 0x1115/0x2226/0x3337 这类取值归类"
  - "按 w0 精确值（0x1111/0x2222/0x3333）做查表/分组，大量 chirp 落不进任何一类（失败信号）"
  - "统计 SPC865 一个波束的 chirp 数，总和对不上每帧 256（失败信号）"
  - "要判定 w0 里哪些 bit 是标识位、哪些是 don't-care"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7de-9a07-7719-ba82-31efaa0ea03c
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

**主张**：SPC865 每 chirp 的标志字 `w0` 里，bit2(0x4)/bit3(0x8) 是 don't-care；用掩码归一到三类（`0x1111` / `0x2222` / `0x3333`）的规则对 **63/63 文件**成立：`w0 & 0xFFFB`（只清 bit2）与 `w0 & 0xFFF3`（清 bit2+bit3）都通过。按精确值匹配会把 `0x1115`/`0x2226`/`0x3337` 这类 chirp 漏掉——本会话实测一帧 256 个 chirp 里有 130 个带这类低位变体，占约一半。

**为什么**：这 3 类模式对应帧内按波束（Rx/beam）分段的 chirp 组；低位是采集侧的变体位，不参与分类。先掩码再分组，才能让每类 chirp 计数与 256 对齐；否则一个波束会被拆成「带变体」和「不带变体」两堆，分段统计和后续按 beam 的相干处理都会错。

**证据（本会话命令 ↔ 结果）**
- 掩码实验：`0x3333 & 0xFFFB = 0x3333`、`0x3337 & 0xFFFB = 0x3333`、`0x3333 & 0xFFF3 = 0x3333`、`0x3337 & 0xFFF3 = 0x3333`、`0x1115 & 0xFFFB = 0x…`。
- 全库规则：`== rules ==   w0 & 0xFFFB -> 1111/2222/3333      63/63 files pass   w0 & 0xFFF3 -> 1111/2222/3333      63/63 files pass`。
- 一帧 w0 直方图：`frame 0 w0 hist: {'0x1111': 66, '0x1115': 62, '0x2222': 28, '0x2226': 36, '0x3333': 32, '0x3337': 32}`（合计 256 = 每帧 chirp 数；其中 130 个带低位变体）。
- 另一文件前 4 帧：`first_hist: {'0x1111': 512, '0x2222': 256, '0x3333': 256}`（合计 1024）。
- 按类分出的 chirp run 形态：`run pattern : {'0': 'b1@0+128|b2@128+64|b3@192+64', ...}`、`32  b3@0+64|b1@64+128|b2@192+64`。
- 报告把该规则写成结论段：`## 0. VERDICT — the decoding rule that is correct for all 63 files`。
- 复现口径：对每个文件的全部帧取 w0，断言 `set(w0 & 0xFFFB) ⊆ {0x1111,0x2222,0x3333}`。

**边界 / 反例**
- 只证明「掩掉 bit2/bit3 后可归一」，**没有**确定这两个 bit 的语义：报告 §15 Explicit unknowns 第一条就是 `What the don't-care bits mean`。
- 三类模式与具体波束/Rx 的映射本会话未在切片中定案（`beam_of` 输出被截断），引用时不要把「哪一类=哪个波束」说死。
- `0xFFFB` 与 `0xFFF3` 都是经验掩码，只证到 63 个文件的取值域；换批次采集时应重跑这条全库断言再采信。
