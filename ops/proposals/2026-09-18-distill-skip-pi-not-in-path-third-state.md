---
id: distill-skip-pi-not-in-path-third-state
type: lesson
status: candidate
scope: project:evo-kernel
domain: evo-kernel
tags: [evo-distill, PATH, launchd, fail-open, 对账]
triggers:
  - "distill.log 里出现 skip: pi 不在 PATH"
  - "后台/launchd 跑的蒸馏一轮过去队列纹丝不动，日志里既无 done 也无 fail（失败信号）"
  - "对账蒸馏进度时只 grep done 行与 fail 行两种记录"
  - "给 launchd plist / 后台驱动器配 PATH，或排查蒸馏「静默不干活」"
  - "evo-distill 在非交互环境查不到报错，却什么都没蒸"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2f3-86b5-73b1-bdd8-c2dceaa1549e
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [distill-log-done-line-is-the-completion-ledger, launchd-silent-output-disk-only, launchd-log-utc-timezone-trigger-check]
---

**主张**：`distill.log` 里的 `skip: pi 不在 PATH（pi）` 是**第三种终态**——既不是 done 也不是 fail：`evo-distill.sh` 在 `command -v "$PI_BIN"` 失败时只 log 一行 skip 就 `exit 0`（fail-open），该次调用在进入处理循环前就退出了，既不标记会话完成、也不进 fail 重试台账；所以「done = 完成 / fail = 待重试」的二分对账会漏掉它，巡检必须单独 `grep 'skip:'`。

**为什么**：pi 是从 2026-09-18 起 evo-distill 的执行器（脚本内 `PI_BIN="${EVO_DISTILL_PI:-pi}"`），而 launchd/后台环境不继承交互 shell 的 PATH。`com.evo.distill.plist` 的注释把这条写明了：PATH 必须含 pi 所在目录，否则脚本 fail-open 直接退出、日志记 `skip: pi 不在 PATH`。此时队列条目原封不动，没有 done、没有 fail，只有一行 skip——从完成台账看像「从没被处理」，从失败台账看什么都不报（exit 0）。drain 侧还有同形的 `skip: <distill> 不可执行`。

**证据**：
- 切片命令（对 `ops/log/distill.log` 逐个特殊字样计数）→ `[command not found] = 17 [锁路径被非目录占用] = 0 [queue 取列表失败] = 0 [pi 不在 PATH] = 3` —— 该 1008 行的 distill.log 里此字样出现 **3 次**，非零即说明有过整次被静默跳过的蒸馏调用。
- 机制（仓库内可核）：`ops/bin/evo-distill.sh:123` = `command -v "$PI_BIN" >/dev/null 2>&1 || { log "skip: pi 不在 PATH（${PI_BIN}）"; exit 0; }`；`ops/bin/evo-drain.sh:55` 同形跳过；`ops/bin/com.evo.distill.plist` 注释写明 PATH 要求。
- 对照（同脚本）：正常收尾是 `log "done $SID — DISTILL_OK n"`，非零 rc 是 `log "fail ${SID} rc=${RC}（未标记，将重试）见 …out"`——三种记录互斥，只有 skip 不产出任何完成/失败凭证。
- 切片里同一次巡检还看到 fail 记录 `2026-09-18T00:16:13Z fail 01a0a575-… rc=0（未标记，将重试）见 .distill-`，说明 fail 台账本身是有的——skip 恰恰不在这里面。

**边界 / 反例**：
- skip 是**进程级**早退：命中后该次调用一个会话都没蒸，所以「出现 3 次」不等于 3 个会话出问题，可能只是同一次 launchd 触发的多路调用各自跳过。
- 它不代表会话数据坏或 distill 实现坏——先修执行环境（PATH 含 pi 目录，或用 `EVO_DISTILL_PI` 指绝对路径），再谈重跑。
- 该文案是脚本内固定字符串（plist 注释说保留 hermes 时代原文以防 sed 改动引入偏差），grep 用整串 `skip: pi 不在 PATH`，别只 grep `pi`。
- 排查 drain「连续 N 轮零进展退出」时值得先 grep 这个字样——skip 会让整轮零产出（因果关系需按当轮日志自行确认）。

**失败信号**（未来命中即该想起本条）：
- 对账只 grep `done`/`fail`，得出「这些会话从没被处理」，却漏掉 skip 行。
- 后台蒸馏轮次跑完队列纹丝不动，且没有任何 fail 记录。
- 在 launchd/非交互环境里 pi 不可见，巡检却只盯着 proposals 产出数看。
