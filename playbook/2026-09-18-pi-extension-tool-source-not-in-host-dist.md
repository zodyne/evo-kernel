---
id: pi-extension-tool-source-not-in-host-dist
type: lesson
status: validated
scope: global
domain: pi
tags: [pi, extension, grep, forensics, registerTool, locating-source]
triggers:
  - "在 pi 安装目录里 grep 某个工具的实现（如 ask_user），0 命中（失败信号）"
  - "因为宿主 node_modules 里搜不到工具名，就断言该工具/行为不存在或没生效"
  - "排查 pi 会话 transcript 里出现的陌生工具到底是什么、由谁注册"
  - "要读扩展注入的 UI / 工具的实现，不确定先翻 ~/.pi/agent/extensions/ 还是宿主 dist"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a801-014f-7485-9b7c-35a1fb467c3a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [hashline-withdrawn-tool-name-conflict, pi-extension-off-suffix-not-disable]
---

**主张**：在 pi 宿主安装目录里按**工具名** grep（`grep -rl "ask_user" /opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent/dist/`）返回 0 命中，**不能**推出该工具不存在 —— 扩展注册的工具名只作为字面量存在于 `~/.pi/agent/extensions/<ext>/index.ts`；宿主侧只有**机制关键字**可搜（`hasUI`、`showExtensionCustom`、`ui.custom`、`executionMode`）。正确顺序是先定位扩展源码，再回宿主 dist 搜该机制的实现。

**为什么（实测证据）**

- 先在宿主目录搜工具名，白跑一步：`grep -rl "ask_user" dist/` 无输出、`Command exited with code 1`；bundle 内计数 `dist/bundle/cli.js:0 dist/bundle/index.js:0 dist/bundle/rpc-entry.js:0`。
- 转到扩展目录立刻找到：`find ~/.pi/agent/extensions/ask-user -type f` → `index.ts` + `README.md`，工具定义在 `index.ts:248` `pi.registerTool({ name: "ask_user", ... })`，执行体在 `:278` `ctx.ui.custom(...)`。
- 之后对宿主侧改搜机制关键字就一路命中：`grep -rln "hasUI"` → `core/extensions/runner.js`、`modes/interactive/interactive-mode.js` 等；`grep -n "showExtensionCustom" -A 40 modes/interactive/interactive-mode.js` → `:1918` 扩展 API 里的 `custom:` 挂载点与 `:2158` 的实现；再 `grep -rn "executionMode"` → `types.d.ts:370`、`tool-definition-wrapper.js:10`。
- 判据：内置工具（bash/read/edit/grep/…）的名字在宿主 dist 里搜得到；只有扩展 `registerTool` 进来的名字搜不到。

**反例 / 边界**

- 反向不成立：dist 里搜到某工具名 ≠ 该工具一定由宿主提供，扩展可以注册与内置同名的工具（重名冲突会直接把 pi 启动打挂，见 `hashline-withdrawn-tool-name-conflict`）。
- 工具名可能被扩展动态拼接或在 promptSnippet 里出现，则连扩展目录也不一定 grep 到字面量；此时从 transcript 的工具结果反查扩展目录里唯一的 `registerTool` 集合更可靠。
- 想看某扩展是否真的在加载，别只看目录（`.off` 后缀不禁用，见 `pi-extension-off-suffix-not-disable`）。
