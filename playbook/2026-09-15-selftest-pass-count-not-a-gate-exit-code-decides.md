---
id: selftest-pass-count-not-a-gate-exit-code-decides
type: lesson
status: validated
scope: global
domain: testing
tags: [selftest, exit-code, pass-fail, regression, verification]
triggers:
  - "跑带 [PASS]/[FAIL] 自检的批验脚本后要汇报结论"
  - "PASS 计数很大（如 53）就想宣布全绿"
  - "自检脚本退出码非 0 但日志里 PASS 行很多（失败信号）"
  - "给 run_demo/回归脚本设计汇总判定（退出码由任一 FAIL 决定）"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a525-f867-777c-a410-32542dd1bef4
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [vitest-full-suite-fail-isolate-rerun, diagnose-by-measured-output-not-proxy-status-word]
---

# 自检脚本的通过与否看退出码/显式 grep FAIL，PASS 计数不是门禁

## 主张

带 `[PASS]/[FAIL]` 自检行的批验脚本，「是否通过」以进程退出码（或对日志显式 grep FAIL）为准；PASS 计数大不代表全绿，单看计数会把混在其中的 FAIL 读丢。

## 为什么

PASS 行数是汇总性代理指标：一条 FAIL 可以藏在几十条 PASS 中间且位置靠前，计数视角天然偏向「看起来大部分通过」。退出码把判定收敛成一个布尔值（脚本作者须实现「任一 FAIL → exit 非 0」的汇总），与计数互相独立，两条都查才不会误报通过。

## 边界

- 该模式依赖脚本自身把退出码写对；脚本若不设 exit code（默认 0），计数与退出码都不可靠，须先审脚本的汇总逻辑。
- 区分于 vitest 全量套件单文件 FAIL（related）：那条管「失败是否真实回归还是套件串扰」，本条管「如何读取自检结果的总体判定」。

## 证据（命令 ↔ 结果，本会话切片）

- `python3 bpm_2t8r_sim/run_demo.py > /tmp/demo.log 2>&1; echo "exit=$?"; grep -c "\[PASS\]" /tmp/demo.log; grep -c "\[FAIL\]" /tmp/demo.log` → `exit=1`、PASS 计数 53、FAIL 计数 1（FAIL 在 log 第 178 行）。
- 若只汇报「53 条 PASS」会误判通过；exit=1 揭示存在 FAIL，随后定位到具体 FAIL 行核验。
