---
id: located-quote-claims-must-be-grepped-in-source
type: lesson
status: candidate
scope: global
domain: review
tags: [review, verification, quotation, fabrication, transcript]
triggers:
  - "复核一份带位置标注（文件名/行号/toolResult 编号）的断言清单或审查报告"
  - "报告里引用了原文/日志/toolResult 里的一句话，要判它真假"
  - "抽查发现某条引文在源文件里 grep 不到（失败信号：疑似编造引用）"
  - "引文能搜到，但出处指错了文件或指错了调用（出处张冠李戴）"
  - "准备把一份引用密集的报告直接采信、入库或据此改代码"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a7ad-67d6-725c-a75a-f9894a03787a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pdftotext-md5-roundtrip-verify-corpus-integrity, adversarial-review-repro-as-written]
---

# 带位置的引文断言必须回到源里 grep 定位，「有位置标注」不等于引文真实

**主张**：复核报告时，凡带位置标注的引文类断言（"某个 toolResult 里写着 X"、"用户配置里有 `cmd = {...}`"），都要把**引文原文**丢回源 transcript / 源文件里检索定位一次；位置标注的存在只是报告者的自述，不构成引文真实性的证据。

**为什么**：引文是最容易被"顺手补全"的一类断言——写报告时凭印象补一句看起来该在那里的报错文本，是成本极低、且不跑命令就发现不了的错误。它同时污染两个层面：引文是否**存在**（凭空生成）与出处是否**正确**（真实文本被安到别的文件/调用上）。两者都要靠"回源检索"才能分开判。

**证据（本会话）**：对抗式复核中抽查 **11 处**带位置的断言，命中 2 处缺陷——
- 1 处**明确引用错误**：报告称结果"均为 timeout: command not found"，复核发现第二条 toolResult 里根本没有这串文本（引文不存在）；
- 1 处**出处张冠李戴**：`cmd = { "pi" }` 被算作"用户配置"，实际用户配置只有 `env = {...}`，`cmd` 来自插件目录（见另条提案 sidekick-pi-cli-cmd-defined-in-plugin-sk-dir）；
- 做法上确实做了回源检索：会话里用 `=== which toolResult contains tui-mode ===` 这类先定位"这句话在哪个 toolResult 里"的检索来核对出处。
- 诚实标注：本条验证强度为 human——"11 抽 2"是复核者自己的统计结论（末条 assistant 摘要），切片里没有逐条命令+结果的完整对账输出。

**边界 / 反例**：
- **grep 不到 ≠ 引文造假**：先确认所依据的源本身完整未损坏、抽取正确（见 related 的 pdftotext md5 回合校验），再下"引文不存在"的结论；
- 引文被**改写**（同义转述、截断省略）时 grep 会落空但不算造假——判据是"逐字引号内文本"是否与源一致，转述需另行标注为转述；
- 逐字复核成本随断言数线性增长，实务上按"关键结论 + 随机抽样"覆盖，但**抽样比例与命中缺陷数要写进复核结论**，不能只说"抽了没问题"。

**失败信号（未来命中即该想起本条）**：读到带引号的文本 + 位置标注就想直接采信；或复核结论里只有"已核对"没有"抽了几处、错了几处"。
