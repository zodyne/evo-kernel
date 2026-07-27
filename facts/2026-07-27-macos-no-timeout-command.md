---
id: macos-no-timeout-command
type: fact
status: validated
scope: global
domain: shell
tags: [macos, shell, timeout, command-not-found, gtimeout, coreutils, bsd-userland]
triggers:
  - "macOS 上跑 `timeout <N> <cmd>` 报 command not found"
  - "想给命令加运行时长上限/超时强制结束"
  - "跨平台脚本用 timeout 包裹命令在 mac 上失败"
  - "需要 GNU coreutils 工具（g 前缀）"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:6f9c92c5-482a-40a9-8810-6dd388611e95
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# macOS 自带 shell 没有 `timeout` 命令

## 主张
macOS 默认的 BSD userland **不含 `timeout` 命令**，直接 `timeout 120 <cmd>` 会立即报 `(eval):1: command not found: timeout`，命令根本不执行。要给命令加运行时长上限，需用 `gtimeout`（`brew install coreutils` 提供，GNU 前缀），或在脚本内自建超时机制（signal alarm / 计时后 kill / 轮询）。

## 为什么
`timeout` 属于 GNU coreutils，macOS 系统只装 BSD 版工具集，没有它。Homebrew 装 coreutils 后会以 `g` 前缀提供 GNU 版工具（`gtimeout`/`gsed`/`gtail`/`greadlink`…），默认不覆盖系统同名命令——所以即便装了 coreutils，命令名仍是 `gtimeout` 而非 `timeout`。

## 证据（本会话命令对照）
- ❌ `timeout 120 python3 .../scratchpad/cycle_combos.py 2>...` → `(eval):1: command not found: timeout`
- 会话里的**实际处理**是直接去掉 `timeout` 改为裸跑 `python3 .../scratchpad/cycle_combos.py`，输出正常（`OK: 15 组合全部通过`）。
- 诚实标注：本会话只验证了"`timeout` 不可用"这一事实；`gtimeout` **本会话未实测**（未跑 `brew install coreutils` / `which gtimeout`），属基于 GNU coreutils 约定的已知替代方向，使用前需自行确认。

## 边界 / 反例
- Linux（GNU coreutils 原生）有 `timeout`，跨平台脚本在 Linux 上正常，只在 mac 上踩坑。
- 若脚本必须跨 mac/Linux 通用，可写 `TIMEOUT=$(command -v gtimeout || command -v timeout)` 再 `"$TIMEOUT" 120 cmd`，自动选可用的那个。

## 失败信号（未来命中即该想起本条）
- macOS 上 `timeout <N> <cmd>` 立即 `command not found: timeout` → 换 `gtimeout`（需 brew coreutils）或去掉 timeout / 自建超时。
