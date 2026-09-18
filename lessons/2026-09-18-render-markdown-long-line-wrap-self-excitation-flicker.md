---
id: render-markdown-long-line-wrap-self-excitation-flicker
type: lesson
status: candidate
scope: global
domain: nvim
tags: [nvim, render-markdown, wrap, conceal, flicker]
triggers:
  - "nvim 打开 md 文件，长行超过窗口宽度时整屏闪烁/光标闪烁无法阅读"
  - "render-markdown.nvim 插件下 wrap/conceallevel 来回跳"
  - "markdown 含超长行（无换行的长段落/长链接）时显示异常"
  - "用 render-markdown 预览，行宽一超过窗口就卡/闪"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad58-5cb3-74a5-bda5-47c14fb2ba3a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---
render-markdown.nvim 打开含超窗口宽度长行（本会话 1962 字符）的 md 文件时，其「是否渲染」判断里带 `win` 的 wrap 状态，wrap 在 true/false 间自激翻转、连带 conceallevel 反复 set，导致整屏闪烁无法阅读。根因证据：repro2.log 在 8.4–9.0s 窗口内 SET wrap/conceallevel 2913 次（337 writes/s）；源码 `core/ui.lua:105` 应用 `config.win_options`、`api.lua:77` 调 `modify_anti_conceal(1)`，`doc/limitations.md` 已标注「Concealed text keeps unnecessary line breaks [ISSUE #82]」。修法：在 plugins/init.lua 的 render-markdown opts 里切断其对 wrap 的干预（win_options.wrap / anti_conceal），提交 1456728 落地。
