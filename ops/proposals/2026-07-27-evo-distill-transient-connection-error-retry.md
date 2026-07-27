---
id: evo-distill-transient-connection-error-retry
type: lesson
status: candidate
scope: project:evo-kernel
domain: ops
tags: [evo-kernel, distill, retry, transient-error, api, connection-error, troubleshooting]
triggers:
  - "evo-distill 蒸馏失败排查 / distill.log 出现 fail 记录"
  - "蒸馏飞轮偶发失败、某会话 distill 后台 .out 文件里是 Connection error"
  - "看到蒸馏 fail 就怀疑配置/数据/实现坏了，想动手改（失败信号）"
  - "后台蒸馏任务遇到 API 端网络瞬时错误如何处置"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:d2f8d5b2-2b60-4913-958b-59d2f937ed95
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# evo-distill 遇到 API Connection error 是瞬时网络失败：记 fail 但不损数据，手动重跑同一 session 通常成功——排查先重跑而非改实现

## 主张
`evo-distill.sh --session <id>` 单次执行时，若底层 LLM API 抛 **Connection error**（网络瞬时断连），distill 会把它记为该 session 的 `fail` 并留下 `.distill-<session>.out`，但**不损坏会话数据、不污染队列、不产生半成品提案**。处置方式是**直接重跑同一 session**，通常一次即恢复；不要一看到 fail 就去改配置、改 distill 实现或怀疑会话文件坏了。

## 为什么
蒸馏是"读会话 jsonl → 切片 → 让 LLM 产出提案 → 写文件"的流程，其中只有"让 LLM 产出"这一步依赖外部 API 网络，最易瞬时失败。Connection error 发生在这一步时，distill 尚未写任何提案文件就退出了，状态是干净的——会话仍在队列里、jsonl 未被改动、ops/proposals 未被污染。因此重跑等于在干净状态上重试同一个确定性输入，成功概率高。把它误判为"配置错/数据坏/实现 bug"而动手改东西，反而会引入真正的问题。

## 证据（本会话命令 ↔ 结果，切片硬证据）
- 飞轮 detach 触发 4af1c06f 后，`$ tail -30 "ops/log/.distill-4af1c06f-edee-4b3f-88a3-87e56a8df9b8.out"` → `Connection error.` —— 失败原因是 API 端 Connection error（瞬时网络），非数据/配置/实现问题。
- distill.log 记录 `2026-07-27T03:01:11Z start 4af1c06f-...` → `2026-07-27T03:05:27Z fail 4af1c06f-...`（从轮询锁释放时间推断该轮以 fail 结束）。
- 手动重跑 `$ EVO_DISTILL_TIMEOUT=900 ./ops/bin/evo-distill.sh --session 4af1c06f-edee-4b3f-88a3-87e56a8df9b8 2>&1; tail -2 ops/log/distill.log` → `2026-07-27T03:13:03Z done 4af1c06f-... — DISTILL_OK 2` —— 同一 session、同一输入，重跑即 `done` 并产出 2 条提案，证明前次失败是瞬时的、状态是干净的。

## 边界 / 反例
- 本条**只**覆盖"Connection error 这类瞬时网络失败"。若 `.out` 里是解析错误、schema 校验失败、slice 为空、权限错误等**确定性**失败，重跑同样会 fail——那种情况必须修根因，不能靠重跑。
- "重跑通常成功"是基于单次样本的信号，不保证 100%；连续多次重跑仍 fail 时，应升级为"怀疑 API 凭证 / 限流 / 该 session 内容本身触发模型异常"，而非继续盲目重试。
- 本条不主张"飞轮会自动重捞失败会话"——切片中 4af1c06f 是**人工**重跑恢复的，飞轮是否自动重试需独立验证（见配套提案 evo-distill-flywheel-launchd-off-switch 的边界）。

## 失败信号（未来命中即该想起本条）
- distill.log 某会话记 fail，对应 `.distill-<id>.out` 末尾是 `Connection error`。
- 看到蒸馏 fail，第一反应是想改 evo-distill.sh / 改会话文件 / 改配置。
- 后台飞轮偶发 fail 但大部分会话正常 done，只有个别会话卡住。
