---
id: tmux-continuum-save-needs-status-bar-rendering
type: lesson
status: validated
scope: global
domain: tmux
tags: [tmux, tmux-continuum, resurrect, status-right, 自动保存]
triggers:
  - tmux-continuum 自动保存静默失效，手动 prefix+Ctrl-s 却正常
  - set -g status off 后 continuum_save.sh 的 interpolation 不再被求值
  - 配置 continuum 时要不要保留 status bar
  - 对比 resurrect 存档目录文件 mtime 与当前时间排查保存失效
  - 想改用外部定时器(launchd/cron)调用 resurrect 的 save 脚本
created: 2026-09-04
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-09-04-03-22-38-065-puvj
last_verified: 2026-09-04
superseded_by: null
schema_version: 1
related: []
---

# tmux-continuum 的自动保存依赖 status-right 被渲染

tmux-continuum 的自动保存靠把 #(continuum_save.sh) 塞进 status-right，由状态栏渲染周期触发求值；一旦 set -g status off，这条 interpolation 永远不会被求值，自动保存静默失效（手动 prefix+Ctrl-s 不受影响）。

## 修法

配置 continuum 时必须保留至少极简的 status bar，或改用外部定时器(launchd/cron)直接调用 resurrect 的 save 脚本。

## 排查手法

对比 resurrect 存档目录里文件的最新 mtime 和当前时间，差距远超预期保存间隔即可实锤。
