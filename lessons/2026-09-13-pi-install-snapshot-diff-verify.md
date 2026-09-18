---
id: 2026-09-13-pi-install-snapshot-diff-verify
type: lesson
status: candidate
scope: global
domain: pi
tags: [pi, package, install, backup, diff]
triggers:
  - "在真实 ~/.pi/agent 装/卸 pi 扩展包"
  - "要向人说明这次安装到底改了什么"
  - "怀疑装包动了共享目录（agents/、extensions/、npm 树）"
  - "装完后 agents/ 冒出不认识的文件、不知道哪来的（失败信号）"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a099a8-07d2-766c-b240-9eaed5f6ca6d
last_verified: 2026-09-13
superseded_by: null
schema_version: 1
related: [backup-untracked-file-before-edit]
---

**主张**：真实 profile 装包前做三样快照——`cp settings.json settings.json.bak-<时间戳>-before-<包名>`、打印已装包版本清单、列 agents/ 目录——装完用 diff + 软链清单核对实际变更面，回退与归因都有据。

**为什么**：安装的可见变更不止 settings.json 的 packages 数组：包的 postinstall 会把 persona .md 软链进 agents/（本例 7 个）、往 npm 树加依赖；不装前快照，事后说不清"哪些是它干的"。

**反例/边界**：`diff` settings.json 前后只显示 packages 数组增量（本例 +pi-cohort、+pi-gauntlet），不会暴露软链类副作用——共享目录要单独 `ls -la` 核对。

**证据**（session:01a099a8-07d2-766c-b240-9eaed5f6ca6d）：留有 `settings.json.bak-20260913-225153-before-gauntlet`；装前 python 打印四包版本"记录安装前状态"；装后 `diff <(python3 -m json.tool settings.json.bak-…) <(python3 -m json.tool settings.json)` 精确定位 packages 增量；`ls -la ~/.pi/agent/agents/ | grep "\->"` 清点 7 个 gauntlet 软链；另跑"真实 profile 未被改动检查"确认沙箱结论可平移。
