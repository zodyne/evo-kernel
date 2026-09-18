---
id: pi-bash-spawn-env-empty-but-inherit-env
type: fact
status: candidate
scope: global
domain: pi
tags: [pi, bash-tool, env, inheritEnv, spawn, bundle-grep]
triggers:
  - "在 pi bundle 里看到 spawn 参数 env:{}，想断言子进程环境被清空（失败信号）"
  - "排查 nvim/sidekick 里起的 pi 的子进程继承了 NVIM_LISTEN_ADDRESS 之类的父环境"
  - "要解释 pi 的 bash 工具子进程的环境变量从哪来"
  - "审计 pi 是否会剥离某个环境变量，需要看 spawn 实际参数"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ad-7b8a-725c-a75a-f98b5e86a96a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [nvim-env-var-not-auto-vim-g-use-os-getenv, nvim-terminal-tmux-env-poisons-osc52-passthrough]
---

# pi 的 bash 工具 spawn 时是 `env:{}` + `inheritEnv:!0` —— 不能只凭 `env:{}` 断言子进程环境被清空

**主张**：在本机 pi（pi-coding-agent）的打包产物里，bash 工具构造 exec 参数的那一行同时写了 `env:{}` 和 `inheritEnv:!0`（见下证据），即"外层看起来是空 env、但显式开了环境继承"。因此：

- 不能只看到 `env:{}` 就下"pi 起子进程时环境被清空/净化"的结论；
- 要断言某个变量（如 `NVIM_LISTEN_ADDRESS`）在 pi 的子进程里被剥离，必须另找证据（本会话在 pi 里搜 NVIM 相关处理逻辑没有命中剥离代码，也侧面说明没有专门的剥离分支）。

**为什么**：`env:{}` 与 `inheritEnv` 是同一行的两个字段，读 bundle 时只看前者会得出相反的环境语义；而"nvim 里跑 pi、pi 再起 nvim/CLI"这类环境泄漏排查（`TMUX`、`NVIM_*` 等进孙进程）正需要这一行作为机制引用点。

**证据（本会话命令 ↔ 结果）**：
- `cd /opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent; rg -n -o 'env:\{\},inheritEnv:!0' dist/bundle/chunks/chunk-JVUZSMYM.js | head`
  → `1013:env:{},inheritEnv:!0`；同一行上下文：

  ```text
  1013:env:{},inheritEnv:!0 === line 1013 === ${command}`:command,cwd:env2.cwd,env:{},inheritEnv:!0};await options?.prepar
  ```

- 前一步专门搜过 pi 是否处理 NVIM 变量：`rg -n 'NVIM_LISTEN|process\.env\.NVIM|NVIM' …` → `=== rg NVIM === === chunk 418ed line === let{env:env2}=toolContext,execution={command:options?.commandPrefix?…`（在 pi 侧没有命中 NVIM 专用剥离逻辑，只看到从 toolContext 解构出 `env`）。

**反例/边界**：
- 只读了压缩后的 bundle 文本，**没有**运行时实验（例如在 pi 的 bash 里 `env | rg NVIM`）证实继承后的实际环境；`inheritEnv` 的确切合并语义（以 process.env 为基底，还是与 toolContext 的 env 合并）未从源码确证。本条能支撑的只有"不能据 `env:{}` 下'环境被清空'的断言"这一条。
- bundle 路径与行号随 pi 版本变化（`chunk-JVUZSMYM.js:1013` 只是本机当前版本的位置），引用时应以现查 `rg -n -o 'env:\{\},inheritEnv:!0' dist/bundle/chunks/*.js` 为准。

**失败信号（未来命中即该想起本条）**：报告/结论里写"pi 起子进程时把环境清空了（bundle 里是 `env:{}`）"——先回到同一行看有没有 `inheritEnv`。
