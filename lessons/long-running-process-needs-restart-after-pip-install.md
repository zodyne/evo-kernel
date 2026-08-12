---
id: long-running-process-needs-restart-after-pip-install
type: lesson
status: candidate
scope: global
domain: process-management
tags: [python, pip, mcp, hot-reload, socks-proxy]
triggers:
  - "给一个已经在跑的常驻进程（MCP server / daemon）装 python 依赖，装完立刻重试还是报同样的 ImportError"
  - "httpx/httpcore 报 'socksio package is not installed'，但 pip show 已经显示装上了"
  - "本机开着 SOCKS 代理（ALL_PROXY=socks5://...），Python HTTP 客户端连不上"
  - "要重启的进程正好是当前会话自己的 MCP stdio 子进程"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:b78d3e85-eb00-4f1c-82d9-d12ac9e1fbc7
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [local-proxy-env-blocks-api-client, listmodels-display-omits-provider]
---

**主张**：本机代理变量里有 `ALL_PROXY=socks5://127.0.0.1:7897`，被继承代理环境的常驻进程（如 pal-mcp-server）里的 httpx 客户端会尝试走 SOCKS，若 venv 缺 `socksio` 包就直接报错——这本身是 `local-proxy-env-blocks-api-client` 的一个具体子情形。但更值得记的是下一步：**给这个"存活中"的进程所在 venv `pip install` 补上依赖后，不重启进程就不会生效**——httpx/httpcore 是在模块加载时（进程启动那一刻）做一次 `try: import socksio` 并把结果缓存成模块级标志位，运行期间不会重新 `import`，所以哪怕包已经落盘、`python -c "import socksio"` 单独验证能成功，那个存活进程还是会报一模一样的"未安装"错误，必须杀掉重启该进程。而如果这个进程恰好是当前会话自己拉起的 MCP stdio 子进程，kill 它会导致该 MCP 在**本次会话内断线且不会自动重连**，要等新开一个会话（或该 harness 的手动重连机制）才能验证修复是否生效——不能在同一会话里直接复测。

**证据**：`.pal_venv/bin/pip install 'httpx[socks]'` 成功装上 `socksio`（`Successfully installed socksio-1.0.0`），且 `.pal_venv/bin/python -c "import socksio"` 单独验证可导入；但对存活的 pal-mcp-server 进程（PID 19025，用的正是同一个 `.pal_venv/bin/python`）重新发起 `chat(model="k3")` 调用，错误信息从 httpx 层的 "socksio package is not installed. ... pip install httpx[socks]" 变成了 httpcore 层的 "socksio package is not installed. Use 'pip install httpcore[socks]'"——两层各自缓存了一次失败判定，说明确实是模块级缓存而非单纯没装上。`kill 19025` 后，本会话里所有 `mcp__pal__*` 工具立即报 "No such tool available"，且系统提示确认该 MCP server 已断开，未自动重连。

**边界**：这是 Python 长驻进程 + 模块级 `try/except ImportError` 缓存模式的通用坑，不限于 httpx/socksio，任何库用同样模式（进程启动时探测可选依赖并缓存布尔标志）都会复现；判别信号是"重新 import 单独验证成功，但存活进程仍报同一个错"。若某天升级到会在每次请求时重新探测依赖的库版本，这条不再适用。
