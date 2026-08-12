---
id: gitignored-dir-comment-out-not-delete
type: lesson
status: candidate
scope: global
domain: git-hygiene
tags: [gitignore, cleanup, no-version-history]
triggers:
  - "清理 .gitignore 覆盖目录里的代码"
  - "目录被 gitignore 没有版本历史"
  - "想删旧函数/旧节内容"
  - "删除前确认有没有版本兜底"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:eaa269a8
last_verified: 2026-08-03
superseded_by: null
schema_version: 1
---

**主张**：在被 .gitignore 覆盖、无版本历史兜底的目录里，不直接删除可能还有用的代码/文档段落——改成注释保留或挂到开关（如 `--extra`）下，保留恢复入口。

**为什么**：`libucm221/` 这类嵌入式工作克隆常整体进 .gitignore，删掉即永久丢失，没有 git 可回退。会话中处理报告第 4 节时选择逐行注释（27 行）而非删除，旧 2D 绘图函数挂到 `--extra` 开关下而非移除。

**边界**：若目录实际有独立 git 仓库（工作克隆自身是 repo），则不受此限，删前先确认；长期无人用的死代码仍应定期清，注释里标注日期与原因。

**证据**：ucm221-pointcloud-2.0 报告精简会话（2026-08-03），用户要求「移除第 4 节」，因无版本兜底改为注释并明确告知恢复方式。
