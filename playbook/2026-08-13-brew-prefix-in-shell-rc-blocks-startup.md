---
id: brew-prefix-in-shell-rc-blocks-startup
type: lesson
status: validated
scope: global
domain: shell-env
tags: [zsh, homebrew, brew-prefix, startup, tmux]
triggers:
  - "tmux 新建窗口一直空白、没有提示符（失败信号）"
  - "shell rc 里写 $(brew --prefix <formula>) 导致交互式 shell 启动卡住"
  - "zsh -ic 'echo OK' 不返回 / 交互式 shell 启动要几十秒"
  - "排查 shell 启动期阻塞：pgrep -P 找到挂着的 ruby brew.rb"
  - "想用 Homebrew 稳定路径替代 brew --prefix"
created: 2026-08-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-13-13-00-18-127-nu9f
last_verified: 2026-08-13
superseded_by: null
schema_version: 1
related: []
---

# 主张

shell rc 里写 `$(brew --prefix <formula>)` 是启动期地雷：`brew --prefix` 会去拉 Homebrew formula JSON API（`curl_download`），缓存过期或网络不畅时无限期阻塞，而这行在每个交互式 shell 启动时都跑一次。

修法：换静态路径 `/opt/homebrew/opt/<formula>/bin`（Homebrew 维护的稳定 symlink，小版本升级仍有效）。

# 症状与误判

表现为 tmux 新建窗口一直空白无提示符，且**极易被误判成「刚才那次改动引起的」**——因为触发条件（缓存过期 / 网络不畅）与改动无关。

# 判别命令

- `pgrep -P <该 pane 的 shell pid>`：能看到挂着的 ruby `brew.rb` 子进程即坐实。
- `zsh -ic 'echo OK'` 不返回也是同一信号。

# 证据

实测 2026-08-13：改前 `brew --prefix python@3.14` 超 20s 不返回、交互式 zsh 卡死；改后启动 0.11s，`python3` 仍解析到同一路径。
