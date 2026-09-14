---
id: claude-session-jsonl-drops-pasted-images
type: fact
status: candidate
scope: global
domain: agent-harness
tags: [claude-code, transcript, jsonl, images, screenshot, recovery]
triggers:
  - "想从 ~/.claude/projects/*.jsonl 里把用户先前粘贴的截图找回来"
  - "会话 transcript 里只看到 [Image #1] 占位符，找不到图片数据（失败信号）"
  - "写脚本从会话记录里提取图片/附件做复现或归档"
  - "对话中途需要重看用户早先给的界面截图"
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:1363c097-a1c9-4248-a903-814a33facb13
last_verified: 2026-08-13
superseded_by: null
schema_version: 1
related: [transcript-parser-normalize-tool-names, evo-slice-normalize-toolname-case-and-path-field]
---
# Claude Code 会话 jsonl 里没有粘贴图片的数据，只有 `[Image #N]` 占位——事后取不回来

## 主张
用户在 Claude Code 里粘贴的截图，在 `~/.claude/projects/<proj>/<sid>.jsonl` 中**只留下 `[Image #1]` 这类文本占位符**，
既没有 base64 图像数据，也没有指向本地文件的路径。
**结论：不要花力气从 transcript 复原截图**——需要重看图就请用户重新提供，或让用户先把图存到可访问路径再引用。

## 为什么
"会话都记录在 jsonl 里"这个直觉会让人反复写扫描脚本（找 `"source"`、找 `data:` URI、找 base64 段），
每次都是零命中，白烧多轮。把这条记成事实可以直接跳到"请用户重发"这个唯一可行动作。

## 证据（本会话命令对照）
- 首条 user 文本确实含两张图的占位：`... 请详细分析 [Image #1] [Image #2] 这是2个agent 显示效果的对比 ...`
- `cd ~/.claude/projects/-Users-zodyne && grep -oE '"source": *"[^"]*"' 1363c097-...jsonl` → `---搜 image 相关行---` 段落**无输出**，`---搜文件路径---` 无输出。
- python 扫当前会话文件找 base64/图像块 → `total images: 0`
- python 扫**该目录下所有** `*.jsonl`（按 mtime 排序）→ `found: 0`
- 同期另一条路也走不通：截图保存前的临时目录 `/var/folders/.../TemporaryItems/NSIRD_screencaptureui_*`
  对终端进程 `Operation not permitted`（`ls` / `cp` / python 全被拒）。

## 边界 / 反例
- 只覆盖本机这一版 Claude Code 的落盘行为；若未来版本改为落盘附件，需重新确认（复核动作就是上面那两条扫描）。
- 有一处扫描输出 `---data URI?--- 1` 语义不明（可能是计数行），但两次独立的结构化扫描均为 0，
  故主张按"无可用图像数据"记；**若将来要推翻本条，应以能真正解出图片字节为准**。
- 用户**手动**保存到 Desktop 的截图当然能读（另受 TCC 限制），那与 transcript 无关。

## 失败信号（未来命中即该想起本条）
- transcript 里看到 `[Image #N]` 却 grep 不到任何 base64/路径。
- 连续多个"扫 jsonl 找图"的脚本返回 0。
