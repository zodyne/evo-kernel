---
id: 2026-09-13-pi-package-sandbox-trial-install
type: lesson
status: candidate
scope: global
domain: pi
tags: [pi, package, install, sandbox, extension]
triggers:
  - "想把 npm 上的 pi 包/扩展装进真实 ~/.pi/agent"
  - "评估陌生 pi 包：能不能加载、注册了哪些命令、负载多大"
  - "pi 启动报 extension 加载失败，怀疑新装的包"
  - "真实 profile 装完包后行为变化，说不清是哪个包干的（失败信号）"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a099a8-07d2-766c-b240-9eaed5f6ca6d
last_verified: 2026-09-13
superseded_by: null
schema_version: 1
related: [pi-gauntlet-personas-symlink-agents-dir]
---

**主张**：把第三方 pi 包装进真实 profile 之前，先用空目录沙箱试装：`PI_CODING_AGENT_DIR=<空目录> pi install npm:<pkg>`，再做 `pi -p --offline` 负载冒烟和 `pi --mode rpc` 的 get_commands 盘点，确认包能加载、命令数符合预期，再动真实环境。

**为什么**：pi install 会改写 settings.json 的 packages、扩展 npm 依赖树，postinstall 还可能往 agents/ 等共享目录写软链；直接装真实 profile，出问题时既难归因也难回退。

**反例/边界**：
- 沙箱 profile 没有 provider key，`--offline` 下报 "No models available" 属预期，不是包的问题。
- 包的 postinstall 若会拉外部二进制（如 gentle-pi 的 gentle-ai 安装器），沙箱里也要用包提供的跳过变量（GENTLE_PI_SKIP_GENTLE_AI_INSTALL=1）拦住，否则试装本身就有副作用。

**证据**（session:01a099a8-07d2-766c-b240-9eaed5f6ca6d）：先在 /tmp/pi-eval/profile 沙箱完成 pi-cohort / pi-gauntlet / gentle-pi 三包试装；rpc 冒烟 `printf '{"id":"r1","type":"get_commands"}\n…' | pi --mode rpc --offline` 统计出 total commands: 68（gentle-pi 38 / pi-gauntlet 17 / pi-cohort 12 / inline 1）；确认后才在真实 ~/.pi/agent 安装。
