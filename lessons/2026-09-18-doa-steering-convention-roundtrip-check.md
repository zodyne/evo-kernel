---
id: doa-steering-convention-roundtrip-check
type: lesson
status: candidate
scope: global
domain: radar-doa
tags: [doa, steering-vector, 约定, roundtrip, 移植验证]
triggers:
  - "移植/实现 DBF 测角，拿不准导向矢量的符号/阵元序/单位约定"
  - "合成 roundtrip 各角度 err=0，但换一个约定变体仍然通过（失败信号：检查无判别力）"
  - "想快速锁定 steering 约定，不想每次都跑暗箱实测"
  - "约定变体（符号翻转/阵元序/tx 序/单位）扰动后 roundtrip 由 True 变 False（该检查可判别）"
  - "移植后第一次真实数据测角偏了，怀疑约定抄错"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a80b-0e7a-7719-ba82-31f4af5174d2
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [known-angle-holdout-validates-doa-geometry, doa-0deg-corner-unconstraining-cross-beam-consistency, mutation-testing-verifies-tests-catch-bugs]
---

# 用合成 roundtrip + 约定扰动锁定 DBF 测角约定

**主张**：移植/实现 DBF 测角时，先用合成数据做逐角度 roundtrip（按候选 steering 约定注入已知角度 θ，检查谱峰回读到 θ），再对约定变体逐一扰动：只有正确约定 roundtrip 为 True，符号翻转、阵元序错、tx 序错等错误约定全部为 False。该检查能在上真实数据之前把「符号/阵元序/单位」约定锁死。

**证据（本会话合成探针输出）**
- 逐角度 roundtrip：`beam1 d= 32 th=  0.00 rt=True peak=   0.00 err=0.00`（对 th=0、8… 多个角度均 err=0.00）。
- 约定扰动：`normal rt True flipped sign rt False identity rx order rt False identity tx order rt False opposite adv rt False norm di…` —— 正确约定通过，各错误约定全部被 roundtrip 拒绝（探针可判别约定错误）。

**为什么**：单看数值输出「差不多」分不出约定抄错——错误的符号/阵元序往往只在偏轴角度或真实数据上才暴露。合成 roundtrip 先把角度空间扫一遍，约定扰动再显式验证「检查是否有判别力」：如果错误约定也能通过，说明测试没在约束约定，继续上真数据只是浪费。

**边界 / 反例**
- roundtrip 只证明「该实现与注入模型自洽」；物理约定的终局判据仍是已知角度实测/跨波束一致性（见 related：`known-angle-holdout-validates-doa-geometry`、`doa-0deg-corner-unconstraining-cross-beam-consistency`）。
- 探针是 in-beam 合成数据（无噪声、无通道标定误差），不能替代外场/暗箱数据。
- 约定扰动必须逐项做；只跑 normal 一支不能证明检查有判别力。

**失败信号**：错误约定（符号/阵元序/单位翻转）下 roundtrip 仍为 True —— 测试无判别力，先修测试再采信结果。
