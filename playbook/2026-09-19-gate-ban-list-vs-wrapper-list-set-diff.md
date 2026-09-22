---
id: gate-ban-list-vs-wrapper-list-set-diff
type: lesson
status: validated
scope: global
domain: verification
tags: [gate, name-list, set-diff, drift, facade, contract]
triggers:
  - "门禁脚本用一张名字表禁用一批函数，同时另有一层合规包装/替代 API（wrapper / facade）"
  - "两处手工维护的名单（禁用清单 / 替代实现清单）怀疑已漂移（失败信号：只有一边新增了函数）"
  - "评审『门禁 + 替代层』双层设计，要判有没有『被禁却无合规替代』的死角"
  - "新增或删除一个被禁函数/包装函数后，没有断言两份名单覆盖同一集合"
  - "要核对两份名字清单是否一致，却只靠人工目视比对"
created: 2026-09-19
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b754-1b2d-7475-af70-36d1c8e07a6e
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [libm-call-audit-via-artifact-symbols, ctypes-argtypes-table-drift-silent-cint-restype, dual-repo-copy-drift-fails-golden-first-diff]
---

# 「禁用名单」与「合规替代名单」必须机器化做集合差，差集非空要逐项解释

## 主张

当门禁用一张**名字表**禁止一批函数、同时又提供一层**合规替代/包装层**时，这两张名单是同一份契约的两种表示，必须用集合差核对（而不是假定一致）。本会话实测：门禁 B 段的禁用名单 **31** 个名字，D10 包装层只有 **20** 个名字，`B-D10 = 11` 个名字**被禁但没有合规替代**——需求方要么绕开门禁、要么无路可走。差集里的每一项都必须给出解释：补上替代、或把该名字从禁用表中删掉；不能默认「反正没人用」。

## 为什么

两张名单通常写在两个不同的载体里（本例：门禁脚本里的正则常量 `tools/libm_gate.sh` vs 设计文档/探针头里的 D10 包装清单 `PLAN.md:865`），改动时几乎不会同步——禁用面比替代面宽出的部分就是**静默死角**：门禁照样报绿（没人调用被禁函数），而合法需求一旦出现就被卡死，且没有任何错误信号。

## 证据（切片命令 ↔ 结果）

1. 用 python 分别解析两份名单做集合差：
   `python3 - "$B_DIR/tools/libm_gate.sh" "$B_DIR/PLAN.md" …`
   ↳ `B段 count: 31`；`B段: ['sin', 'cos', 'sincos', 'tan', 'asin', 'acos', 'atan', 'atan2', 'sinh', 'cosh', 'tanh', 'exp', 'exp2', …]`
2. 收口输出：
   ↳ `### 1. set diff (script over tools/libm_gate.sh + PLAN.md:865)  B段: 31 names; D10: 20 names; B-D10 = 11 = sincos sinh cos…`（切片在此截断）
   —— 差了 11 个：`sincos sinh cosh tanh cbrt trunc fmin fmax ldexp frexp` 一类（同会话另有一条命令用这 11 个名字作为 `rg` 交替模式在 `core` 里找用法，可交叉对照）。
3. 该次对抗复核的裁决（末条 assistant）：`判定：真问题（isReal = true），严重度维持 risk，不是 blocker`，四类推翻尝试全部失败，第 1 条即 `名单差集成立`。

## 边界 / 反例

- 差集非空**不必然**等于「缺替代」：差集里的名字有的可能压根不可能出现在源码里（如 `sincos` 只由编译器融合产生，见 related「真值层是产物符号表」）；此时正确的动作是把该名字从禁用表剔除，而不是补包装。每个差集项都要落到「补替代 / 删禁用项」两者之一。
- 方向要写清：本会话是「禁用清单 ⊃ 替代清单」，不是反过来（反过来是替代层供了没人禁的函数，属另一类冗余）。
- 解析名单前先确认两份来源是**同一口径**（本例：脚本里的正则常量 vs 文档里的 D10 清单），口径不同会得到一个假的差集。
- 本条只断言「差集必须被算出来并逐项解释」，不判这 11 个具体名字该补还是该删。
