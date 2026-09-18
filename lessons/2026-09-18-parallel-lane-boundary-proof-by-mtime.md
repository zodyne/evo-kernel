---
id: parallel-lane-boundary-proof-by-mtime
type: lesson
status: candidate
scope: global
domain: workflow
tags: [multi-lane, mtime, 交付证据, 越界, 并行开发]
triggers:
  - "多车道/多 agent 并行改同一仓库，交付时要证明没动别人模块"
  - "被要求给出『未触碰其他 lane 文件』的可复核证据"
  - "交付报告声明只改了 X 文件，需要现场证据支撑"
  - "收尾自查是否越界修改（目标模块 mtime 晚于本车道开工时间 = 失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a80b-0e7a-7719-ba82-31f4af5174d2
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# 并行车道交付：用 mtime 清单自证没越界改别人模块

**主张**：多个车道/agent 并行改同一仓库时，收尾跑一条 mtime 清单命令（本车道文件 + 相邻模块），把「本车道只新建/改了哪些文件、其他模块 mtime 早于本车道开工」写进交付报告，作为未越界的可复核证据。本会话只新建 `spc865/doa.py`（348 行）与 `tests/python/test_doa.py`（419 行），并报告 `config.py` 10:27 / `io.py` 10:23 / `dsp.py` 10:20 的 mtime 早于本车道开工（会话时间戳 2026-09-16T02-28-12Z）。

**证据（本会话命令 ↔ 结果）**
- 命令：`ls -la --time-style=full-iso spc865/*.py 2>/dev/null || ls -lT spc865/*.py tests/python/*.py; echo; wc -l spc865/doa.py`（macOS 上走 `ls -lT` 分支）→ 输出逐文件本地 mtime：`… 1028 Sep 16 10:17:26 2026 spc865/__init__.py … 21233 Sep 16 10:…`。
- 写/改文件清单只有 `spc865/doa.py`、`tests/python/test_doa.py`（末条汇报均标为新建）。
- 末条 assistant 汇报：「未触碰 config.py / io.py / dsp.py（mtime 仍为 10:27 / 10:23 / 10:20，早于本次开工）」。

**为什么**：并行车道最典型的交付事故是 A 车道顺手改了 B 车道的文件；在有未提交改动的脏工作区里 `git status` 只能看出「有改动」，分不清归属，而 mtime 相对开工时间能给出快速、可复核的边界证据（配合写/改文件清单）。

**边界 / 反例**
- mtime 是佐证不是铁证：`touch`/复制可伪造时间戳，同一秒内并发写入可能混淆；高保证场景应加 `git status --porcelain` / `git diff --stat` 与内容抽查。
- 只对「本车道本就不该触碰」的模块有意义；若本车道确实要动某文件，其 mtime 晚于开工是正常的。
- 命令要带 BSD 兼容回退（`|| ls -lT`），否则在 macOS 上 `--time-style` 失败被 `2>/dev/null` 吞掉后可能得到空输出。

**失败信号**：交付报告声称未越界，但列出的目标模块 mtime 晚于本车道开工时间，或写/改文件清单里出现未被授权的文件。
