---
id: bin-shim-symlink-still-points-old-repo
type: lesson
status: candidate
scope: global
domain: cli-packaging
tags: [symlink, migration, path-resolution, end-to-end, cli-entry]
triggers:
  - "仓库从旧路径迁出/拆分后，~/bin 里还留着指向旧路径的入口软链"
  - "迁移后旧仓库没删，里面的同名包还在，命令照样能跑（失败信号：旧树仍在执行）"
  - "想知道这条全局命令到底跑的是哪份代码"
  - "改完入口脚本或重指软链后，要证明解析到的是新仓库根"
  - "准备删掉 ~/bin 里的旧命令，先确认没有别名/软链仍指向它"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a964-e50e-77c1-a593-51a129dcb579
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [config-symlink-reference-scan-before-delete, same-name-repo-verify-by-remote-url]
---

**主张**：仓库换路径（拆分/迁出）后，`~/bin` 里的入口软链可能仍指向旧树；只要旧树里的同名包还在，命令就**照常能跑**，静默执行旧代码、不报任何错。迁移后必须做三件事而非只看「命令存在」：(1) `ls -la ~/bin/<cmd>` 看链接目标是不是旧路径；(2) 复刻入口脚本的路径解析（或 `readlink -f`）确认最终解析到新仓库根；(3) 从无关 cwd 端到端跑一次（`cd /tmp && <cmd> --help`）。确认目标是重指还是删除，再做动作（旧链留 `.bak`）。

**为什么**：这类入口脚本通常按「自身解析后的真实路径」引导 `sys.path`，所以软链指到哪就加载哪棵树，路径错了也没有任何报错——失效方式是「结果悄悄变了」。而旧仓库往往还留在磁盘上（本机 `~/Dev/SPC865` 在新仓 `~/Dev/spc865-adc` 迁出后仍完整），于是「命令能跑」这个观察完全无法区分新旧树，必须直接看链接目标和运行根。

**边界**：软链扫描只查相关的那几条（`ls -la ~/bin/<name>`）或 `~/bin` 一级列表；不要用无路径递归 grep 扫家目录/软链目录（会顺链越出 cwd 触发 pi 的 bash-guard 拦截，见 related）。只改 `PATH` 里找不到的目录（本机 `~/bin` 不在 PATH 上）就删是安全的，但仍在 `PATH` 上的目录要先确认没有别处引用。

**证据**（session 01a0a964，evo slice「命令 ↔ 结果」）：
- `ls -la ~/bin/spc865-ui ~/bin/spc865` → `~/bin/spc865 -> /Users/zodyne/Dev/SPC865/spc865_cli.py`（旧仓库；新仓库是 `~/Dev/spc865-adc`）。
- 旧树仍在：`ls -d /Users/zodyne/Dev/SPC865/spc865` → 存在 → 软链能跑通、不报错（这就是「静默跑旧码」的机制）。
- 重指后证明解析到新树：从 `/tmp` 复刻入口脚本的 resolve 逻辑 → `~/bin/spc865_ui.py → 仓库根 /Users/zodyne/Dev/spc865-adc`。
- 端到端（无关 cwd、无任何安装）：`cd /tmp && ~/bin/spc865 --help` → 正常 usage；`cd /tmp && env SPC865_DATA_ROOT=… ~/bin/spc865-ui --check` → 正常 check 输出。
- 最终决定不留全局命令：`rm -f ~/bin/spc865 ~/bin/spc865-ui ~/bin/spc865.bak ~/bin/spc865-ui.bak` → `无 ✓`，再敲 `spc865-ui` → `command not found ✓`。
