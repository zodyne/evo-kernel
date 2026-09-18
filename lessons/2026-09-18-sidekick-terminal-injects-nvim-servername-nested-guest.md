---
id: sidekick-terminal-injects-nvim-servername-nested-guest
type: lesson
status: candidate
scope: global
domain: nvim
tags: [nvim, sidekick, flatten.nvim, env, guest, crash-triage]
triggers:
  - "在 nvim 里用 sidekick 的 terminal 跑 pi/claude 等 CLI，随后宿主 nvim 退出（用户称之为『闪退』）"
  - "怀疑嵌套 nvim 被 flatten.nvim 判成 guest：该去看它继承的环境里有没有 NVIM / NVIM_LISTEN_ADDRESS（失败信号）"
  - "解释『nvim 里跑 agent 后 nvim 退出』时只查了 flatten 的 nest_if_no_args，没查 sidekick 给 CLI 注入的 env（失败信号）"
  - "要读 sidekick.nvim 的 lua/sidekick/cli/terminal.lua，确认它给 terminal 里启动的 CLI 传了哪些环境变量"
  - "在 nvim 内嵌终端里跑 agent，事后要判断『agent 起的那个 nvim 为什么不是普通独立实例』"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a7b2-5ed2-725c-a75a-f9943c464c4a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [flatten-nvim-nest-headless-crashes-host, nvim-terminal-tmux-env-poisons-osc52-passthrough, pi-bash-spawn-env-empty-but-inherit-env]
---

# sidekick 的 terminal 给 CLI 注入 `NVIM = vim.v.servername` ⇒ 它启动的嵌套 nvim 被 flatten.nvim 判成 guest

**主张**：sidekick.nvim 的 terminal 在拼 CLI 启动环境时**硬编码注入** `NVIM = vim.v.servername`（`lua/sidekick/cli/terminal.lua:282-284`）。因此「在 nvim 里用 sidekick 终端跑 pi/claude，再让这个 agent 去起 nvim」这条链上，agent 起的 nvim 一出生就**继承了 NVIM 环境变量**，被 flatten.nvim 的判定当作「嵌套实例 = guest」（`flatten/init.lua:239-243`）。guest 一旦退出，退出事件会被传播回 host —— 从用户视角就是「在 nvim 里跑 pi，nvim 闪退」。

排查入口因此有**两条**，别只看一条：flatten 侧 `nest_if_no_args` / `should_nest`（argv 判定），**和**这侧的 env 注入（环境变量判定）。本会话的案例是后者：命令行带了 `+cmd`（非「无参数」），仅凭 `nest_if_no_args` 解释不了它为什么被判 guest。

**为什么**：flatten 的 guest 判定依据之一是「当前进程环境里是否已有 NVIM servername」——这是 nvim 内嵌终端/嵌套场景的通行信号。sidekick 为了让终端里的 CLI 能感知「自己跑在哪个 nvim 实例里」（可回连 server、发通知等），主动把这个变量塞进 CLI 的环境；对 CLI 本身是特性，对 CLI 再起的 nvim 就是**误判来源**：它明明是新起的实例，却被当成已有 host 的 guest。

**反例 / 边界**：
- 本条与 `flatten-nvim-nest-headless-crashes-host` **互补不重叠**：那条讲 `nest_if_no_args=true` 把「不带文件参数的 nvim」（含 `--headless`）嵌套进 host；本条讲 env 注入导致的 guest 判定，触发路径是「交互式 agent 在终端里起 nvim」，不依赖 `nest_if_no_args`。
- 与 `nvim-terminal-tmux-env-poisons-osc52-passthrough` 同源（都是「nvim 内嵌终端把外层环境透给子进程」），但受害面不同：那条是 `TMUX`/OSC 52 显示乱码，本条是 flatten 的实例归属误判。
- 反向不成立：环境里有 `NVIM` ≠ 一定被 flatten 判 guest（要 flatten 在加载中且 host 存活）；没配 flatten 时这条链不成立。
- 逃生门仍走 flatten 侧：`should_nest` 钩子里对「带 `FRESH_NVIM=1` 的 guest / agent 起的 nvim」返回 false（细节见 related 的 flatten 条目）；用户侧另有 `configs/sidekick.lua` 的 `mux_enabled()` 这类「不在 sidekick 终端里再套一层」的开关，可类比处理。

**证据（本会话切片）**：
- 命令：`sed -n '276,305p' /Users/zodyne/.local/share/nvim/lazy/sidekick.nvim/lua/sidekick/cli/terminal.lua | cat -n` —— 会话确实打开的就是这段拼 env 的区域；同批还有 `echo "=== sidekick terminal.lua env region ..."` 的定向检索（命中 terminal.lua 第 8 行的 `---@field` env 声明）。
- 命令：`ls -d .../lazy/flatten.nvim` → 装上且在 lazy 路径下；`guest.lua 1-20` → 第 20 行即 `vim.cmd.qa({ bang = true })`（guest 侧就是走 `qa` 退出）；`init.lua 150-175` → 第 153 行注释即「If this returns true, the nested session will be …」（嵌套判定所在）。
- 末条 assistant（切片内可见的结论）：「1. sidekick 终端硬编码注入 `NVIM = vim.v.servername`（`terminal.lua:282-284`）2. pi 起的嵌套 nvim 因此被 flatten.nvim 判为 guest（`init.lua:239-243`）3. 命令行含 `+cmd` → 默认 n…」。
- **诚实标注**：切片对每条命令的输出做了截断（150/120 字符），上面那两处源码行**没有在切片里逐字可见**；机制结论来自被复核会话的分析文本 + 其给出的精确 file:line。故 `verified_by: human`。复核者一条命令即可升级为 command：
  `sed -n '278,290p' /Users/zodyne/.local/share/nvim/lazy/sidekick.nvim/lua/sidekick/cli/terminal.lua` 与
  `sed -n '235,250p' /Users/zodyne/.local/share/nvim/lazy/flatten.nvim/lua/flatten/init.lua`。

**失败信号（未来命中即该想起本条）**：报告只说「flatten 的 nest 配置」却解释不了「命令行明明带了参数/`+cmd` 还是被嵌套」；或核对「nvim 里跑 agent → nvim 退出」时，没人去看 sidekick 终端注入的 env。
