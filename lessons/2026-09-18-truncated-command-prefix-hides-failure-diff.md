---
id: truncated-command-prefix-hides-failure-diff
type: lesson
status: candidate
scope: global
domain: forensics
tags: [jq, shell, evidence-hygiene, truncation, reproducibility]
triggers:
  - "写长复合命令（变量赋值 + 绝对路径 + 内嵌 jq/grep 程序）跑取证/批处理查询"
  - "同一条命令的目标文件/程序只差一点，日志里却只留下同一段样板前缀（失败信号）"
  - "jq/grep 报错只回显程序开头（如 `line 1: select(.type=`），看不出写法差异（失败信号）"
  - "记录里同一条前缀的命令一败一成，事后无法复盘差异（失败信号）"
  - "要把失败命令与修复命令成对存档供事后比对"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e5b0-725c-a75a-f97e671dc5aa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [rg-o-window-search-in-jsonl-transcripts, pi-transcript-tool-args-encoding-is-per-tool]
---

# 长样板前缀吃掉命令的区分度：一次失败留下的是"和成功一模一样"的记录

## 主张

取证命令常被写成 `F=<长绝对路径>; jq -r '<程序>' "$F" | …` 这种复合形式。当执行记录按固定宽度截断时（切片/审计日志/CI 日志），**可见部分全是样板（变量赋值 + 路径），真正区分成败的那几个字符落在窗口之外**——于是失败与成功的记录长得**完全一样**，事后无法复盘成因（更谈不上把它变成教训）。做法：让**区分度前置**——先 `cd` 到目标目录再用短路径、把过滤器写成单行且短、复合命令拆成多条；被截断的是样板而不是关键差异。修好后把**失败命令与修复命令成对留档**（差异是唯一可复盘的东西）。

## 为什么

截断窗口是定宽的，样板是定长的：样板越长，留给"这次和上次到底差在哪"的空间越小。叠加第二个放大器——**工具自己的报错也只回显开头**：jq 的 `syntax error, unexpected INVALID_CHARACTER … at <top-level>, line 1: select(.type=` 只打印程序前 12 个字符，正好落在样板之后。两个截断叠起来，失败就成了一条不可解释的记录。

## 证据（本会话命令 ↔ 结果，切片逐字）

- 两条命令的可见前缀**逐字相同**（同为 `F=/Users/zodyne/.pi/agent/sessions/--Users-zodyne--/2026-09-14T08-47-35-627Z_01a09f19-aecb-710e-a57d-2538cf71db31.jsonl; jq -r 'select(.type=="message`，到窗口右界被切在同一处），结果却一个是失败、一个是成功：
  - 失败：`↳ ✗ jq: error: syntax error, unexpected INVALID_CHARACTER (Unix shell quoting issues?) at <top-level>, line 1: select(.type=`
  - 成功：`↳ ##### call_00_GH3r5WLjHSGxsPkYxJd19941 at 1789375715460 err=false [{"type":"text","text":"=== load config headless, capt`
  - 另一条同前缀的命令也成功：`↳ 检查分析我的nvim配置`
- 同一段前缀在切片里重复出现 6 次以上（`…jq -r 'select(.type=="message`），每条背后是不同的抽取逻辑——**要看差异只能看结果，命令本身提供不了信息**。
- 报错只回显程序头：jq 打印到 `line 1: select(.type=` 就没了（连出错字符都看不到），与命令截断叠加后成因完全不可考。

## 反例 / 边界

- **不是所有长命令都要拆**：一次性、不失败、不需要事后复盘的探索命令无所谓。代价只出现在"要复盘/要当证据"的场合。
- 拆分有反面成本：多条命令会增加调用次数与日志行数，也可能让原子性丢失（前段成功、后段失败）。判据是"这条命令的产物会不会被后人当证据读"。
- 前置区分度的做法要和"引号/转义"风险一起权衡：把过滤器写短通常也降低了引号出错的概率，但长程序仍有存在必要——那就落成脚本文件（`jq -f prog.jq`），文件名短且内容完整可查。
- 本条只管"记录里能不能看见差异"；命中窗口本身的信息量问题（jsonl 单行超长）见 related。

## 失败信号（未来命中即该想起本条）

- 复盘一条失败命令时发现：失败与成功的命令记录逐字相同，或只剩路径前缀。
- 报错信息停在程序/模式的开头（`line 1: <不到一行的程序>`），看不出错在哪个字符。
- 修复了却只记下"改好了"——没有把**修复前后**两条命令成对留下。
