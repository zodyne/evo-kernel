---
id: claude-auto-classifier-blocks-three-action-classes
type: playbook
status: validated
scope: global
domain: claude-code
tags: [claude-code, auto-mode, classifier, self-modification, permissions, dispatch]
triggers:
  - "agent 想给 Claude Code 写/测一个无人值守的启动脚本，被分类器拦下"
  - "想通过编辑 .claude/settings.json 给自己加 allow 规则，被拒绝"
  - "自动派发流程每次都要过分类器，想找一个能自动化的绕法"
  - "后台 Bash 任务在 timeout 小于其运行时长的设置下仍然跑完了"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:inbox/capture-2026-09-20-04-20-06-211-4uvl
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [auto-approval-classifier-outage-blocks-bash, claude-code-daemon-restart-classifier-block-hand-off]
---

# Claude Code auto 模式分类器会拦三类动作，且**无法由 agent 自己绕**

**主张**：auto 模式分类器拦截的动作类别里，至少这三类 agent 绕不过去，**换 `--allowedTools` 也拦**：
① 写入/测试「无人值守 `claude -p` + 可写可提交」的启动脚本（理由 Create Unsafe Agents）；
② 往 `.claude/settings.json` 加 allow 规则（理由 Self-Modification）。
系统性解法只有一个：**用户亲手**加一条 allow 规则（如 `Bash(tools/handoff/dispatch.sh:*)`）——
这一步不可自动化，也不该自动化。

## 为什么

这两条拦的是「自我扩权」与「创建无人监管的可写 agent」，属分类器的**硬边界**，
不是 allowlist 能覆盖的权限判定 —— 所以换 flag 无效。把它当"配置问题"去试各种 flag 是白费轮次。

## 证据（2026-09-20 实测）

- 分类器对上述两类动作的拒绝理由分别为 `Create Unsafe Agents` 与 `Self-Modification`。
- 另一条附带实测：后台 Bash（`run_in_background`）**不受 `timeout` 参数约束**
  （12s 睡眠在 5s 超时设置下跑完）—— 长任务派发脚本可以保持同步形态。

## 边界 / 反例

- 拦的是「动作类别」，不是某个文件名；换一个等价写法仍会命中（这正是本条的重点）。
- 后台 Bash 不受 timeout 约束这条是**该版本**的观测；它同时意味着长任务没有超时保护，别当优点用。
