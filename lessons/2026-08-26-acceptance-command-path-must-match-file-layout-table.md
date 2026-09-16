---
id: acceptance-command-path-must-match-file-layout-table
type: lesson
status: candidate
scope: global
domain: design-review
tags: [acceptance-criteria, test-layout, unittest, plan-review]
triggers:
  - "评审一份同时给出「文件清单表」和「验收命令」的实现方案"
  - "验收命令写 python3 -m unittest discover -s tests -t .，方案文件表却把 test_*.py 列在仓库根"
  - "测试文件按方案清单写齐了，验收命令仍 exit=1 或一个测试都没收集到（失败信号）"
  - "给 worker 下发任务时同时规定目录布局与验收命令，评审前要判方案是否自洽"
created: 2026-08-26
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:82468b1c-204f-4d81-9cc1-7bcb97697158
last_verified: 2026-08-26
superseded_by: null
schema_version: 1
related: [unittest-discover-needs-importable-start-dir, design-review-cross-check-implementation]
---
一句话主张：设计评审时必须把方案的「文件清单表里的测试文件路径」与「验收命令隐含的搜索路径」当成两条独立规约交叉核对——两者不一致时方案自身就不自洽，实现方照清单写完，验收命令仍以非零码失败。

为什么：验收命令 `python3 -m unittest discover -s tests -t . -p 'test_*.py'` 把 `tests` 作为 start dir，测试文件放在仓库根时 `tests/` 是空目录；本会话实测该场景退出码 `exit=1`（非"收集 0 个测试"的软通过）。方案文本读起来两部分各自合理，矛盾只在把布局落地后跑一次验收命令才暴露，所以评审不能只读文本、要在临时目录做最小复现。

边界与证据（均来自本会话切片的命令 ↔ 结果，评审阶段无写文件动作）：
- 首条 user 给出的验收命令为仓库根跑 `python3 -m unittest discover -s tests -t . -p 'test_*.py'`。
- 评审员在 `/tmp/revcheck` 造最小复现，命令注释明写 `Scenario 1: test files at REPO ROOT (as plan.md's file table lists), tests/` ——即方案 plan.md 的文件表把测试文件列在仓库根，与验收命令的 `-s tests` 冲突。
- 精确重测一轮：`python3 --version` → `Python 3.14.6`；`=== A: empty tests/ (no __init__.py) ===` 分支 `python3 -m unittest discover -s tests -t . -p 'test_*.py' -v` → `exit=1`，并抛出 traceback（异常类型文本被切片截断，未记入本条主张）。
- 本条只主张"不一致 → 验收失败，评审须交叉核对并实测"；失败的具体机理（start dir 是否需可 import）见 related 的 `unittest-discover-needs-importable-start-dir`，不在本条证据范围内。
