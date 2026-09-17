---
id: hashline-withdrawn-tool-name-conflict
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [hashline, pi-extension, tool-name-conflict, claude-look, cc-rendering, registerTool]
triggers:
  - "装 hashline（pi-hashline-edit-pro）后 pi 启动报 Tool read conflicts"
  - "两个扩展都注册同名内置工具（read/edit），启动即冲突（失败信号）"
  - "pi-cc-extensions 富 diff 只认 edit/write，replace/insert 拿不到 CC 渲染"
  - "引入会改写内置工具名的扩展前，要先 grep 全部已加载扩展的 registerTool 名字"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-14-01-34-44-989-t03p
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: [pi-extension-off-suffix-not-disable]
---

# 主张

hashline 试用 1 天即撤：与用户的 TUI 状态不兼容——claude-look 重新注册 read 等 7 个内置工具做 CC 渲染，hashline 也注册 read → pi 启动即报 `Tool read conflicts`；且 pi-cc-extensions 的富 diff 只认 edit/write 名字，hashline 的 replace/insert 拿不到 CC 渲染。

# 用户取舍

用户明确：外观/原状优先于 edit 错误率试验。

# 规则

以后引入会改写内置工具名的扩展前，先 grep 全部已加载扩展的 registerTool 名字。
