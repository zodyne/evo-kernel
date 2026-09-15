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
  - "治理指标（时效/使用量）被自登记或机器调用噪声拉低/虚高且找不到外部来源"
  - "换/新增 harness 之后，旧 harness 修过的自污染又出现（失败信号）"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [register-at-first-event-not-lifecycle-end]
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

## 2026-09-15 补强：同一环路在 hermes 侧复发 1.5 个月（防护没有跟着迁移）

pi 侧的修法（`--no-session`）是 **harness 专属**的：2026-08-14 蒸馏后端迁到 hermes 时，等价短路没有补上，
环路静默复发（commit `f95da31` 修复）。实测：

- **自登记 13 条**（8/15–8/17 七条 + 9/15 六条）。判据是「登记 ts 与 `distill.log` 的 start 行秒级对齐」全量匹配日志，
  而不是只看当天直觉——不这么查就会漏掉两个月前那批。其中 3 条（129–324KB，带真实导出 transcript）
  已排进待蒸馏队列——**下一批就会「自己蒸自己」**；其余 10 条 `'?'` 哨兵压低 transcript 时效指标。
- **指标双通道污染**：驱动器自己跑 `evo get` 读条目，被 `lastRecallSession()` 回填成 agentic 使用量——
  报告显示 `get 3 次/5 id`，真实只有 `1 次/2 id`（2/3 是机器账）。而使用量正是判据表「≥10 个任务才可读精度」
  这道闸门的输入：**机器账填满闸门 = 拿假数据触发决策**。
- `hook-recall` 同样给驱动器 prompt 写 `recall.jsonl`，把非真人任务混进词法注入统计。

**hermes 侧修法**：驱动器给子进程注入 `EVO_DRIVER=1` → `hook-recall` / `hook-session-end` 短路、
`candidates` / `get` 不落账（guard 故意不短路：安全优先）；adapter 另加提示词哨兵兜底（防 env 传不进 hook）。
桩测：`EVO_DRIVER=1 hermes -z …` → 登记 101→101、recall 807→807；哨兵 prompt（不带 env）→ 同样零登记。
存量：13 条自登记行移除（405→392），2 条机器账移除。

**推广规则（本次最贵的教训）**：短路标志是 per-harness 的——**每次 harness 迁移/新增，把「已修自污染清单」
当迁移 checklist 逐条重放**。这类缺陷不报错、不缺证据，只是安静地长；撞见它的入口往往是
「某条指标数字的来源对不上」，而不是任何一条报错。
