---
id: hardcoded-data-dir-rot-fails-late
type: lesson
status: candidate
scope: global
domain: data-pipeline
tags: [python, data-analysis, path-management]
triggers:
  - "写数据分析脚本时把采集数据目录路径硬编码成常量"
  - "数据集目录改名/归档后，旧脚本报 FileNotFoundError / No such file or directory"
  - "脚本跑到一半才 traceback，前面缓存加载都正常（失败信号）"
  - "跑长流水线/批处理前没有先验证输入目录存在"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:583c96aa-69cd-41b3-926b-4f72d4d7c7f5
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
---

硬编码的采集数据目录会腐烂：目录改名后，脚本不是启动即报错，而是跑到中途才 FileNotFoundError，浪费前面的计算。

会话证据：`rx_pair_doa.py` 加载完 44 点缓存后才 traceback；`ls` 确认 `/Users/zodyne/Dev/ucm221/20260508暗室角度采集: No such file or directory`（目录已不存在）；`angle_survey.py` 同样在该数据集处崩溃。

做法：数据目录做成参数/配置，或 main() 开头统一校验所有输入路径存在并给出人话报错，把失败提前到启动时。
