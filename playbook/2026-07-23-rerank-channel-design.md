---
id: rerank-channel-design
type: lesson
status: validated
scope: global
domain: retrieval
tags: [rerank, recall, small-model]
triggers:
  - "recall 召回质量差"
  - "实现 P1.5 rerank 通道"
  - "grep/triggers 漏召"
created: 2026-07-23
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: blueprint:v2 §6
last_verified: 2026-09-14
superseded_by: null
---
设想（待 P1.5 验证）：recall 增加小模型 rerank 通道——把 manifest 全量一行摘要（id+claim+triggers）喂一次小模型调用做相关性筛选，成本可忽略、召回质量应远超纯词匹配。
**待验证**：真实命中率提升幅度；endpoint 配置缺失/调用失败时必须静默降级回 P1 通道（fail-open）。
**判据**：注入精度（对账的「注入但无关」占比）对比 P1 基线。
**形态 B（2026-07-23 已实现）**：主 agent 即大模型精筛器——`evo candidates`（粗筛清单）+ `evo get --ids`（拉全文），零额外模型调用、无 hook 超时风险。若 agentic 模式命中率足够，P1.5 内嵌 rerank 可能被跳过。CLI 内嵌大模型不推荐：成本/延迟/key 管理 + hook 链路 fail-open 风险。

**✅ 2026-09-14 验证（本条目此前因 `verified_by: none` 被归档，当日补测后恢复）**

用新建的穷举盲标评测集（20 query × 76 条 = 1292 对全标注，标注者对系统输出盲）测得：

1. **P1 词法层的天花板是测出来的**：降到 `relevance >= 0.10` 时 recall 也只到 **63%**
   （而 precision 已崩塌到 18%）⇒ **37% 的真相关对在词法上完全够不着**，任何阈值都救不了。
2. **阈值本身已近最优**：代价闭式解（按实测漏/误 = 3.44）给出 0.225，与实测曲线吻合；
   从 0.25 挪到 0.225 只买 +7pp recall / −3pp precision ⇒ **调阈值不是杠杆**。
3. ⇒ **结论：词法层不可能独立达到可用召回，形态 B 不是"可跳过的优化"而是"必需的通道"。**

**⚠️ 本条目原始判据写错了侧**：原文的判据是「**注入精度**（对账的「注入但无关」占比）对比 P1 基线」。
实测显示约束在**召回**侧（漏 31 : 误 9 = 3.44），只测精度会让"少注入"永远像改进。
**正确判据应为：召回率与漏/误比（对 P1 基线）。**

**⚠️ 形态 B 已实现但从未被启用**：`~/.pi/agent/primer` 与 `primer.md` 里**一个字都没提**
`candidates` / `get --ids` —— 唯一能做语义匹配的实体（agent）无从知道这条通道存在。
所以 P1 词法层被迫承担了它做不到的语义职责。**这是路由失效，不是算法不足。**
