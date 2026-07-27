---
id: bash-source-root-breaks-when-script-moved
type: lesson
status: validated
scope: global
domain: shell-scripting
tags: [bash, bash-source, project-root, script-copy, silent-failure, fail-open]
triggers:
  - "复制脚本到别处做临时改造/加日志/做实验"
  - "脚本用 dirname \"$BASH_SOURCE\"/.. 推项目根目录"
  - "脚本副本跑完什么都没发生，退出码还是 0"
  - "日志文件没写出来，或写去了不存在的路径"
  - "fail-open 的脚本挪个位置就静默空转"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
用 `ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"` 推项目根的脚本，**位置就是它的配置**。把它复制到别处（临时加桩、改一行做实验），`ROOT` 会静悄悄指向副本的祖父目录——所有派生路径（CLI、日志、锁、数据文件）跟着全错。

**为什么难发现**：这类脚本通常是 fail-open 设计——找不到 CLI 就当队列为空、日志写不进就算了，最后 `exit 0`。于是副本"跑完了、没报错、什么也没做"，看起来像"本来就没活可干"。

**证据**：把 `ops/bin/evo-distill.sh` 复制到 scratchpad 只改了一行清理逻辑，跑完 `ops/log/distill.log` 一条新记录都没有。真实原因在后台任务的 stderr 里：`line 37: /private/tmp/.../-Users-zodyne-Dev-agent-evo/ops/log/distill.log: No such file or directory`——`ROOT` 从 `~/Dev/evo-kernel` 变成了 scratchpad 的祖父目录，`EVO` 指向不存在的 `bin/evo`，`queue` 因此为空。副本放回 `ops/bin/` 后同一份代码立刻正常。

**做法**：改造这类脚本时**副本放回原目录**（`ops/bin/.xxx-test.sh`），别挪层级；或跑之前先 `ROOT=<真实根> bash 副本`（前提是脚本允许 `ROOT` 被环境覆盖——多数没写，那就只能放回原位）。验证副本是否在对的根上，最省事的是先看它有没有写出预期的日志行，而不是看退出码。

**边界**：只影响用自身位置推路径的脚本。用环境变量（`EVO_ROOT`）或 `git rev-parse --show-toplevel` 定根的不受影响——后者跟 cwd 走，跨仓库时另有坑。
