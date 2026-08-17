---
id: claude-md-directory-scoped-global-skill
type: lesson
status: deprecated
scope: global
domain: claude-code
tags: [claude-code, claude-md, skill, routing-rules]
triggers:
  - "CLAUDE.md 规则在别的项目不生效"
  - "跨项目共享行为规则"
  - "子模型路由规则没触发"
  - "规则写了但 agent 不看"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:583c96aa
last_verified: 2026-07-30
superseded_by: skill:claude-code
schema_version: 1
---

**主张**：写在项目 `CLAUDE.md` 里的行为规则只在那个目录的会话中加载；想要跨项目生效的「主动触发」机制，应做成全局 skill（`~/.claude/skills/`，description 驱动自动出现），而不是把同一段文字复制进每个项目的 CLAUDE.md。

**为什么**：graph-lab 的多模型路由规则写得很全，但在 ucm221 会话里全程不可见——这才是「multi-mode 不够主动」的真正原因之一，不是规则内容不够。复制多份会造成两份文本漂移。

**边界**：项目特有的命令/路径约定仍应留在项目 CLAUDE.md；全局 skill 放跨项目通用的触发规则。改动后把项目里的副本删掉或缩成指针，避免双写漂移。

**证据**：2026-07-30 ucm221 会话，定位「multi-mode 不主动」时发现规则早已存在于 graph-lab/CLAUDE.md 但从未加载，最终落成为全局 skill + symlink。
