---
id: hermes-tui-restyle-v1-residual-lessons
type: lesson
status: validated
scope: global
domain: hermes-tui
tags: [hermes, tui, typewriter, throttle, feature-flag, testing]
triggers:
  - "Hermes TUI 做流式打字机 / typewriter 节流，出现纯延迟 + 闪烁"
  - "给 TUI 写组件测试时用本地复刻副本而不是 import 真实组件（失败信号：测试全绿但真机行为不对）"
  - "同一处行为被多个 flag 同时控制（MINIMAL_STATUS_RULE vs CLAUDE_MODE）"
  - "多 flag 职责重叠导致注释 / 文档腐坏"
  - "改造后渲染有延迟或闪烁 bug，怀疑节流实现"
created: 2026-08-13
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-08-13-02-09-12-476-9x5d
last_verified: 2026-08-13
superseded_by: null
schema_version: 1
related: [tui-restyle-additive-not-subtractive, hermes-tui-component-test-rendersync]
---

# 主张

hermes TUI Claude 化 v1 的失败复盘里，除「风格改造是加法不是减法」之外，还留下三条可复用的教训：

1. **turnController 的 typewriter 节流是纯延迟 + 闪烁 bug**——Claude 的做法是「到达即渲染」，不做打字机节流。
2. **测本地复刻副本 = 测试剧场**——必须 import 真实组件，不能拿本地复刻件当被测对象。
3. **多 flag 职责重叠（`MINIMAL_STATUS_RULE` vs `CLAUDE_MODE`）会致注释 / 文档腐坏**——同一处行为应由单 flag 控制。

# 为什么

- 打字机节流人为把渲染时刻推后，既没有增加信息量，又把连续到达的内容切碎成闪烁的画面；「到达即渲染」省掉这一层状态机，行为与 Claude 一致。
- 本地复刻副本与真实组件是两套实现，副本上的测试全绿不能推出真实组件正确——复刻件本身会随真实组件演进而失同步，测试对象从根上就不是发布物。
- 两个 flag 控制同一处行为时，注释与文档只能描述其中一种组合，另一条路径的语义无处安放，读的人按注释理解就会错，注释随代码腐坏。

# 反例 / 边界

- 本条的「三件残余教训」与 `tui-restyle-additive-not-subtractive` 是同一份 capture 的不同切面：那条已覆盖「别把工具调用行 / busy 动画藏进手风琴」的可见性主张，本条不重复它。
- 「必须 import 真实组件」指的是被测对象的选择（测试保真度问题），与 `hermes-tui-component-test-rendersync` 记录的「用 `renderSync` 直接渲染单个组件、不起全 App」并不冲突：后者讲的是渲染入口，前者讲的是不要渲染一个副本。

# 证据

capture `capture-2026-08-13-02-09-12-476-9x5d` 原文（未改写）：「hermes TUI Claude 化 v1 失败教训:风格改造别把官方默认可见的信息(工具调用行/busy 动画)藏进手风琴或删掉——Claude 风格=信息全可见+每样一行 dim,是加法不是减法;turnController typewriter 节流=纯延迟+闪烁 bug(Claude 到达即渲染);测本地复刻副本=测试剧场,必须 import 真实组件;多 flag 职责重叠(MINIMAL_STATUS_RULE vs CLAUDE_MODE)致注释/文档腐坏,应单 flag」。

证据等级为 human：capture 内无命令输出，属改造后的失败复盘。
