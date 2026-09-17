---
id: write-cli-must-not-probe-with-help-flag
type: lesson
status: validated
scope: global
domain: cli-usage
tags: [cli, help-flag, argument-parsing, evo-capture, probing]
triggers:
  - "对不熟悉的 CLI 用 --help 探测，结果被当作实参消费"
  - "写类命令（如 evo capture）把字面量 --help 写进产物"
  - "已经打印出命令签名却跳过它另试探测方式"
  - "CLI 位置参数命令误用 --foo 探测导致落盘垃圾（失败信号）"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-14-07-14-55-542-r68r
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: []
---

# 对不熟悉的 CLI：先读 help 里的签名；"写"类命令不得用 --help 探测

## 主张

evo capture 是位置参数命令，"capture --help" 不打印帮助而是把字面量 "--help" 当真值写进 inbox（零判断，直接落盘为一条经验条目，已手动清除）。同类错误当日第三次，形态一致：我上一秒刚跑出 evo --help（其命令面明写 capture "text" 一句话入 inbox），看着证据却没读，仍用 --help 去探测。

## 规则

对不熟悉的 CLI，先读父命令 help 中给出的签名再决定探测方式；"写"类命令不得用 --help/--foo 探测（会被当作实参消费）；已打印的证据必须读，不要跳过它去另试。
