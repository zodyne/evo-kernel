---
id: verdict-json-reload-validate-before-verdict
type: lesson
status: candidate
scope: global
domain: review-automation
tags: [verdict, json, machine-readable, review-loop, validation]
triggers:
  - "评审/审计结论落盘成机器可读 JSON（verdict.json）驱动后续循环"
  - "写完 findings/verdict 的 JSON 文件后，下游要读它做 approve/reject 分支"
  - "手写 JSON 落盘后直接宣告结论，没有回读校验（失败信号）"
  - "verdict 字段与 findings 里的 blocking 计数可能不一致"
created: 2026-08-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:pi-design-review.t-002
last_verified: 2026-08-11
superseded_by: null
schema_version: 1
---
# 机器可读 verdict JSON：落盘后必须 json.load 回读校验 + 统计 blocking 数再定结论

## 主张

评审结论写成机器可读文件（如 verdict.json，格式 `{findings:[{severity,file,msg}],verdict}`）后、对外宣告结论前，用 `python3 -c json.load` 回读该校验两件事：① JSON 语法合法；② verdict 字段与 findings 统计一致（如「零 blocking 才许 approve」的规则要程序化核对）。下游 loop 按这个文件做分支决策，格式漂移或 verdict 与内容口径不一会静默破坏流程。

## 证据

pi-design-review.t-002 两轮评审均在写完 verdict.json 后回读校验：

- round-0：`python3 -c "import json; d=json.load(...)"` 输出 `valid JSON | 8 findings | 2 blocking | verdict: reject`
- round-1：同一校验输出 `valid JSON | 4 findings | 0 blocking | verdict: approve`

两轮 verdict 字段都与 blocking 计数规则（0 blocking 才 approve）程序化一致后才进入下一步。

## 反例/边界

- 校验开销极小（一条 one-liner），不校验的代价是 loop 拿着坏 JSON 或自相矛盾的 verdict 继续跑，错误放大到下一轮才发现。
- 只解决「文件合法且自洽」，不解决 findings 本身判得对不对——那是评审质量问题，不在此条范围。
