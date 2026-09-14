---
id: redirect-masks-per-scenario-exit-code
type: lesson
status: candidate
scope: global
domain: shell
tags: [exit-code, redirect, measurement, bash, verification]
triggers:
  - "写一段脚本连跑多个场景（A/B/C 布局、有无某文件）验证命令在哪种情形下通过"
  - "把被测命令输出重定向进 /tmp 日志或串进管道后再判成败"
  - "多场景实验输出糊在一起，分不清究竟哪个场景失败（失败信号）"
  - "评审/验收结论要建立在退出码上，需要每个场景一个确定的 exit 值"
created: 2026-08-26
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:82468b1c-204f-4d81-9cc1-7bcb97697158
last_verified: 2026-08-26
superseded_by: null
schema_version: 1
related: [diff-in-and-chain-exit-1-masks-success, brew-services-start-not-equal-port-listening]
---
一句话主张：用一段多场景脚本验证"哪种布局能通过"时，把被测命令接进管道或重定向后就拿不到各场景真实退出码，据此下的结论不可信；必须每个场景单独跑并显式打印 `exit=$?`，再重测一轮。

为什么：管道/重定向改变了可见的成败信号（整链退出码归属最后一个命令、被测命令的失败被日志吞掉），多场景连跑时还会把不同场景的输出混在一起。本会话评审员先跑了两轮场景脚本，随后自己判定 `The pipeline masked the real exit codes`，改为"精确测量"重跑——即多做了一轮返工才拿到可用判据。

边界与证据（本条只有评审员的判断，未做对照实验，故 verified_by: human）：
- 切片第 5、6 条命令是两个场景脚本（`Scenario 1` 根级测试文件 + 空 `tests/`；`Scenario 2` 测试文件放进 `tests/`），输出含被截断的 traceback，未给出可归属场景的退出码。
- 末条 assistant 原话：`The pipeline masked the real exit codes. Let me measure precisely and pin down the exact layout requirements for this Python version.`
- 重测一轮的形态是逐场景显式打印：`echo "=== A: empty tests/ (no __init__.py) ==="` → 结果行出现 `exit=1`（间接佐证"显式打印退出码"才拿到判据）。
- 未验证：管道掩盖退出码的具体位置（是 `>` 重定向、`|` 还是 heredoc 组合）在切片中被截断，不作断言；引用本条时把它当"测量方法纪律"，不要当机制解释。
