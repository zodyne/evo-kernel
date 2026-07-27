---
id: evo-distill-flywheel-launchd-off-switch
type: lesson
status: candidate
scope: project:evo-kernel
domain: ops
tags: [evo-kernel, distill, launchd, flywheel, automation, background-job, flock]
triggers:
  - "给 Evo-Kernel 加后台 / 定时 / launchd 自动化任务"
  - "配置 launchd plist 定时触发 evo（com.evo.distill 之类）"
  - "蒸馏飞轮不运行 / 不触发 / 队列堆积不消化，排查"
  - "想临时暂停或永久关停后台蒸馏（失败信号 / 运维信号）"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:d2f8d5b2-2b60-4913-958b-59d2f937ed95
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# Evo-Kernel 后台蒸馏飞轮 = launchd 定时触发 trigger.sh + 单会话 distill.sh 两层；用 .distill-off 文件做总开关、.distill.lock 防并发

## 主张
Evo-Kernel 的自动蒸馏飞轮是**两层脚本 + 文件开关 + 文件锁**的组合，不是单一守护进程：
- **调度层** `ops/bin/evo-distill-trigger.sh`：由 launchd（`ops/bin/com.evo.distill.plist`）定时拉起，负责 detach 起一个 driver 遍历蒸馏队列；
- **执行层** `ops/bin/evo-distill.sh`：driver 对队列里每个会话调用它，一次处理一个 session（`--session <id>`），产出 `DISTILL_OK <n>`；
- **总开关**：`ops/log/.distill-off` 文件**存在**即代表"关停"——trigger 检测到它就**立即返回、不干活**（无需卸载 plist、无需改代码）；
- **并发锁**：`ops/log/.distill.lock`（目录锁）防止多个 trigger/driver 实例同时跑。

## 为什么
后台自动化最怕"想停停不下来""起多个实例互相踩"。用文件存在与否当开关（`.distill-off`），停飞轮只需 `touch ops/log/.distill-off`、恢复只需 `rm`，比 unload launchd 或改 plist 轻得多，且 trigger 每次都自查开关、即时生效。目录锁防并发则是 detach driver 时避免"launchd 上一轮还没跑完下一轮又起"的经典竞态。两层分离（调度 vs 执行）还让单会话蒸馏能被人工 `evo-distill.sh --session <id>` 单独重跑，便于排障。

## 证据（本会话命令 ↔ 结果，切片硬证据）
- `$ chmod +x ops/bin/evo-distill.sh && bash -n ops/bin/evo-distill.sh && echo "语法 OK" && ./ops/bin/evo-distill.sh --dry-run --max 3` → `语法 OK would distill: 019fa11b-...` —— 执行层支持 dry-run 预览，语法可静态校验。
- `$ chmod +x ops/bin/evo-distill-trigger.sh && touch ops/log/.distill-off && time ./ops/bin/evo-distill-trigger.sh && echo "开关: 立即返回"` → `./ops/bin/evo-distill-trigger.sh  0.01s user 0.01s system 1% cpu 0.993 total  开关: 立即返回 rc=0  --- 无开关（会 detach 起 driver，锁会挡...` —— 开关存在时 trigger ~1s 内立即返回 rc=0，确实"关停即生效"。
- `$ EVO_DISTILL_TIMEOUT=900 ./ops/bin/evo-distill.sh --session 4af1c06f-edee-4b3f-88a3-87e56a8df9b8 2>&1; tail -2 ops/log/distill.log` → `2026-07-27T03:13:03Z done 4af1c06f-... — DISTILL_OK 2  2026-07-27T03:13:04Z 本轮完成 1 个；剩余队列 12` —— 执行层单会话跑通并产出真实提案计数。
- 写/改文件清单含 `ops/bin/evo-distill.sh`、`ops/bin/evo-distill-trigger.sh`、`ops/bin/com.evo.distill.plist` 三件套，印证"调度 + 执行 + launchd 单元"分层。

## 边界 / 反例
- 本条只描述飞轮的**结构骨架**（两层脚本 + .distill-off 开关 + .distill.lock 锁），不主张 launchd 的具体触发间隔、plist 的 KeepAlive/StartInterval 取值——切片无直接证据，需另行核对 `com.evo.distill.plist`。
- 切片未直接证明"飞轮会在后续周期自动重捞失败的会话"（4af1c06f 的失败是**人工**重跑恢复的，见配套提案 evo-distill-transient-connection-error-retry）；"失败会话是否自动重回队列"需独立验证，勿据本条断言。
- `.distill-off` 是软开关（trigger 主动检查）；若 driver 已经 detach 起来正在跑，touch 开关不会中断当前这一轮——它是"阻止下一轮"，不是"杀当前轮"。
- 文件锁用目录锁（mkdir 原子）才可靠；若实现用的是普通文件 touch + 检查，存在 TOCTOU 竞态，应核对 `evo-distill-trigger.sh` 实际锁实现。

## 失败信号（未来命中即该想起本条）
- 蒸馏队列持续堆积、`./bin/evo queue | wc -l` 只增不减，但 distill.log 没有新 start 记录 → 可能 trigger 没被 launchd 拉起，或 `.distill-off` 被遗忘残留导致 trigger 一直立即返回。
- 想停飞轮却不知道停在哪 → 检查 `ops/log/.distill-off` 是否存在。
- 出现多个 driver 并发 / distill.log 同一会话被重复 start → 检查 `.distill.lock` 锁机制是否失效。
