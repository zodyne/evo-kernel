---
id: blind-spot-claim-needs-instance-count
type: lesson
status: validated
scope: global
domain: code-review
tags: [static-analysis, severity, adversarial, gate, scope]
triggers:
  - "有人指控『检查器/闸门漏掉了形态 X』，要定这条发现的严重度或阻塞性"
  - "复核『正则漏掉某种写法』类发现，准备把它升级成阻塞项之前"
  - "报告里写『闸门无法检测 Y』却没有任何 Y 的实际出现次数（失败信号）"
  - "审计结论主张『有漏报面』，需要区分理论缺口与实际被放过的调用"
  - "在某个目录/scope 上搜某种写法零命中，要判断这能否支撑『无影响』结论"
created: 2026-09-19
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b753-cd18-7475-af70-36cd8df466ea
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [single-segment-miss-is-not-a-gate-hole, dup-key-overwrite-severity-by-payload-identity]
---

## 主张

有人指控「检查器/闸门漏掉形态 X」时，先在**该闸门覆盖的真实范围**里数 X 的实例数：出现 0 次 ⇒ 是理论缺口而非实际漏报，严重度/优先级按实例数定；但缺口本身仍要记录并修复（新代码随时可能引入该形态）。

## 为什么

「模式漏掉某种写法」与「有调用被放过」是两件事：后者还要求被漏的写法在扫描范围内真实存在。先把实例数数出来，能避免把模式覆盖面问题直接升级成阻塞项，也能给修复排优先级。

## 证据（切片命令 ↔ 结果）

在 `/Users/zodyne/Dev/algommw-plus` 里对 `core` 用比发现方更宽的模式搜限定数学调用：

`== core: qualified math calls (any) == NO-MATCH in core == core: parenthesized qualified call forms == NO-MATCH`

—— 连被声称漏掉的「括号包裹的限定调用」形态也一条都没有：该发现指控的漏报形态在 `core` 里零出现。
（同会话旁证：限定调用要到 core 之外才命中——`tools/parity/frame_source.cpp:238: const double dFr = std::floor( dUniform() * m_ulAdc );`。）

## 边界 / 反例

- 「零实例」是**当下快照**：只降低严重度，不撤销修复——新代码、别的 lane、生成代码都可能引入该形态。
- 数实例必须用**独立于被指控模式**的更宽模式；用有洞的检查器去证明「没有实例」是循环论证。
- 结论只对**已扫描范围**成立；换 scope（core → 全仓 / 生成物）必须重数。
- 与 `dup-key-overwrite-severity-by-payload-identity` 同属「严重度看实际是否有害」：那条按被覆盖 payload 是否相同定级，本条按被漏形态的实例数定级。
