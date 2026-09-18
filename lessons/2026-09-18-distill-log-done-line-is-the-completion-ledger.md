---
id: distill-log-done-line-is-the-completion-ledger
type: lesson
status: candidate
scope: project:evo-kernel
domain: evo-kernel
tags: [evo-distill, distill-log, 对账, distill]
triggers:
  - "判断某会话是否已被后台蒸馏处理完"
  - "evo-distill 蒸馏完成状态的权威对账源"
  - "tail distill.log 找 done 记录"
  - "蒸馏飞轮跑完但不确定结果落没落账（失败信号）"
  - "想拿队列或 .out 文件当完成凭证"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af9e-b3c1-764c-a77e-5180607e51ae
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [evo-distill-transient-connection-error-retry]
---
**主张**：evo-distill 后台蒸馏的完成状态，权威对账源是 `ops/log/distill.log` 里的 `done <session_id> — DISTILL_OK <n>` 行；判断某会话是否蒸馏完成应 grep 该行，而不是看队列或 .out 文件。

**为什么**：后台 Reflector 链路是异步多进程的，回答「evo 会话是否完成了蒸馏」这类问题时，需要一个 append-only 的落地台账；distill.log 的 `done` 行由驱动脚本在蒸馏收尾时写入，同时带 `DISTILL_OK <提案数>` 结果，是唯一同时含「会话 id + 完成态 + 产出数」的记录。

**边界/反例**：
- `bin/evo queue` 只列待处理队列（sid + transcript 路径），行数 135 也不区分已完成/待处理/失败，不能当完成凭证；
- `ops/log/.distill-<sid>.out` 是单次运行原始输出，进程还在跑时内容未定，且 rc=0 不代表已标成功；
- `done` 行的 `DISTILL_OK 0` 表示蒸馏跑完但零提案产出（被查重跳过属正常），不是失败；
- **第三种终态 `skip:`**（2026-09-18 补）：`evo-distill.sh` 在 `command -v "$PI_BIN"` 失败时只 log 一行 `skip: pi 不在 PATH（pi）` 就 `exit 0`（fail-open），该次调用在进入处理循环前退出，既不标记会话完成、也不进 fail 重试台账。launchd/后台环境不继承交互 shell 的 PATH，`com.evo.distill.plist` 注释要求 PATH 含 pi 所在目录（或用 `EVO_DISTILL_PI` 指绝对路径）；drain 侧有同形的 `skip: <distill> 不可执行`。所以「done = 完成 / fail = 待重试」的二分对账会漏掉它（表现为「这些会话从没被处理」），巡检必须单独 grep 整串 `skip: pi 不在 PATH`，别只 grep `pi`。

**证据**：2026-09-17 会话切片：`tail -40 ops/log/distill.log` 输出含 `2026-09-17T08:05:46Z done 01a09f4d-d062-7129-be3e-248fe1a2a683 — DISTILL_OK 0` 等多行；同会话 `./bin/evo queue | wc -l` = 135、`queue` 输出仅 sid+路径两列，佐证队列无状态列。
