---
id: fft-memcmp-self-consistency-no-golden-binding
type: lesson
status: candidate
scope: global
domain: testing
tags: [fft, test-gate, discriminative-power, golden, algommw]
triggers:
  - "审查/编写 FFT 或查表类回归测试，看到 memcmp 比对两条内部路径（查表 vs 现算）"
  - "想判断单元测试的『参照』是独立 golden 还是同库第二条代码路径"
  - "表/查找表内容与输出之间没有任何 golden 绑定断言（失败信号）"
  - "改坏算法实现（如 plan 尺寸守卫）后回归测试仍然全绿（失败信号）"
  - "评估测试闸门判别力：memcmp 到底验了正确性还是只验了两路径自洽"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a6aa-b9c7-7353-8a3d-42e33b11ac8b
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [dual-impl-cross-check-tolerance-grid-anchored, mutation-testing-verifies-tests-catch-bugs]
---

一句话主张：单元测试用 memcmp 比对同一代码库内两条路径（FFT 查表 vs 现算）当正确性闸门，只证明两条路径输出一致、不证明正确性——「现算」路径被注释标为「参照路径」（pxRef）却是同库第二条代码路径而非独立 golden，表内容与输出之间没有任何 golden 绑定断言；两条路径共享底层实现时，共因缺陷会双双通过、测试仍绿。

为什么：`tests/unit/test_fft_mixed.c` 的 memcmp 在同一输入上比对「表路径 vs 现算路径」，把现算结果当参照；但表（预计算 twiddle 查表）与现算（实时计算 twiddle）都在同一个 `core/src/math/fft.c` 里，共享同一 radix 内核、归一化、输入准备，只在 twiddle 来源上分叉——二者天然共因。表内容一旦写错、或两路径共享的底层逻辑错了，两条路径一起错，memcmp 依然相等，测试判别力归零。全仓仅 core/ 与 test_fft_mixed.c 触碰 FftPlan 相关结构，进一步印证「参照」与「被测」是同一实现的两个分支，不是独立实现。

边界/反例：不是所有两路径比对都没用——若「现算」是数学上独立的第二实现（MATLAB 参考移植、从零重写且独立到假设层），则构成有效对拍（见 dual-impl-cross-check-tolerance-grid-anchored）。判别标准是「参照是否独立 golden」，不是「有没有第二条路径」。

证据：对抗式验证者在 /tmp 拷贝仓库、变异 `core/src/math/fft.c` 的 plan 尺寸守卫后重建（BUILD_OK）并跑 ctest，测试仍全绿——该守卫缺陷未被测试捕获，佐证闸门判别力不足。`test_fft_mixed.c:124-141` 行号逐字核对，memcmp 只比对同一输入的两条路径，且无 golden 绑定断言。
