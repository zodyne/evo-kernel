---
id: tui-restyle-additive-not-subtractive
type: lesson
status: candidate
scope: global
domain: hermes-tui
tags: [hermes, tui, theming, claude-code, ui]
triggers:
  - "给 Hermes TUI 或同类 Ink/React 终端 UI 做 Claude Code 风格/极简风格改造"
  - "改造方案里出现『把工具调用行 / busy 动画藏进手风琴折叠面板或直接删除』的想法"
  - "改造后用户反馈『看不到工具在跑 / 看不到 busy 状态 / 信息没了』（失败信号）"
  - "评估一个主题皮肤，纠结『藏起来更干净』还是『全可见但更挤』"
created: 2026-08-15
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:4659d364-dabe-409a-b11c-258b78db277c
last_verified: 2026-08-15
superseded_by: null
schema_version: 1
related: []
---

主张：给 Hermes TUI 做 Claude Code 风格改造时，把官方默认可见的信息（工具调用行、busy 动画）藏进手风琴折叠面板或直接删除是「减法」——用户因此失去对工具执行/忙碌状态的可见性；Claude 风格的本质是信息全可见 + 每样一行 dim（降噪但不藏），是加法不是减法。

证据：v1 改造把工具调用行和 busy 动画藏进手风琴后失败，随即 `evo capture` 记下结论：「hermes TUI Claude 化 v1 失败教训:风格改造别把官方默认可见的信息(工具调用行/busy 动画)藏进手风琴或删掉——Claude 风格=信息全可见+每样一行 dim,是加法不是减法」，落到 inbox/capture-2026-08-13-02-09-12-476-9x5d.md。整场会话随后在 thinking.tsx / appLayout.tsx / appChrome.tsx 上做「每样一行 dim」式改造。

为什么：终端 UI 的默认可见项（工具调用、busy spinner）是用户判断「agent 在干什么 / 卡没卡」的关键信号；藏起来或删掉直接损害可观察性。Claude Code 之所以「干净」不是靠删信息，而是靠把信息统一成一行 dim 的低对比文本。

边界：本教训针对「风格改造 / 皮肤定制」，不针对功能性重构（删掉确属冗余的死代码另说）；「加法」指保留信息可见性，不代表不能折叠低频项（如元数据 / 协议噪声）。
