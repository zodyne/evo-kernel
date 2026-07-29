---
id: benchmark-traffic-isolated-from-telemetry
type: lesson
status: validated
scope: global
domain: evaluation
tags: [benchmark, telemetry, isolation, measurement, recall]
triggers:
  - "给检索/记忆/注入系统写基准或评测脚本"
  - "基准查询会经过与真实流量相同的日志通道（失败信号）"
  - "精度/召回指标莫名变好，分不清是系统改进还是测量污染"
  - "评测脚本直接对生产数据目录跑，没有 fixture 副本"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: test
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [injection-precision-must-split-recall-vs-adoption, self-registration-hook-self-pollution-loop]
---

# 基准流量必须与真实遥测隔离：否则评测污染自己的度量口径

## 主张

给"自记录"系统（检索/记忆/RAG，查询本身会写日志）跑基准时，基准必须打在 fixture 副本上、用独立日志；并加一条 smoke 断言"基准跑完，真实遥测日志行数不变"。否则基准查询混入真实遥测，后续精度/采纳率统计被自己的测量流量虚增或稀释，指标失去判读性。

## 为什么

evo-kernel 的检索基准（test/retrieval-bench）若直接对真库跑，每条基准查询都会落进 recall.jsonl——这正是 M1 召回精度/采纳率的数据源，测量行为会污染被测指标。基准因此自带 fixture（`fixture/playbook` + `fixture/ops/log`）并以 smoke 守护：`✓ M: 基准不污染 recall.jsonl（测量与被测数据隔离）`。同一手法也用于 pi-mcp 验收：调用 pi_run 前后 recall.jsonl/session-refs.jsonl 行数不变（179→179、82→82），证明包装层无副作用泄漏。

## 反例/边界

- 只读型基准（被测系统不写任何日志）无需隔离，先确认系统是否"自记录"。
- fixture 要定期从真库刷新，否则基准分布与真实分布漂移，通过率高也无代表性。
- 隔离断言要测"行数不变"而不只是"没报错"——写入失败和根本没写是两回事。

## 证据

- 测试：smoke 组 M `✓ M: 检索基准四阶段可跑`、`✓ M: 基准不污染 recall.jsonl（测量与被测数据隔离）`，全量 PASS=92 FAIL=0；pi-mcp `test/isolation-check.js` 输出"调用前: recall.jsonl=179 … 调用后: 179 ✓ 未被污染"。
