---
id: 2026-09-16-recovery-doc-must-inline-not-pointer
type: lesson
status: validated
scope: global
domain: documentation
tags: [documentation, self-contained, recovery, archive]
triggers:
  - "写恢复/归档/清理记录文档，关键清单想只写'见另一份文件'"
  - "记录里用指针引用别的文件，担心将来断链"
  - "写操作日志时想把文件清单/恢复办法省略成一句含糊话"
  - "归档记录被指出关键事实缺失、只有指针（失败信号）"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a7f9-4ced-73b3-8cfc-3829cc92108c
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: []
---

写恢复/归档/清理记录时，关键事实（文件清单+版本号、恢复命令、以及「无恢复办法」的明确结论）必须内联，不能只写指向另一份文件的指针。本会话把 TI 安装器从「只给指针」改为 8 个文件名+版本号内联进日志（并写明为何内联），把「可再生成但未留痕」的含糊措辞改为「❌ 无恢复办法」结论写死并附 6 条排查线证据表，另增一张「被删对象 × 能否恢复 × 办法」的恢复矩阵。

为什么：单点依赖——指针指向的那份文件一旦丢失/移动/被删，整条恢复记录就成了死链，将来无法独立恢复；含糊措辞（如「可再生成」）会让将来的人误判可恢复性，必须给出确定的能/不能结论并附排查证据。

边界/反例：恢复文档的价值在「独自重建现场」，不在于写得短；清单、版本号、sha256 这类可复核的事实优先内联，跨文件共享的大段内容才用指针。
