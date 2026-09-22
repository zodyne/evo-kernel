---
id: claude-auto-mode-classifier-uses-own-model
type: lesson
status: candidate
scope: global
domain: claude-code
tags: [claude-code, auto-mode, classifier, billing, router, env-vars]
triggers:
  - "主模型走网关/第三方，却发现 Anthropic 侧仍持续有调用量"
  - "想知道 Claude Code 的 auto 权限分类走的是哪个模型"
  - "试过用环境变量把 auto 模式的分类模型指到便宜模型，但没生效"
  - "router/网关日志里出现大量 sonnet 调用，推理不出是谁在打"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:inbox/capture-2026-09-22-07-53-40-927-ivvi
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [claude-auto-classifier-blocks-two-action-classes, auto-approval-classifier-outage-blocks-bash, claude-code-nanoradar-gateway-settings, claude-model-slash-command-global-default]
---

# Claude Code 的 auto 权限分类走它自己的模型，与主模型无关

**主张**：`permissions.defaultMode: "auto"` 下，**每次工具调用**都由 **claude-sonnet-5** 做权限分类，
走 `api.anthropic.com`（**订阅额度**）—— 即使主模型是别的（本例 deepseek-v4-flash 经本机 claude-router 走网关）。
触发点是 Bash 命令**静态 AST 解析不了**时回退到模型分类。
`CLAUDE_CODE_AUTO_MODE_MODEL` 这个 env 在 **CLI 2.1.277** 里**无效**（隔离端口做过 A/B：
deepseek-v4-flash 与 claude-haiku-4-5-20251001 两个名字都不生效）。要止住这笔流量，只能关 auto mode。

## 证据（来自 capture，**prose 摘要、无命令转录**）

- router 侧 30 小时窗口：**5752 次**打 Anthropic，其中 **5727 次**是 sonnet-5。
- 隔离端口的 A/B：`CLAUDE_CODE_AUTO_MODE_MODEL` 设两个不同的模型名，均不生效。

**证据等级 `human`**：本条的一手来源是 inbox 里的 prose capture，**没有命令 ↔ 结果的转录**
（按本库口径，这类不够 `command`——见 `evidence-grade-is-command-record-not-observed-wording`）。
升级路径：**跑一次 router 日志的按模型分组统计**（`grep` 出 anthropic 上游那段、按 model 字段
`sort | uniq -c`），跑出来即可升 `command`；`CLAUDE_CODE_AUTO_MODE_MODEL` 那条同样可用
「设了之后 router 侧 sonnet 计数是否下降」当场证伪。

## 边界 / 反例

- 版本相关（2.1.277）；换版本先复核 env 是否仍无效、分类是否仍走 sonnet。
- 「每次工具调用」是本例观测的粒度；**不是**所有工具调用都会走到模型分类 ——
  能被静态解析的 Bash 命令走的是规则路径（本条的触发点正是「解析不了时才回退」）。
- 与 `auto-approval-classifier-outage-blocks-bash` 是同一机制的两面：那条讲分类器**挂了**
  会把命令拒掉、报错长得像命令有问题；本条讲它**在跑**时流量计在谁的账上。
- 不主张「必须关掉 auto」：这是个成本/便利的取舍，本条只把账目说清。
