---
id: vitest-full-suite-fail-isolate-rerun
type: lesson
status: candidate
scope: global
domain: testing
tags: [vitest, npm-test, flaky, hermes-tui, isolation, daemon]
triggers:
  - "npm test 全量跑报某个测试文件 FAIL，准备据此去改代码"
  - "改动与失败用例毫不相关，但全量套件一直红（失败信号）"
  - "判断一次测试失败是真回归还是套件内串扰"
  - "在 Hermes ui-tui 仓库跑 npm test 看到 execFileNoThrow / daemon 相关用例失败"
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:1363c097-a1c9-4248-a903-814a33facb13
last_verified: 2026-08-13
superseded_by: null
schema_version: 1
related: [untested-tool-config-bugs-stay-invisible]
---
# 全量套件红 ≠ 真回归：先单文件复跑同一个测试再决定改不改代码

## 主张
`npm test` 全量跑报出的失败，可能只是套件内并发/环境串扰造成的**假红**。
判定动作是**用同一个 runner 单独复跑那一个文件**：`npx vitest run <该测试文件>`。
本次全量报 `FAIL packages/hermes-ink/src/utils/execFileNoThrow.test.ts > execFileNoThrow with daemo...`，
单独复跑 `Test Files 1 passed (1) / Tests 4 passed | 1 skipped (5)` —— 说明该失败与本次改动无关，
**不要为它改产品代码**，也不要把它当作"改坏了"的证据。

## 为什么
带子进程/daemon 的用例对并发、端口、临时目录、环境变量敏感；全量跑时的相互干扰会让失败挂在
一个跟当前改动毫不相干的文件上。此时如果不做隔离复跑，会误判为回归，进而改动无关代码（真正的坏结果：
引入新问题 + 掩盖真实基线）。反过来也成立：单跑绿不代表全量绿，全量红要留档为已知不稳定项。

## 证据（本会话命令对照）
- 第一次全量：`cd ~/.hermes/hermes-agent/ui-tui && npm test 2>&1 | grep -E "Test Files|Tests |FAIL"`
  → `⎯⎯ Failed Tests 1 ⎯⎯  FAIL  packages/hermes-ink/src/utils/execFileNoThrow.test.ts > execFileNoThrow with daemo...`
- 隔离复跑：`npx vitest run packages/hermes-ink/src/utils/execFileNoThrow.test.ts`
  → `Test Files  1 passed (1)` / `Tests  4 passed | 1 skipped (5)`
- 后续再次全量（另一轮改动后）仍是同一个文件 FAIL —— 稳定复现的"全量红/单跑绿"，指向串扰而非本次改动。
- 同期 `npm run build` 均通过（`dist/entry.js 3.5mb / Done in 62~92ms`），进一步说明不是编译级破坏。

## 边界 / 反例
- 本会话**没有定位到串扰的具体来源**（未做 `--no-threads` / `--sequence.concurrent=false` 等对照），
  所以只支持"隔离复跑再判定"这一动作，不支持"这个文件永远可以忽略"。
- 单跑绿也可能掩盖真实的并发缺陷（若被测对象本身就要求并发安全）；结论应写成"疑似套件串扰，待查"，而不是"没问题"。
- `grep -E "Test Files|Tests|FAIL|✗|×"` 这类过滤会把摘要行滤掉导致看不到结论，确认失败范围时留足输出。

## 失败信号（未来命中即该想起本条）
- 全量红的文件与本次 diff 完全无交集。
- 失败用例名里带 daemon / spawn / exec / port 等子进程语义。
