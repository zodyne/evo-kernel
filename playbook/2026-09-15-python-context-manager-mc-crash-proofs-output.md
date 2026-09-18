---
id: python-context-manager-mc-crash-proofs-output
type: lesson
status: validated
scope: global
domain: python
tags: [python, monte-carlo, contextlib, redirect-stdout, precompute, timing, radar]
triggers:
  - "跑长时蒙特卡洛/批量统计验证脚本,怕中途崩了丢全部输出"
  - "多阶段验证脚本后面阶段抛异常,看不到前面阶段已算出的结果"
  - "长脚本要留运行证据,又要限时跑完(macOS 无 timeout 命令)"
  - "蒙特卡洛轮数上量级后单次运行要十几分钟,想压缩时长"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a5ef-b7d0-777c-a410-325dae81e5ed
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: []
---

# 长 MC 脚本用 redirect_stdout 收集输出 + try/except 兜底打印,崩了不丢已完成阶段的证据

## 主张
长时蒙特卡洛/批量验证脚本把各阶段输出收集进 `io.StringIO`(`with contextlib.redirect_stdout(buf):`),整体套 try/except,异常时 `traceback.print_exc()` 后仍 `print(buf.getvalue())` 再退出——中途崩溃不丢已完成阶段的结果,免于整轮重跑;配合把循环内重复的重活预计算/缓存,轮数上量级后时长可压一个数量级。

## 为什么
2026-09-15 会话实测:多阶段统计验证脚本在后续阶段抛异常退出,但兜底逻辑仍完整打出前面阶段结果(`checks=60 pass=60`),证据零丢失、无需重算。性能侧实测:不缓存走全链信号合成 synth_beat+add_noise+range_doppler ≈ 0.0711 s/帧 → 2000 trials × 4 帧 ≈ 569 s;把每帧重复的 noise+2D-FFT 预计算后 5.6 ms/帧 → 22 ms/trial → 2000 trials ≈ 44.9 s。macOS 无 `timeout` 命令,靠脚本自身轻量化+限时结构兜底(切片中 `timeout: command not found` 实证)。

## 边界 / 反例
- 只适合"收集后统一打印"的场景;要实时看进度仍需直接 print,或用同时写终端与缓冲的 tee 式对象。
- StringIO 全量驻留内存,超长输出(逐 trial 打印)会放大内存占用,聚合统计后打印为宜。
- 预计算要掂量内存:缓存的是循环内不变的中间量(本例噪声+2D-FFT 路径),不是把全部 trial 数据预生成。

## 证据(2026-09-15 会话命令对照)
- 切片命令输出:`checks=60 pass=60`(异常兜底下仍产出完整阶段结果)。
- 切片 timing 输出:`synth_beat(rmc)=0.0528s add_noise+range_doppler=0.0183s per-frame total=0.0711s => 2000 trials x 4 frames ~= 569.0 s` vs `noise+2D-FFT per frame: 5.6 ms -> per trial (4 frames) 22 ms -> 2000 trials 44.9 s`。
- 切片命令输出:`/bin/bash: timeout: command not found`。
