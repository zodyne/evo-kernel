---
id: hermes-cron-model-drift-fail-closed
type: bullet
status: validated
scope: global
domain: hermes
tags: [hermes, cron, model, drift, fail-closed]
triggers:
  - "cron last_status=error 但没有真实推理调用"
  - "errors.log 报 Skipped to prevent unintended spend: global inference config drifted"
  - "换全局默认模型后 LLM cron 任务不跑"
  - "排查 hermes cron 任务到点未执行"
created: 2026-08-12
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:capture-2026-08-12-01-09-50-916-ezxs
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [hermes-config-set-cannot-write-list-dict, hermes-cron-create-positionals-before-options]
---
hermes cron LLM 任务有防漂移熔断（#44585）：创建时快照全局 model/provider，全局默认变了之后，未 pin 的任务 fail-closed 拒跑。

**失败信号**：cron last_status=error 但没有真实推理调用；errors.log 报 `Skipped to prevent unintended spend: global inference config drifted`。
**修法**：`hermes cron edit <job_id> --provider <p> --model <m>` 显式 pin，或配置 `cron.model` / `cron.model_provider` 机队默认（该轴视为用户刻意路由，不判漂移）。
**边界**：换全局默认模型后要主动检查所有未 pin 的 LLM cron 任务——熔断是刻意的防浪费设计，不是故障。
**证据**：2026-08-12 实例——晨报任务快照 v4-pro、全局切 v4-flash 后 09:00 熔断跳过。
