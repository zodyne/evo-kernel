---
id: pi-subagent-task-outputs-in-tmpdir
type: fact
status: candidate
scope: global
domain: pi-agent
tags: [pi, pi-subagents, subagent, artifacts, tmpdir, forensics, audit]
triggers:
  - "子代理（subagent）的产出在主会话里只剩摘要或回流被截断，想拿原始输出"
  - "审计/复核子代理到底跑了什么、返回了什么，要拿未被转写的原件"
  - "在临时目录找不到 pi 子代理的任务产物，不知道 <uuid>.output 属于哪次派发"
  - "会话结束或闪退后，想追回 parallel fan-out 的大产出"
  - "想按时间线判断某个子代理结果产出于哪一刻（失败信号：只凭主会话 transcript 下结论）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ad-83f5-725c-a75a-f98c8ce559e8
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pi-subagent-tool-silent-failure-pitfalls, pi-jsonl-toolresult-toolcallid-pairing]
---

# pi 子代理的任务原始输出按「派发它的会话」留档在 $TMPDIR 下

## 主张
`pi-subagents` 把子代理任务的输出以文件形式留在磁盘，路径形状是
`$TMPDIR/pi-subagents-<uid>/<cwd-slug>/<派发该子代理的会话 id>/tasks/<task-uuid>.output`。
所以要让主会话 transcript 之外核对子代理原件（回流被截断、只剩摘要、或会话早已结束），按这个路径取件：先用会话 id 定位桶目录，再用 `stat -f '%Sm %N'` 把 `<uuid>.output` 的 mtime 与派发时间线对齐。

## 为什么
主会话转录里留下的是回流文本，不是子代理的原始产出（parallel 模式还另有 50KB/任务的回流上限，见 related `pi-subagent-tool-silent-failure-pitfalls`）；审计、复核、追责都要求原件。这个目录按**派发会话 id** 分桶，因此既能回答"这是哪次派发产生的"，也保留了未被转写/截断的全文。

## 证据（本会话命令 ↔ 结果，切片硬证据）
```
$ cd /var/folders/_9/mtxm3vm57vb0_686607pg8fm0000gn/T/pi-subagents-501/Users-zodyne/01a09f18-05ae-7485-85f6-b4efb9c12374/tasks/ && stat -f '%Sm %N' -t '...'
↳ 16:46:29 b3ef1e69-f5cd-4ba.output 16:46:35 d224b27b-2de6-4c0.output
```
- 路径四段可逐段对上：`pi-subagents-501`（uid）/ `Users-zodyne`（cwd `/Users/zodyne` 的 slug，去掉前导 `/` 后把 `/` 换成 `-`）/ `01a09f18-05ae-7485-85f6-b4efb9c12374`（派发子代理的那个会话 id，切片里另有同一 id 的 `{"type":"session","version":3,"id":"01a09f18-..."}` 首行佐证）/ `tasks/`。
- 文件名为任务 uuid + `.output`；两个 mtime（16:46:29、16:46:35）与该会话末条记录时间戳（`2026-09-14T08:46:28.595Z` = 本地 16:46:28）落在同一段，可直接用来对齐"哪次派发在什么时候出结果"。
- 触发本条的用例：本会话正是在复核一份关于该会话子代理行为的报告，需要回到原件层面取证。

## 边界 / 反例
- 本切片只证明"该路径存在、且含 `<uuid>.output` 文件"。**未**验证 `.output` 与主会话中某一次 subagent 调用的一一映射字段，也**未**验证它是完整未截断输出——当原件使用前先抽查头尾。
- 位置在 `$TMPDIR`（macOS 上是 `/var/folders/<hash>/T/`，**不是** `/tmp`）：本切片只能证明产物 2 天后（Sep 14 产出、Sep 16 读取）仍在，不能假定长期留存；要留档得主动复制出仓库/会话目录。
- 路径随 uid 与 cwd 变化：换用户（uid 段）或换工作目录（cwd slug 段）都要重算，不能照抄字面路径。

## 失败信号（未来命中即该想起本条）
- 拿着主会话 transcript 里的摘要/截断输出做结论，被追问"原件呢"答不上来。
- 在 `/tmp` 下找不到 `pi-subagents-*` 就断言"产物没留档"（应先看 `$TMPDIR`）。
