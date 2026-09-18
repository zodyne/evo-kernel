---
id: relative-path-list-breaks-when-cd-away
type: lesson
status: candidate
scope: global
domain: shell
tags: [shell, cwd, relative-path, batch, file-list]
triggers:
  - "把一批文件路径写进 /tmp 清单，再用 `$(cat list)` 展开批量处理（wc/cat/rm/sort）"
  - "命令先 `cd <子目录>` 再展开仓库相对路径清单，报 open: No such file or directory（失败信号）"
  - "清单里的路径明明存在，批量命令却说文件找不到（cwd 与清单基准不一致）"
  - "同一条批量命令在仓库根跑得通、换个 cwd 就整批失败"
  - "要决定清单里存相对路径还是绝对路径，避免 cwd 变化导致批量操作全线失败"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-52eb-73b1-bdd8-c2d41b3df10d
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [backgrounded-cd-and-list-leaves-shell-cwd-unchanged, make-nothing-to-be-done-check-cwd]
---

一句话主张：清单文件里存的是**相对仓库根**的路径时，展开并处理它的命令必须从仓库根（清单的基准目录）执行；先 `cd` 到子目录再用 `$(cat list)`，每个路径会按新的 cwd 重新解析，整批变成 `open: No such file or directory`。

**为什么**：`$(cat list)` 只是把路径字符串原样交给命令，命令相对**当前 cwd** 解析——cwd 一变，清单的基准就失效。错误信息只回显你给的路径（如 `ops/proposals/x.md`），看着像文件真丢了，实际是命令在另一个目录下执行。

**怎么修**：让处理命令与清单基准对齐——在仓库根执行（`cd /path/to/repo && …`），或生成清单时就写绝对路径；需要在子目录操作时把展开放进同一个 `(cd … && …)` 子 shell。

**边界/反例**：清单存绝对路径时不受 cwd 影响；`cat list | xargs` 与 `$(cat list)` 同样按 cwd 解析。与"后台任务里的 `cd` 不作用于同一行的后续命令"是两种不同的 cwd 坑（见 related）。

**证据**（会话 01a0b2ce 切片，命令↔结果）：
- 仓库根生成清单后执行 `cd /Users/zodyne/Dev/evo-kernel/ops/proposals && wc -c $(cat /tmp/evo-triage/batch-2) | sort -n` → `wc: ops/proposals/2026-09-18-embedded-image-sha256-cross-doc-same-figure.md: open: No such file or directory`（此时 cwd=ops/proposals，路径被解析成 ops/proposals/ops/proposals/…）；
- 改回仓库根 `cd /Users/zodyne/Dev/evo-kernel && wc -c $(cat /tmp/evo-triage/batch-2) 2>&1 | tail -5` → 正常列出各提案文件字节数（3329、3716 …）。
