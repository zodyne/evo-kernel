---
id: refs-json-count-range-contiguity
type: lesson
status: candidate
scope: global
domain: transcription
tags: [verification, json, numbering, acceptance, external-artifact]
triggers:
  - "引用/合入外部生成的编号产物(JSON/清单),要写验收检查"
  - "转写/抽取产物要交付,想证明无漏条无重号"
  - "产物统计只报了总数,想确认编号无缺口"
  - "抽查发现某编号缺失但总数对得上(失败信号)"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad8f-3d4d-7710-933f-0b7310898577
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [verify-numbered-list-full-coverage-by-regex-count]
---

引用外部生成/外部维护的**编号产物**(如文献转写 JSON、带编号的抽取清单)时,验收检查必须包含三件套:**条目数 n + id range 两端(min/max)+ id 序列无缺号无重复(contiguous)**,不能只看 n。

**为什么**:range 连续是「无漏条、无重号」的强校验。单看 n 无法发现中段缺号——例如预期 54..121 共 68 个编号,若中段丢 1 条又多 1 条重复,n 仍是 68;只有把 sorted(id) 与 range(min, max+1) 逐点比对才能暴露。外部产物的计数自述(「共 68 条」)属于生成方的 self-report,验收方不能沿用作结论。

**证据**(GroupTracker 会话,命令+结果):`python3` 读 `meta/latex/refs_b.json`,输出 `n 68 range 54 121 contiguous True en 16 zh 52 unc 16 missing-key keys? []`——一行同时确认总数、两端、连续性、无坏键,作为 p164–p166 文献转写产物(54..121 编号段)的验收依据。

**边界**:id 非纯数字编号的产物不适用 range 检查,退化为 set 去重 + 与预期全集做差集;range 连续只证明编号覆盖完整,不证明每条内容正确——内容正确性由逐条核对/抽样审计负责,两者互补。

**失败信号**:抽查发现某编号缺失但总数与预期一致;或只报了 n 就想宣告产物完整。
