---
id: gridding-quantization-cap-negative-radial-velocity
type: fact
status: candidate
scope: project:algommw
domain: radar-dsp
tags: [多普勒, 展开速度, DDM, 量化, TDM]
triggers:
  - "DDM/TDM 波形下计算或核对最大不模糊径向速度"
  - "把有符号 Doppler 展开到超过单 PRF 不模糊范围后核对边界值"
  - "比较两波形口径的最大速度，数字对不上又各能自圆其说（失败信号）"
  - "需要先选最小 v 步长再推导 ±v_max 的量纲链"
  - "写文档时凭空写 ±28.81 这类速度边界被复核打回"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af3a-aba2-7097-91f3-80f58c344ace
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: []
---

## 主张

展开多普勒的速度上限由「最小 v 步长 × 可编码 bin 总数」逐级量纲推导，AFM761 DDM(768 chirps/帧) 口径为 **±28.77 m/s**（曾误写 ±28.81）；这个值是整链的量纲锚，不是标称参数——文档里的速度边界必须以推导值为准，且推导口径（以哪一级最小步长起算、含多少 bin）要与实现一致，否则就出现 .81/.77 这类「说不清谁错」的并存版本。

## 为什么

 algommw/AFM761 实例（2026-09-17 会话取证）：config_schema 记录了文档自报 ±28.81 m/s 与推导 ±28.77 m/s 的并存，迁移纪要 §2 按推导口径定值 ±28.77 m/s，并列入「Documented correction batch」。该口径下 DDM bin 是 pre-fold baseband（非速度），有符号真值由 chain 展开输出——边界值只能从「步长→bin 数→速度」的量纲链得出，任何一步口径含糊都会在文档里留下两个都「像是算过的」数。经验面：量纲锚（L0）必须落在可独立复算的推导值上，文档转抄值不具锚资格。

## 反例/边界

- 边界为 project:algommw 局部：数值本身仅适用 AFM761 768-chirp DDM 口径；可迁移的是「步长→bin→边界」推导法与「推导值优先于转抄值」的定值规则。
- 与「步长参数必须派生不得手填」（本仓 config_schema §1 红线，xRangeStep/xDopplerStep 由 eChainInit 推导）同源：量纲链上任何手工填入点都是 .81/.77 类分叉的来源。
- 若未来改 chirp 数/PRF，边界值随之改变，应重新推导而不是改文档数字。

## 证据

session 01a0af3a 纪要 §2「±28.77 m/s」与 §7「Documented correction batch: ±28.81→±28.77」；config_schema `[waveform]`/`[doa]` 段（会话内读取的原文）。
