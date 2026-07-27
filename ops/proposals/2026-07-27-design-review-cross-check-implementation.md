---
id: design-review-cross-check-implementation
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [design, review, blueprint, grounding, implementation-vs-design]
triggers:
  - 评审/修订一份"描述已部分实现系统"的设计文档（blueprint/architecture/RFC）
  - 设计文档主张某机制（注入范围、hook 触发点、状态机）但拿不准实现是否已如此
  - 想只读 design.md 就直接产出评审意见或修订版
  - 设计走查被指出"实现其实不是这样"
  - 对已有原型的系统做 greenfield/迭代设计评审
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:64181609-8d44-4e81-8fba-4fb21b13f7ce
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# 评审"描述已部分实现系统"的设计文档，必须交叉核对实现，不能只读设计文档本身

## 主张
当被要求分析/修订一份**描述一个已经部分实现（有 bin/源码、测试、运行配置）的系统**的设计文档时，评审动作不能只停留在设计文档内部：必须把设计里的机制性主张（注入哪些目录、哪个 hook 在哪个时机触发、状态机如何迁移、是否 fail-open）逐条与**实际实现 + 测试 + 配置**交叉核对，再据此给"指导性/实施性"意见或产出修订版。只读 design.md 评审，会冒"背书或重写一个与实现已经漂移、或实现早已反驳的主张"的风险。

## 为什么
设计文档是"意图快照"，实现是"事实当前态"，二者会漂移。本会话正是靠交叉核对把设计主张转成了可验证事实：
- 设计/SCHEMA 称"candidate(lessons) 默认不注入"——`grep RECALL_DIRS bin/evo` → `['playbook','facts','episodes','principles']` **证实**实现与设计一致，于是评审该机制时可放心引用而非臆测。
- `bash test/smoke.sh` → ✓ 通过，**证实**被设计的系统真实可运行（不是空想中的架构），评审才有落地意义。
- `python3` 读 `~/.claude/settings.json` → 真实 hook 接线（`UserPromptSubmit→hook-recall`、`SessionEnd→hook-session-*`），印证设计里的 hook 事实。
- `grep blueprint.md` → fail-open 第一原则文本，确认设计内核原则成文。

这些命令把"设计声称 X"降级为"经实现/测试验证 X 成立"，修订版（blueprint-v4.md）才建立在事实而非文档自我引用上。

## 证据（本会话命令 ↔ 结果，切片硬证据）
- `grep -n "RECALL_DIRS" bin/evo` → `33:const RECALL_DIRS = ['playbook', 'facts', 'episodes', 'principles']; // candidate(lessons) 默认不注入` —— 设计主张与实现一致，获验证。
- `bash test/smoke.sh 2>&1 | tail -8` → `✓ sol...` —— 系统实测可运行。
- `python3 ... settings.json hooks` → `UserPromptSubmit -> .../evo hook-recall`、`SessionEnd -> .../evo hook-ses...` —— 真实 hook 接线印证。
- `grep -n "§10|准入四条件" blueprint.md CONVERGENCE.md` → 命中 blueprint.md 的 fail-open 第一原则。
- 写出 `/Users/zodyne/Dev/agent-evo/design/blueprint-v4.md`（修订基于上述实现事实）。

## 边界 / 反例
- 纯**绿地设计**（系统尚未有任何实现/原型）无法交叉核对实现——此时评审只能基于设计内部自洽与第一性原理（参见 `independent-design-review`：评审者看全文、不参与设计、意见分指导性/实施性、逐条裁决）。本条只针对"已有实现"的设计评审。
- 不是"读每一行源码"——只核对设计中**会被你引用/背书/重写的机制性主张**（目录范围、hook 时机、状态机、原则），不发散到全量代码 review。
- 与 `verify-external-references`（外部 id/URL/字段名使用前必验）互补：那条管"外部引用"，本条管"设计主张 vs 自家实现"。

## 失败信号（未来命中即该想起本条）
- 评审意见引用了某机制，但被指出"实际 bin/源码里不是这样"。
- 仅基于 design.md 给出"指导性建议"，未跑过 `grep/sed bin`、未跑过 smoke/测试、未读过相关 schema/convergence。
- 修订版设计的主张与现存实现互相矛盾、或重复实现已解决的问题。
