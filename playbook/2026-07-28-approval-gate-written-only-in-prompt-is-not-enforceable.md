---
id: approval-gate-written-only-in-prompt-is-not-enforceable
type: lesson
status: validated
scope: global
domain: agent-safety
tags: [guardrail, human-in-the-loop, prompt-injection, invariant, evo-kernel]
triggers:
  - 设计"某操作必须先经人工确认"的门槛，把它写进 SKILL.md / 系统提示词
  - 声称某个不变量是"人审前置"，但执行者就是被约束的那个 agent
  - 自进化系统里，agent 有权调用批准自己更新的那条命令
  - 复核安全边界时问"这条规则被绕过会怎样"，答不上强制机制在哪
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
related: [warn-rule-must-be-visible-to-user, doc-selfreported-counts-drift]
---
# 只写在提示词里的人审门不是执行边界：agent 能调用的命令，就等于没有人审

## 主张
"X 操作必须先经用户确认"如果只以自然语言写在 SKILL.md / 系统提示词里，而被约束的 agent 本身有权调用 X，那么这个门槛**是一条建议，不是边界**——它会被忽略、被上下文挤掉、被提示注入改写，且失效时无任何信号。要让它成为边界，必须由 agent 改不动的机制（工具层拦截 / 权限分离）执行。判据很简单：**问"绕过它需要 agent 做什么"，如果答案是"什么都不用做，照常调用即可"，那它就不是门。**

## 为什么
Evo-Kernel 的 I3 不变量写着"curate 是唯一入库口（含脱敏 + 指令样内容审查），人审前置"。但执行层是：`skills/evo-learn/SKILL.md` 结尾一句散文——"提案未获用户确认前不要 curate"。而 `bin/evo curate` 本身只校验 schema、敏感信息、指令样内容三项，**没有任何人审校验**；agent 可以直接 `Bash: evo curate --file ... --to playbook` 把自己写的提案写进注入集。

这恰好命中自进化系统的第三道安全边界——**批准自身更新的验证器、发布门槛、审计日志不可被自我修改**（《大模型与 Agent 开发实战》ch8「持续进化的安全边界」）。否则一个 agent 只需降低阈值或跳过门槛，就能把退化伪装成进步。在 Evo-Kernel 的形态里，这意味着一条未经人审、甚至源自被注入网页内容的"经验"可以进入 recall 集，从此每次会话持续生效。

代价不对称：门在正常情况下从不触发（agent 通常照 SKILL.md 执行），所以它失效时也毫无迹象——这类"平时看不出坏"的缺口只能靠机制补，不能靠观察补。

现成机制已经在库里：`ops/constraints/` + `hook-guard` 就是 agent 改不动的工具层拦截，当前只用了一条 `dangerous-rm-rf`。把 guard 用在内核自己的写入口上即可，无需新造机制。

## 证据（本会话命令 ↔ 结果）
- `sed -n '1,50p' skills/evo-learn/SKILL.md` → `- 提案未获用户确认前不要 curate。`（门槛的全部实现，散文一句）
- `sed -n '/^  curate/,/^  [a-z-]*:/p' bin/evo` → 校验项仅：schema 缺字段 / 敏感信息正则 / 指令样内容正则；**无人审校验、无交互确认**
- `ls ops/constraints` → `dangerous-rm-rf.json`（唯一一条，未覆盖内核自身写命令）
- blueprint-v4 §2.2 I3 声明"人审前置"——文档不变量与执行现状之间的落差即本条

## 边界 / 反例
- **不是所有软门槛都要硬化**：低风险、可逆、误触成本小的操作（如 `evo capture` 写 inbox）硬化只会增加摩擦。判据是"失效后果是否持久且不可见"——curate 写进注入集属于持久且不可见，capture 不是。
- 硬化本身有误报代价：constraint 是子串匹配，无法区分"执行"与"提及"，commit message 里出现 `evo curate` 也会命中。因此应按 §8 准入走 `mode: warn` 观察期，攒够命中样本复核误报率再升 block（见 `warn-rule-must-be-visible-to-user`）。
- 单用户单机场景下，**风险不来自恶意 agent，而来自被注入内容 + agent 的顺从性**。别把这条读成"不信任自己的 agent"，读成"不信任流经 agent 的外部内容"。

## 失败信号（未来命中即该想起本条）
- 复核安全边界时，某条不变量的执行机制指向一段自然语言指令。
- 发现库里出现自己没批准过的条目，或提案跳过评审直接进了注入集。
- 有人问"这条规则怎么保证不被绕过"，只能回答"skill 里写了"。
