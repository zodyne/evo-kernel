---
id: backup-untracked-file-before-edit
type: lesson
status: candidate
scope: global
domain: workflow
tags: [git, backup, untracked, pre-edit-safety, large-file-edit, rollback]
triggers:
  - "要改的文件 `git ls-files <path>` 返回空（未纳入追踪）"
  - "动手重写/覆盖一个不在版本控制里的文件"
  - "新写的脚本/查看器改坏了发现 git checkout 救不回来"
  - "改动前想确认目标文件是否受 git 保护"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:6f9c92c5-482a-40a9-8810-6dd388611e95
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# 改未纳入 git 追踪的文件前，先做时间戳备份

## 主张
动手编辑前先 `git ls-files <path>` 确认目标文件是否被追踪；若**返回空（未纳入 git）**，改前先把它 `cp -p` 成一份**带时间戳的副本**放进 `backup/`，再开始改。因为未追踪文件一旦被覆盖/重写，`git checkout`/`git stash` 都救不回来——版本控制只保护已追踪文件。

## 为什么
git 的回滚能力建立在"对象库里已有该文件的历史版本"之上。新建的、被 gitignore 的、或尚未 `git add` 的文件，没有任何历史版本，被覆盖式编辑后无路可退。给这类文件手动建一个时间戳备份，等于临时给它补一个可回滚点。本会话目标 `python/viewer_filtered.py` 是个新写的查看器、`git ls-files` 返回空，后续又对它做了多轮重写（import 改动、累积锚点重构等），改前先备份是合理的安全网。

## 证据（本会话命令对照）
- `git ls-files python/viewer_filtered.py; echo "(空=未纳入git)"` → 输出 `(空=未纳入git)`（ls-files 无任何路径，确认未追踪）。
- 随后 `mkdir -p backup && TS=$(date +%Y%m%d_%H%M%S) && cp -p python/viewer_filtered.py "backup/viewer_filtered.${TS}.py" && ls -la backup/ && md5 -q ...` → `backup/` 目录创建成功、时间戳副本就位并做了 md5 校验。
- 旁证：本会话 grep 也确认仓库文档里没有既定的 `.bak`/backup 约定（`grep -rn "\.bak\|backup" CLAUDE.md CONTRIBUTING.md` 无输出），所以临时 `backup/` 是自建的而非违反约定。

## 边界 / 反例
- 已被 git 追踪的文件**不必**额外备份，`git stash`/`git checkout` 足够，再加 `backup/` 反而是噪音。
- `backup/` 目录本身应进 `.gitignore`，避免把二进制/大副本污染仓库。
- 一次性小改、或文件可由脚本重新生成（非手工产物）时，备份收益低可跳过——备份是给"改坏难重建"的手工产物上的保险。

## 失败信号（未来命中即该想起本条）
- `git ls-files <path>` 没有任何输出 = 这个文件 git 救不了 → 改前先 `cp -p` 出时间戳副本。
