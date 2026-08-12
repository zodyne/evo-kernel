---
id: ab-reference-independent-of-compared
type: lesson
status: candidate
scope: global
domain: experiment-design
tags: [ab-test, validation, circular-reference, radar]
triggers:
  - "A/B 对照的参照集怎么来"
  - "对照组 100% 匹配好得可疑"
  - "用旧算法输出当新算法真值"
  - "循环论证的验证"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:40a7756a
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
---

**主张**：A/B 对照评估时，参照集若由被对照的某一方自己产出，该方的 100% 吻合是定义出来的、不算证据；必须补一个不依赖任何一方的独立检验。

**为什么**：实测过滤算法对照中，参照集是 legacy 跟踪器自己的航迹，legacy 行 100% 覆盖是同义反复。改用独立检验——直接看 GT 目标位置上**输入点**的标签与 SNR——才发现真问题：落在目标上的点 36.4% 被判 REJECT 且 SNR 中位 33.7 dB 比 KEEP 组还高，循环参照下这个代价完全不可见。

**边界**：独立 oracle 可以是原始输入标注、人工真值、或第三方法；合成真值若由独立生成器产出（非被测算法输出）也是合法 oracle，但只能作验收判据、不能作优化目标（否则退回调参自洽陷阱）。

**证据**：2026-07-29 ucm221 嵌入式移植会话，KEEP-only vs legacy 对照中剥掉循环论证后发现过滤代价。
