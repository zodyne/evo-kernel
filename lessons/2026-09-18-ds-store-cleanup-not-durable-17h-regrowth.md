---
id: ds-store-cleanup-not-durable-17h-regrowth
type: lesson
status: candidate
scope: global
domain: macos
tags: [macos, ds_store, cleanup, regeneration, disk-hygiene]
triggers:
  - "全机清理 .DS_Store / 桌面垃圾文件，想一次清干净"
  - "清理脚本跑完复查归零就宣告完成（失败信号：次日重扫又冒出一批）"
  - "用户要求『桌面/磁盘以后不再有 .DS_Store』"
  - "决定要不要给 .DS_Store 清理写定期任务（launchd/cron）"
  - "解释 .DS_Store 为什么删了又出现"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a8c1-5e3e-710a-b61a-fd2478c30f87
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: []
---

**主张**：macOS 上全机清理 `.DS_Store` 只是瞬时效果，不是可交付的终态——本机清空 157 个、重扫归零后，**17 小时内自然再生 13 个**，再生点主要在普通项目目录（`~/Dev/SPC865`、`SPC865/data`、`SPC865/output`，时间 17:07）。

**为什么**：`.DS_Store` 由 Finder 在真实使用中按需写回，任何「删除 + 复查为 0」都只证明删除那一刻的状态；把任务以「已清零」收尾，会给用户一个第二天就被推翻的承诺。正确交付姿势是明确告知会再生，并把清理做成定期任务（已有 `~/bin/dsclean` 脚本可复用），而不是宣称一劳永逸。

**边界/反例**：本条只否定「一次性清理可持续」；不清零仍然有即时收益（157 个分布在 72 Dev / 35 Documents / 31 Library / 16 Downloads / 1 Desktop）。另外，17 小时 13 个的样本来自本机自然使用节奏，不能外推成固定速率——重要的是「会再生」这个定性，不是 13 这个数。至于「为什么自动化 Finder 实验复现不出写入」，见 related 条目。

**证据**（session 01a0a8c1，evo slice 「命令 ↔ 结果」）：
- `time find ~ -name .DS_Store -type f | wc -l` → `命中数量: 157`（real 0m30.665s）；按顶层目录分布 `72 Dev / 35 Documents / 31 Library / 16 Downloads / 1 Desktop`。
- 删除前 `删除记录-DS_Store-20260916.txt` 存档 161 行 → `执行删除 成功 157 / 失败 0` → `复查（重新扫描）剩余: 0`。
- 次日复查（末条 assistant 的自然再生表）：清空后 17 小时内再生 13 个，`09-16 17:07 ~/Dev/SPC865/.DS_Store` 等，含 `SPC865/data`、`SPC865/output`。
