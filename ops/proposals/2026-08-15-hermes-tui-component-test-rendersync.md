---
id: hermes-tui-component-test-rendersync
type: playbook
status: candidate
scope: global
domain: hermes-tui
tags: [hermes, tui, ink, vitest, react, testing]
triggers:
  - "给 Hermes TUI 的组件/组件树写单元测试"
  - "想验证某组件渲染输出又不想起完整 Hermes App / gateway / 真实 PTY"
  - "找不到 TUI 组件测试的入口，不知道 renderSync 从哪 import（失败信号：起全 App 太慢或超时）"
  - "审查/新增 src/__tests__/ 下的 *.test.tsx"
created: 2026-08-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:4659d364-dabe-409a-b11c-258b78db277c
last_verified: 2026-08-15
superseded_by: null
schema_version: 1
related: []
---

主张：给 Hermes TUI 组件写单元测试时，用 `renderSync`（`@hermes/ink` 导出）直接渲染单个 React 组件并断言其文本输出，不必起完整 gateway / App / 真实 PTY——既有测试就是这么做的。

证据：`head -50 src/__tests__/petPane.test.tsx` 显示 `import { Box, renderSync } from '@hermes/ink'` + `import React`；`grep -rn "renderSync" src/ink/...` 定位到 `src/ink/root.ts:107: export const renderSync = (node, options) => Instance`；scratch 测试经 renderSync 渲染后打印出 `PROBE-LINES: {"boxed":20,"plain":60,"scrollInBox":20,"scrolled":20}` 与 `BANNER-OUTPUT`。单测试文件跑 ~80ms，全量 ~5.5s。

为什么：TUI 组件是纯 React/Ink 树，渲染逻辑与 gateway 事件流解耦；renderSync 同步产出文本输出，可直接做快照/断言，比起全 App 快几个数量级。

边界：只覆盖「组件给定 state 渲染成什么」这一层；不覆盖 gateway 事件分发、真实流式行为、PTY 交互——那些需另测（createGatewayEventHandler.test.ts 单独测事件流，96 个用例）。
