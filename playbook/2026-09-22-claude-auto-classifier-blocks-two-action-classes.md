---
id: claude-auto-classifier-blocks-two-action-classes
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
verified_by: human
source: capture:inbox/capture-2026-09-20-04-20-06-211-4uvl
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [auto-approval-classifier-outage-blocks-bash, claude-code-daemon-restart-classifier-block-hand-off]
---

# Claude Code auto 模式分类器拦下的两类动作：写无人值守启动脚本、给自己加 allow 规则

**主张**：2026-09-20 那次会话里，auto 模式分类器拦下两类动作，且拦的不是 allowlist 那一层：
① 写入/测试「无人值守 `claude -p` + 可写可提交」的启动脚本（拒绝理由 `Create Unsafe Agents`，
**这一条**换 `--allowedTools` 也拦）；
② 往 `.claude/settings.json` 加 allow 规则（拒绝理由 `Self-Modification`）。

同一次记录里的解法：用户**亲手**加一条 allow 规则（如 `Bash(tools/handoff/dispatch.sh:*)`）。

## 证据

- 分类器对上述两类动作的拒绝理由分别为 `Create Unsafe Agents` 与 `Self-Modification`。
- ① 处另附「换 `--allowedTools` 也拦」。② **没有做过等价验证**——不要把①的括注套到②上。
- 附带一条：后台 Bash（`run_in_background`）在该版本下**不受 `timeout` 参数约束**
  （12s 睡眠在 5s 超时设置下跑完）。

证据等级：`verified_by: human` —— 来源是会话内的 prose 摘要（`capture:…`），无命令转录。
跑一次「改 flag 后是否仍被拦」的对照即可证伪，通过后可升回 `command`。

## 边界 / 反例

- capture 原文写「会拦**三类**动作」，但只列出了 ①②（第三类未记录）。本条只对**已列出的这两类**作陈述，
  id 里也不带计数——见到第三类的证据再补。
- 这是**单次观测**（2026-09-20 一个会话、一次 `/dispatch` 场景）；不要据此推断分类器的判定层级、
  也不要推断「试别的 flag 同样无效」——只测过 `--allowedTools` 一个。
- 「用户亲手加 allow 规则」是 capture 给出的做法；它为什么是唯一解（不可自动化的原因）capture 未记录。
- 后台 Bash 不受 timeout 约束是该版本的观测；capture 没有据此推过「长任务没有超时保护」，
  本条也不推——那只是这条现象的**后果之一**，不是实测结论。
