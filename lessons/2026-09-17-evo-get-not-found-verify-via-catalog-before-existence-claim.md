---
id: evo-get-not-found-verify-via-catalog-before-existence-claim
type: lesson
status: candidate
scope: project:evo-kernel
domain: tooling
tags: [evo-kernel, evo-get, catalog, index-drift, existence-check]
triggers:
  - "evo get --ids 某条 id 返回未找到，准备据此断定该条目不存在"
  - "知识库实体文件被改名/搬区（inbox→playbook 等）后，拿不准旧 id 是否还能用工具直接拉到"
  - "catalog 里 grep 得到某 id，但 get/文件系统路径对不上"
  - "批量整理 inbox capture 时要判断某条到底入没入库"
  - "只凭单一查询工具的空结果就下存在性结论（失败信号）"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae53-583c-764c-a77e-517de3420920
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [frontmatter-edit-must-use-setfmfield]
---

# evo get 报「未找到」不能当作「该 ID 不存在」的证据——先回 catalog/文件系统交叉定位

## 主张

evo-kernel 是「catalog 索引 + 实体文件」双结构知识库，实体文件被改名或移动后索引行未同步（或实体尚在 inbox 等非检索区）时，会出现「`evo get` 报未找到、catalog 里却有行」的脱节态。此时 **`evo get --ids <id>` 的「未找到」只证明该工具查不到，不证明该 ID 不存在**；下存在性结论前必须拿 `evo catalog | grep <id>`（看行在哪个区）和文件系统（`ls inbox/` 等真实位置）交叉核实。

## 为什么

`evo get` 与 `evo catalog` 走的覆盖面不同：get 只在可检索的入库区里找，而 capture 实体可以合法地存在于 inbox（未审区）。搬运/改名类操作还会留下旧索引行。单一工具的空结果在这种双结构下天然有盲区；把它当存在性证据，会得出「这条经验丢了/从没入库」的假阴性结论，进而误删索引或重复补写。

## 反例 / 边界

- 本条只主张「未找到 ≠ 不存在，需交叉核实」；如果 catalog 也 grep 不到、且文件系统确认无此文件，才可以下「不存在」结论。
- catalog 的行只说明索引里有记录，**不保证实体文件就在行内标注的区里**——还需 `ls`/`find` 到真实路径才算闭环。
- 适用于 evo-kernel 这类「索引+实体文件」仓库；对单一数据源的普通 API，未找到基本等同不存在，不适用。

## 证据（本会话切片命令 ↔ 结果）

- `$ ./bin/evo get --ids capture-2026-09-14-13-15-33-086-6c1f` → `未找到`；
- `$ grep -n "capture-2026-09-14-13-15-33-086-6c1f" /tmp/catalog_full.tsv` → `116:capture-2026-09-14-13-15-33-086-6c1f	inbox	` —— get 未找到与 catalog 有行同时成立，且该区为 inbox；
- 同切片 `$ cat /tmp/capbatch_ac` 列出的批处理清单里该批 capture 均以 `inbox/capture-*.md` 形式存在 —— 实体文件在 inbox 有真实落盘位置，佐证「未找到只是通道盲区，不是条目不存在」。
