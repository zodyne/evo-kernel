---
id: 2026-07-27-stash-patch-apply-check-freeze-uncommitted
type: playbook
status: candidate
scope: global
domain: git-workflow
tags: [git, stash, patch, apply-check, archive, provenance]
triggers:
  - 要丢弃/清理工作区里的未提交并行工作，但它的内容仍值得日后回放
  - 需要一个干净工作区来打包交付，却有一批游离的未提交改动挡路
  - git apply --check <patch> 报 "can't open patch / No such file or directory"
  - 想用 git stash 保全未提交工作，但忘了带 -u 导致 untracked 文件漏掉
  - 冻结存档后直接还原了工作区（顺序颠倒），发现内容其实没真正进 git
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:c0a7ecbd-7117-4c93-931a-53aca42b7fed
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---

# 冻结未提交工作：stash -u + apply --check 回放验证，先入库再还原

丢弃工作区里的未提交并行工作前，先用 `git stash -u`（**必须带 `-u` 含 untracked**）导出补丁，用 `git apply --check` 验证补丁能干净回放到 HEAD，再把「冻结副本 + 补丁」一起 `git commit` 入库——**顺序必须是「先提交存档、再还原工作区」**，颠倒即丢数据。

## 为什么

工作区里常常混着两类"想扔又怕扔"的东西：已跟踪文件的未提交改动，和一堆未跟踪的实验文件/脚本。直接 `git stash`（不带 `-u`）只收前者，untracked 文件会随工作区清理一起蒸发；想靠"我先 stash 起来"兜底却没验证补丁能回放，等真正丢弃后才发现补丁写错了路径或漏了文件，已经救不回来。

## 回放验证是硬闸门

`git apply --check <patch>` 不改任何文件，只模拟应用：**它失败就说明你的"保全"还没到位，必须先修再继续**，绝不能假设已经存住了。本会话里这一步直接命中过：

- 第一次 `git apply --check archive/frozen-doa-large-angle/uncommitted-changes.patch`
  → `error: can't open patch '...uncommitted-changes.patch': No such file or directory`
  （补丁其实写在了 scratchpad，不是 archive 路径，照搬相对路径就找不到）
- 改正路径后 → `✓ 补丁可干净应用于 HEAD 状态`，这才进入下一步。

## 顺序：先入库，再还原

把冻结副本（移到 `archive/<line>/`）连同补丁 `git commit` 之后，**才**还原/丢弃工作区。本会话的提交记录印证了这条顺序：先 `commit` 出 `chore(archive): 冻结 C 线 ...`，然后才 `git stash` 还原工作区；提交信息里明确写"现在才还原工作区（内容已在 git 中）"——颠倒这个顺序，一旦还原出了岔子，内容既不在工作区也不在 git。

## 边界

- `git stash` 不带 `-u` 不收 untracked：要保全游离文件必须 `-u`。
- `apply --check` 路径要对：补丁写在哪就用哪个路径喂给它，别凭记忆写相对路径。
- 补丁是快照、会随上游演进而失效：冻结是为了"日后能人工还原这次的具体改动"，不是长期可复现机制；长期复现靠重跑脚本（provenance），不靠补丁。
