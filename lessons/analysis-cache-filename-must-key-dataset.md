---
id: analysis-cache-filename-must-key-dataset
type: lesson
status: candidate
scope: global
domain: data-pipeline
tags: [cache, npz, stale-cache, dataset, python, reproducibility]
triggers:
  - "分析脚本把中间结果（快拍/特征/npz）落盘做缓存，支持换数据集复跑"
  - "给脚本加 --input/--chamber 这类数据集参数，旁边已有按固定文件名命名的缓存"
  - "换了输入数据，结果却和上次一模一样或点数对不上（失败信号）"
  - "缓存命中日志显示的点数/路径属于上一个数据集"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fab8d-651f-7df8-8d1d-29c7d2f71bce
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [episode-ucm221-fpga-cache-mismatch, make-d-macro-change-skips-rebuild-silently]
---

**主张**：支持多数据集的分析脚本，**磁盘缓存的文件名（或校验逻辑）必须绑定输入数据集标识**；否则换数据集后旧缓存静默命中，产出"貌似正常、实则张冠李戴"的结果——没有任何报错。

**证据**：`rx_pair_doa.py --chamber "../data/UCM221-20260713-非均匀阵列暗室数据采集" --tag _20260713` 首次运行，输出 `快拍就绪: 44 点（缓存 snapshot_cache.npz）`——44 是**旧数据集**（20260508）的点数，新数据集应为 63 点，缓存文件名未带数据集标识导致静默复用；修正后同一命令输出 `发现 63 个角度采集点… 快拍就绪: 63 点（缓存 snapshot_cache_20260713.npz）`。会话中多次 `rm -f snapshot_cache.npz && python3 ...` 也是在手动兜底这个缺陷。

**边界**：与 `episode-ucm221-fpga-cache-mismatch`（硬件采集缓存未清空→测角错误）同族不同层：本条是软件分析层的缓存键设计。根治靠文件名带 tag（`snapshot_cache_<tag>.npz`）或在 npz 里存数据集指纹并校验；手动 `rm` 兜底容易忘，且换数据集前的旧结果文件（图/CSV）也要一并带 tag 区分。
