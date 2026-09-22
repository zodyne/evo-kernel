---
id: single-segment-miss-is-not-a-gate-hole
type: lesson
status: validated
scope: global
domain: verification
tags: [acceptance-gate, adversarial, probe, libm, coverage]
triggers:
  - "复核『闸门/检查的某一段有漏报 ⇒ 闸门有洞』这类发现，准备判 confirm/refuted"
  - "审计多段验收闸门（源码正则扫描 + 产物符号扫描等），要判整体覆盖面"
  - "发现方只给出单一段的命中数就断言闸门失效（失败信号：没跑其它段）"
  - "写对抗探针验证闸门有没有假阴性，需要决定探针上跑哪些检查"
  - "闸门里一段正则报 0 命中，但产物 nm/objdump 里出现可疑符号（失败信号）"
created: 2026-09-19
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b753-cd18-7475-af70-36cd8df466ea
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [cpp-mode-libm-symbol-diff-per-tu, adversarial-review-separate-evidence-from-impact-attribution, blind-spot-claim-needs-instance-count]
---

## 主张

判「闸门某一段有漏报 ⇒ 闸门有洞」之前，必须在**同一批探针**上把闸门的所有段都跑一遍：单段命中数不能代表闸门覆盖面，一段漏掉的调用可能被另一段抓到；只有全段都漏（或不覆盖同一失败类别）才是洞。

## 为什么

验收闸门常是多段实现——本例是 C 段（源码正则扫描限定数学调用）+ B 段（产物 `nm -u` 查浮点 libm 符号）。发现方拿 C 段的 0/1 计数说「有洞」，只证明了 C 段的模式覆盖面；B 段是否覆盖同一失败类别，只能实测。

## 证据（切片命令 ↔ 结果）

对抗探针 harness 在同一批构造 TU 上同时打印两段结果：

- `injected_float`：`compile: OK   C-seg regex hits: 0   nm -u: _sinf    B-seg float hits: _sinf`
  —— C 段源码正则报 0，B 段符号层抓到 `_sinf`：同一调用被另一段覆盖。
- `injected_fptr`（`double probe( float x`）：`compile OK  C-seg hits: 0  nm -u: _sin  B-seg float hits: []`
  —— B 段对 double 形态没有误报（该段是真判据，不是无脑报警）。
- 真实树对照：`== core: qualified math calls (any) == NO-MATCH in core`（C 段在 `core` 上同样零命中）。

同会话最终裁决：该发现 `isReal = false` —— 其计数（1 / 0 / 0 / 0）精确复现，但「闸门有洞」的结论不成立（末条 assistant：`the finding is a toolchain-model misread, not a real gate hole`）。

## 边界 / 反例

- 只有另一段在同一探针上真的命中，才可判「不是洞」；若两段共因（同一输入源/同一模式族），两段同漏仍是洞。
- 探针必须覆盖被发现声称漏掉的那种写法；否则「没洞」和「有洞」一样没有证据。
- 本条只判「闸门整体是否漏」，不判被漏形态的实际影响面（实例数另计，见 `blind-spot-claim-needs-instance-count` 方向的条目）。
