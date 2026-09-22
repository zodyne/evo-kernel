---
id: card-title-guard-term-is-not-include-guard
type: lesson
status: candidate
scope: project:algommw-plus
domain: verification
tags: [algommw-plus, p1.0b, include-guard, terminology, grep, false-positive, ledger]
triggers:
  - "在 algommw-plus P1.0b 台账里搜『守卫 / guard / include guard』，判断头文件守卫是否已被规划或覆盖"
  - "看到卡名『命名空间 + libm 守卫』就以为 include guard 已在这张卡的处理范围（失败信号：同词不同义）"
  - "审计 P1.0b 对 redefinition / 多重包含 的提及情况"
  - "grep 关键词命中了文档标题就准备下『已被覆盖』结论"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-eca1-7475-af70-36bc7743f28f
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [algommw-plus-core-headers-ifndef-guard-convention, inline-constexpr-header-still-needs-include-guard, zero-include-header-still-has-includers]
---

# algommw-plus P1.0b：台账里的「守卫」命中只是卡名，不等于 include guard 已覆盖

## 主张

在 `docs/ledger/2026-09-18-P1.0b/` 里搜 `redefinition|include guard|unguarded|多重包含|守卫|guard`，唯一命中是 `REPORT.md:1` 的卡名「卡 P1.0b（命名空间 + libm 守卫）」；对 PLAN/audit 的同类搜索得到 `NO mention in PLAN/audit`。因此标题里的「守卫」不能当作 include guard 已规划/已覆盖的证据——P1.0b 这张卡的台账对 include guard / 重定义零提及。

## 为什么

「守卫」在 P1.0b 的卡名里与 include guard 不是同一个所指（`REPORT.md` 标题与 PLAN 的动作清单里都没有任何 redefinition / 多重包含 / include guard 的措辞）。关键词检索是审计覆盖面的常用手段，但命中标题/命名时只证明「这个词被用作名字」，不证明「这个话题被处理过」；把名字命中当覆盖证据，会直接漏掉「缺 include guard」这类发现——本会话的复核正是确认了这条发现事实成立。

## 证据（切片命令 ↔ 结果）

- `cd /Users/zodyne/Dev/algommw-plus/docs/ledger/2026-09-18-P1.0b && rg -n -i "redefinition|include guard|unguarded|多重包含|守卫|guard" . || echo "NO mention …"` ↳ `./REPORT.md:1:# REPORT · 卡 P1.0b（命名空间 + libm 守卫）—— 受阻，未完成`，随后 `==== NO mention in PLAN/audit …`（切片在该处截断）。
- 同会话台账标题旁证：`rg -n "P1.0b" …` ↳ `docs/ledger/2026-09-18-P1.0b/REPORT.md:1:# REPORT · 卡 P1.0b（命名空间 + libm 守卫）—— **受阻，未完成**`。

## 边界 / 反例

- 这是 2026-09-19 前后台账的快照；若后续卡片/PLAN 补写了 include guard 要求，本条需重查。
- 切片未展示「libm 守卫」在卡里的定义；本条不解释该词具体指什么，只主张「它不是 include guard 的覆盖证据」+「台账对 include guard/redefinition 零提及」。
- 反向不成立：搜不到不代表永远不会有——零命中只能证明「搜索时点未覆盖」，修复/评审动作仍要做（同批提案 `inline-constexpr-header-still-needs-include-guard`、`algommw-plus-core-headers-ifndef-guard-convention` 给出了机制与风格约定）。
- 与 `zero-include-header-still-has-includers` 同属「名字/字面命中 ≠ 语义覆盖」，但那条针对代码消费者，本条针对台账术语。

## 失败信号（未来命中即该想起本条）

- 审计结论写「P1.0b 已包含守卫处理」而唯一依据是卡名/标题里的「守卫」二字。
- `grep 守卫` 命中列表只有文档标题，却被当成规划覆盖。
