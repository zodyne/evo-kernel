---
id: transcription-json-balanced-escape-gate
type: playbook
status: candidate
scope: global
domain: document-processing
tags: [latex-transcription, json, validation-gate, escape, brace-balance, audit]
triggers:
  - "人工修订后的转写 JSON（latex/note/changed 字段）写回后要收口"
  - "怕手改 JSON 弄坏反斜杠转义、漏键或括号不配平"
  - "修订产物落盘后没跑校验就想宣告完成（失败信号）"
  - "批量核对修订文件：条目数、changed 计数、花括号配平"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad64-2a2e-7710-933f-0b6734543245
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [latex-string-backslash-escape-assert, scanned-book-formula-latex-compile-validation, transcription-compile-gate-not-semantic-correctness]
---

人工修订的转写 JSON 宣告完成前必须过程序门：①`json.load` 全量解析（反斜杠转义完整）②键集合与预期条目集双向核对（miss/extra 皆空）③每条 latex 花括号配平 ④changed 计数与逐条 reason 一致。四项全绿才收口。

**为什么**：修订产物下一站是程序消费（并入 chunk、编译验证），手改最常见的错误——反斜杠少打一层、漏一个键、括号失衡——要么到编译期才爆、要么静默错；四项检查把「结构完整」变成硬判据。本会话对 bold_audit.json（14 条黑体修订、改 11 条）依次跑四项全绿后才宣告 done。

**证据**（命令↔结果）：
- `OK 14`（全量 json 解析通过）；
- `keys: 14 miss: [] extra: [] changed: 11 ['p053-01', 'p055-09', 'p078-08', ...]`（条目集双向一致、changed 计数成立）；
- `all balanced & well-formed: True`（花括号配平）。
- 若要定位到具体坏条（json.load 只报解析失败、不指认哪条），加一条落单反斜杠断言 `assert '\\' not in l.replace('\\\\', '')`（先抵消成对 `\\`，剩单个 `\` 即漏转义）：本会话对 chunk01.json 跑该断言直接 Traceback 定位出坏条，修复后 `42 equations exit=0` 编译通过。

**边界**：配平检查只保证括号数量匹配，不保证语义分组正确（\frac 分子分母切错位置照样配平）——本门是结构门，语义忠实度另走编译门/抽验（见 related）。
