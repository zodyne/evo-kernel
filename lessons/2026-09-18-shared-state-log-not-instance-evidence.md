---
id: shared-state-log-not-instance-evidence
type: lesson
status: candidate
scope: global
domain: nvim
tags: [nvim, mason, log-attribution, evidence-strength, forensics]
triggers:
  - "用 mason.log / stdpath(\"state\") 下共享日志里的一行，去证明某个 nvim 实例执行了某动作（如被转发的 :checkhealth）"
  - "排查『nvim 里跑 agent 后宿主退出』，要判定到底是 host 还是 guest 执行了某条命令（失败信号：拿共享日志命中当实例级证据）"
  - "多个 nvim 实例共用一份状态文件/日志，要把某行日志归属到具体实例"
  - "对抗复核追问『谁执行了 X』的独立证据，而手上只有一份跨实例共享的日志"
  - "准备把 mason.log 的命中写进根因结论或排查报告"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a7a8-aee1-725c-a75a-f97991f2e9a9
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [nvim-log-lines-carry-pid-for-instance-attribution, flatten-nvim-nest-headless-crashes-host]
---

# 跨实例共享的状态日志（mason.log 等）命中一行，只能证明「发生过」，不能证明「是哪个 nvim 实例做的」

**主张**：位于 `stdpath("state")` 下的共享状态日志（本案例是 mason.log；同目录的 nvim state 文件同理）是**一台机器一份、所有 nvim 实例共写**的文件。它里面出现一行记录，只能支持「这个动作在本机发生过」，**不能**支持「是 host 实例执行了它（而不是 guest/另一个终端里的实例）」。当要论证的因果链恰好是「谁执行了这条命令」时，共享日志在这条链上是零信息甚至误导——必须换成带实例唯一键的证据（行内 pid / 实例 id / per-instance 文件）。

**为什么**：guest nvim（`--headless` 的体检、flatten 嵌套实例）与 host 写的是同一个 state 文件，谁也不在行里留自己的身份。所以「mason.log 里有这条 :checkhealth」与「host 执行了被转发的 :checkhealth」之间缺了一环：动作确实发生过，但执行者未定。把两者当同一件事，等于用一个不区分主体的观测去闭合一条以主体区分（host vs guest）为核心的结论——本会话里这条链正是被对抗复核打回的。

**反例 / 边界**：
- 不等于「mason.log 没用」：证明某动作在本机发生过、给时间线排序、判断先后顺序，它仍然有效；只是不能承担**实例归属**。
- 判据是「行内/路径里有没有实例唯一键」，不是文件叫什么：`nvim.log` 每行内嵌 `ui.<pid>`，那种日志就能做归属（见 `related` 的正向条目）；反之，无实例键的共享文件一律只能当「发生过」级证据。
- 单实例、无并发 nvim 时该文件只有一个写入者，「共享」不构成风险；风险只在多实例并存（host/guest、多终端、agent 起的嵌套实例）时出现——而「nvim 里跑 agent → 闪退」的排查恰好天然处在多实例场景。
- 反向不成立：共享日志里**没有**某行，不能推出「没人执行过」——写入路径可能根本不经该文件。

**证据（本会话切片 01a0a7a8）**：
- 命令：`… jq -r 'select(.index==1…' "$D"/…` （读 pi 子代理任务产物）→ 结果：`{"refuted":false,"counterpoints":[{"point":"mason.log 不能独立证明「宿主执行了被转发的 :checkhealth」——mason.log 是共享状态文件（stdpath(\"state\`（切片按 120 字符截断，可见部分至此）。
- 同批子代理产物的 HEADLINE：`flatten.nvim 把嵌套 nvim 的 +qa! 转发给宿主执行 → 宿主退出，连带杀死 nvim 终端里的 pi`；REFUTED HYPOTHESES 段第一条：`nvim 是段错误/硬崩（segfault / OOM / abort）退出的 → ~/Library/Logs/DiagnosticReports/ 100 个文件里 rg -i '…'`（本会话另有命令 `ls -la ~/Library/Logs/DiagnosticReports/ | rg -i 'nvim|node'` 的对应输出段为空 → 无崩溃报告）。即：主结论（flatten 转发退出）成立，但其中「宿主执行了 :checkhealth」这一步的证据被复核判为**不独立**。

**诚实标注**：本条的直接证据是本会话里**对抗复核子代理的 counterpoint 文本**（复核结论为 `refuted:false` + 该条 counterpoint 保留），不是本会话亲手跑实验得到的；切片未逐字显示 mason.log 的文件路径与内容，`stdpath("state")` 这一属性来自该 counterpoint 的表述。故 `verified_by: human`。复核者一条命令即可升级为 command：`rg -n '<pattern>' ~/.local/state/nvim/mason.log | head` 看行首是否带 pid/实例标识（不带即证实「无实例键」）。

**失败信号（未来命中即该想起本条）**：报告/结论里出现「宿主执行了 :checkhealth，证据是 mason.log 里有这行」；或复核时被问「这条日志凭什么说是这个实例写的」而只能答「时间对得上」。
