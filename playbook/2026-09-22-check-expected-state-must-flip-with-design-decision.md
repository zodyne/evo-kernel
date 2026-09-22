---
id: check-expected-state-must-flip-with-design-decision
type: playbook
status: validated
scope: global
domain: verification
tags: [deployment-check, doctor, expected-state, design-flip, stale-assertion, self-check]
triggers:
  - "翻转一个设计决定之后（接入→退役、启用→停用、开→关），自检脚本还留着旧决定的预期值"
  - "部署自检把「正确的新状态」报成异常并建议改回去（失败信号：判据在说反话）"
  - "自检项的措辞看起来对，但它的「预期状态」是上一版设计写的"
  - "一个自检项把 PASS 给了本该警惕的状态、把 WARN 给了本该是常态的状态"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:2a5c9cfe-7ff2-46f2-800e-c160ffe842a5
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [coverage-denominator-is-a-moving-target, count-only-acceptance-gates-miss-value-drift, doc-selfreported-counts-drift, milestone-status-claims-conflict-in-repo, mount-check-must-verify-ownership-not-existence]
---

# 设计决定翻转后，自检项的「预期状态」必须跟着翻——否则判据会变成反话

**主张**（范围：deployment-check / doctor 这类「预期值 + 建议动作」型判据；本次实例 n=1）：
判据的正确性主要落在它的**预期状态**上。当一个设计决定被翻转（本次：Claude Code 由
「有意不接入」改为「接入」），当旧文案**给出的行动本身是破坏性的**（如「建议清理」）时，旧预期没跟着翻的自检项会
**主动把下一个执行者引向错误动作**：它会把自己刚装好的正确状态报成「残留，建议清理」。

本次实例：`doctor` 第 6 项在退役期的文案是「**Claude hooks 已退役确认**，预期无挂载」，
把「无挂载」判 PASS、「有挂载」判 WARN 并提示「残留旧挂载（pi 已退役，建议清理）」。
挂上三件套之后再跑，它报的正是这句——**任何照着它做的人都会把刚接好的 hooks 拆掉**。

> **同源**：本条与 `mount-check-must-verify-ownership-not-existence` 出自**同一次** doctor 第 6 项重写
> （commit `db6fd48`）——**一次观测被拆成两条**，别当两条独立的经验计权。

## 证据（2026-09-22，命令 ↔ 结果）

- 挂载前后同一条命令的对照：
  挂载前 `[PASS] 6. Claude hooks 已退役确认  已退役（预期无挂载）`
  → 挂载后 `[WARN] 6. Claude hooks 已退役确认  残留旧挂载（pi 已退役，建议清理）: UserPromptSubmit, SessionEnd, PreToolUse`。
- 改判据后同一状态报 `[PASS] 6. Claude hooks 挂载确认  三件套已挂载`；smoke 组 K 从 2 条扩到
  4 条对照（未挂 WARN / 齐+同仓 PASS / 指向他处 WARN / 部分挂载 WARN），`npm test PASS=149 FAIL=0`。

## 边界 / 反例

- 本库的**编号刻意不回收**（删掉的检查项留空号，见 `bin/evo` 检查项编号与 README 部署门表），
  这是惯例问题；**名字改不改没有定论**——本次实际做法是改了（「已退役确认」→「挂载确认」）。
  必须改的是**预期值**与**建议动作**：旧文案给的行动（「建议清理」）在新决定下正好是错的。
- 判据该 PASS 还是 WARN 取决于「错的那一侧有多坏」：本库把「未挂载」判 WARN 而非 FAIL，
  因为内核不依赖任何 harness 也能跑；这条取的是**可见性**（静默才是真问题），不是严重度。
- 只在**有人拍板翻转决定**时才触发；决定没翻而判据报异常，那是判据在正常工作。
- 与 `doc-selfreported-counts-drift` 是近亲但不同：那条讲文档自述的**数字**漂移，
  本条讲自检项的**预期状态/建议动作**漂移。两者危害的**比较**（谁更危险）本条未度量，不下结论。
- 范围收窄到「**预期值 + 建议动作**」型判据（deployment-check / doctor 一类），
  不是所有自检项：只报噪声、不给可执行动作的判据并不会「引向错误动作」。
