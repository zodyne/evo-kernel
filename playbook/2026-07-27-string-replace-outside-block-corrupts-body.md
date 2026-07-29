---
id: string-replace-outside-block-corrupts-body
type: lesson
status: validated
scope: global
domain: text-processing
tags: [frontmatter, markdown, string-replace, scope, silent-corruption]
triggers:
  - "用 string.replace 改写 markdown frontmatter / YAML 头 / JSON 头里的某个字段"
  - "正文里恰好出现了和要改字段同名的行（如 `status:`、`title:`）"
  - "改写后正文内容被误改，且无报错（静默损坏）"
  - "实现 setFmField / 改 frontmatter 的工具函数"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# 改写结构化区块（frontmatter/JSON 头）字段必须限定在区块边界内，全局 replace 会误改正文

**主张**：对 markdown frontmatter、YAML/JSON 头部等"文档里嵌一块结构化文本"做字段改写时，若用 `text.replace(/^status:.*$/m, ...)` 这类**不带边界**的正则，只要正文里出现同名字段（如示例正文写 `status: validated` 作说明），就会被一起改掉——静默损坏正文，无报错。

**根因**：字段名（`status:`、`title:`、`id:`）在自由正文里完全合法且常见；正则锚的是"行模式"而非"位置（在第几块）"。

**修法**：改写函数必须先切出区块（匹配 `^---\n([\s\S]*?)\n---` 拿到 fm 块），只在块内做 replace，再拼回。即"定位 → 局部改 → 还原"，而非"全文搜替"。

**反例/边界**：若文档结构保证字段名全局唯一（如代码里不存在同名），全局 replace 也能工作——但这依赖隐性不变量，一旦破坏就静默出错；区块限定是鲁棒默认。

**证据**（commit d092eaf）：
- 复现 1：探针 `zz-fmprobe` 正文写 `status: validated`，curate（应把 fm 的 `status: candidate→validated`）后正文那行也被改写（旧 setFmField 用不受限 replace）。
- 复现 2：`/tmp/nostatus.md`（无 fm status 字段、正文开头有 `status:` 行）被旧实现误改正文。
- 修复：setFmField 改为先切 fm 块、块内 replace、拼回。
- smoke 新增守护 `curate 入 validated 区改写 status`（限定在 fm 块）。
