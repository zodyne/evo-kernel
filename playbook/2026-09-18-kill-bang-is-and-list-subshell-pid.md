---
id: kill-bang-is-and-list-subshell-pid
type: lesson
status: validated
scope: global
domain: shell
tags: [bash, background-job, pid, kill, subshell, nvim, swap]
triggers:
  - "用 `cd <dir> && nvim … &` 起后台探针后 `kill -9 $!`，以为进程已死，`ps` 却发现它还在（失败信号）"
  - "重开同一文件得到 W325: Ignoring swapfile from Nvim process <pid>，但持有者明明是自己刚『杀掉』的探针（失败信号）"
  - "后台起的 nvim/长命令 kill 后仍持有 swap / socket / 锁，收尾清理时才发现漏杀"
  - "要把后台 nvim 的真实 PID 写进 pid 文件或直接 kill -9"
  - "`A && B &` 的 `$!` 到底是 A、B 还是子 shell 的 PID"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b37f-3278-73b1-bdd8-c2e52b31a9ae
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [backgrounded-cd-and-list-leaves-shell-cwd-unchanged, nvim-stale-swap-e325-blocks-repeated-headless-runs]
---

# `cd <dir> && CMD &` 的 `$!` 是子 shell 的 PID：`kill -9 $!` 杀不到 nvim

**主张**：`A && B &` 会把整条 and-list 放进后台子 shell，`$!` 记的是**子 shell**的 PID，不是链里那条长命令（nvim/探针）的 PID。于是

```bash
cd /tmp/gate-r3 && nvim --headless … +'sleep 6' >/dev/null 2>&1 & P=$!; sleep 2; kill -9 $P
```

shell 回显 `Killed: 9` 看似成功，实际被杀的是子 shell；nvim 是子 shell fork 出的孙进程，被 reparent 后继续活着，并继续持有它写的 swap 文件。下一次打开同一文件得到的会是 **W325: Ignoring swapfile from Nvim process <pid>（持有者还活着）**而不是 **E325（被拦下）**——很容易把"没杀干净"误读成"swap 是别的实例留下的"。要拿真实 PID：在子 shell 里直接背景化 nvim 并把 `$!` 落盘，`( nvim … & echo $! > /tmp/x/npid )`；或启动后用 `ps -p <pid> -o pid=,stat=,command=` 核对这个 PID 到底是不是 nvim。

**为什么**：`&` 只背景化它左侧的整条 and-list（`cd … && nvim …` 是一个 list），bash 为此 fork 子 shell 来执行，`$!` 就是这个子 shell 的 PID。子 shell 被杀不级联到它的子进程；而 `--headless` 且没有 `+qa` 的 nvim 本来就不会自己退出。"kill 报成功/打印 Killed" 与 "目标进程已死" 是两件事，必须用 `ps -p` 验证。

**证据**（session 01a0b37f，命令 ↔ 结果）：
- `cd /tmp/gate-r3 && nvim --headless -u NONE swaptest.md +'lua vim.api.nvim_buf_set_lines(…)' +'sleep 6' >/dev/null 2>&1 & P=$!; sleep 2; kill -9 $P 2>/dev/null; sleep 1; ls ~/.local/state/nvim/swap/ | rg -i 'gate-r3|swaptest'` → `/bin/bash: line 1: 17545 Killed: 9`，swap 仍在；随后 `nvim --headless -u NONE swaptest.md +'lua print("OPENED")' +qa` → `W325: Ignoring swapfile from Nvim process 17548` + `OPENED`（不是 E325）。
- `ps -p 17548 >/dev/null && echo "17548 ALIVE: $(ps -p 17548 -o comm=)"` → `17548 ALIVE: nvim`；`ps -p 17548 -o pid=,stat=,command=` → `17548 S nvim --headless -u NONE swaptest.md +lua vim.api.nvim_buf_set_lines(…) +sleep 6`。被 `kill -9` 报杀的 17545 与真正的 nvim 17548 不是同一个进程。
- 对照组（直接背景化 nvim、`$!` 落盘）：`( nvim --headless -u NONE /tmp/gate-r3/swap3.md +'lua …' +'sleep 12' >/dev/null 2>&1 & echo $! > /tmp/gate-r3/npid )` → `pid=17672`，`ps -p 17672` 显示的就是 nvim 命令行；`kill -9 $(cat /tmp/gate-r3/npid)` → `DEAD`，重开同一文件 → `E325: ATTENTION Found a swap file`。只有拿到 nvim 自己的 PID，kill 才真命中，swap 才会从 W325 变成 E325。

**反例 / 边界**：
- 启动写成 `cmd &`（前面没有 `&&` 链）时，`$!` 就是 cmd 的 PID，不会踩这条；踩坑的是 `cd … && cmd &` 这种把 cd 和命令串成一条 list 的写法。
- 同构造的另一个坑（cd 不作用于父 shell，见 related `backgrounded-cd-and-list-leaves-shell-cwd-unchanged`）讲 cwd，本条讲 PID，排查时别混。
- 持有者还活着时的 W325 **不要**去删它的 swap（可能丢未保存改动）；先 `ps` 确认持有者是谁。
- 收尾清理别只信 kill 回显：按探针 tag 全量 `pkill -f` 后仍要用 `pgrep -fl`/`ps` 复核，且核对用户自己的实例没被误伤。
