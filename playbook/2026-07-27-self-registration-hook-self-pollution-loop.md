---
id: self-registration-hook-self-pollution-loop
type: lesson
status: validated
scope: global
domain: harness-config
tags: [hook, self-registration, feedback-loop, background-process, sentinels]
triggers:
  - "扩展/hook 里有『每次会话开始就登记一条 session 记录』的逻辑"
  - "后台驱动器 / 定时任务 / launchd 会调用同一个被 hook 包装的入口"
  - "登记表里出现大量找不到 transcript 的脏行 / 哨兵（失败信号）"
  - "治理指标（如 transcript 时效）被自登记的噪声拉低且找不到外部来源"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# hook 的"每次会话自登记"逻辑遇到后台驱动器自调用会形成自污染反馈环

**主张**：若扩展在 session_start hook 里"无条件登记本次 session"，而后台驱动器（launchd/定时器）会调用同一入口（如起一个子进程 `pi`/`claude` 跑批处理），驱动器每次跑都会**把自己登记成一条数据**——这些自登记行没有真实 transcript，是纯噪声。它们会污染依赖该登记表的治理指标（队列、时效、蒸馏节律），且因为"自己触发自己"而持续累积，形成反馈环。

**根因**：登记逻辑假设"每次入口调用 = 一次真实用户会话"，但后台自调用破坏了这个假设；入口无法区分"真人会话"与"我自己为了干活起的子进程"。

**修法**：给后台/无会话的调用通道加短路标志，让 hook 跳过登记。本次修复即让蒸馏驱动器调用 pi 时带 `--no-session`（不产生会话记录），hook 侧对无 session 的调用不登记。

**反例/边界**：若驱动器确实需要被记录（如审计后台任务执行），应登记到**独立通道**（如 distill.log）而非混入"会话登记表"——同表混放是污染根源。

**证据**（commit `fix: 后台蒸馏自登记哨兵污染治理判据`）：
- 复现：`pi -p "..."`（默认带会话）→ `tail -1 session-refs.jsonl` 新增一行登记；登记表里 58 条全哨兵行，transcript 时效指标 60% 失真。
- 验证修法：`pi -p --no-session "..."` → 登记行数 97→97，未新增哨兵。
- 治理：清除 22 条 pi 自登记哨兵后，doctor `transcript 时效` 从 58/97 (60%) 降到 36/76 (47%)。
