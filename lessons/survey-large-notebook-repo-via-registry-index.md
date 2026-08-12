---
id: survey-large-notebook-repo-via-registry-index
type: lesson
status: candidate
scope: global
domain: content-survey
tags: [notebook, registry, survey, teaching, claude-cookbooks]
triggers:
  - "面对几十上百个 notebook/教程文件的内容仓库，要先产出全景地图"
  - "用 teach 技能讲解一个大型示例仓库之前"
  - "逐个点开文件摸结构太慢，想找仓库自带的索引/清单文件"
  - "grep registry.yaml 的 title/path 字段快速列出全部条目"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fb6c8-af0e-7d39-b9fc-d8c830b28fe5
last_verified: 2026-07-31
superseded_by: null
schema_version: 1
---
勘察大型内容集合（如 claude-cookbooks 约 80 个 notebook）时，**先找仓库自带的索引文件（registry.yaml / index / manifest），grep 其 title/path 字段 + 目录概览**，而不是逐个点开文件——两步命令即可产出带定位的全景地图。

证据：本会话 `grep -E "^\s+-?\s*(title|path):" registry.yaml | head -80` + 目录循环概览，直接支撑最终输出了一张按板块组织的 ~80 notebook 全景表。

边界：仓库没有索引文件时退回目录树 + README；索引可能滞后于实际文件，关键条目需抽查核对。
