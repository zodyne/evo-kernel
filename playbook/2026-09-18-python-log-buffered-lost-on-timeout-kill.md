---
id: python-log-buffered-lost-on-timeout-kill
type: lesson
status: validated
scope: global
domain: debugging
tags: [python, stdout, buffering, timeout, long-running, logging]
triggers:
  - "用命令行跑可能超时的长任务（全链回归 --check、批量处理、蒙特卡洛），想看到它的实时进度"
  - "命令被工具/看门狗超时杀掉后，重定向的日志文件是 0 字节，分不清是没跑、卡在开头还是输出被缓冲（失败信号）"
  - "Python 输出重定向到文件后，运行期间文件里什么都看不到"
  - "长任务被中断后中间输出全丢、只能整段重跑（失败信号）"
  - "要给别人或下一次会话留下长任务的中间证据"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5c18-7353-8a3d-42d03382d2d8
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [faulthandler-dump-traceback-later-hang, macos-no-timeout-command, stdio-mcp-server-shell-background-probe-false-dead]
---

**主张**：把一个可能被超时/看门狗打断的 Python 长任务用「落盘 + 不缓冲」的方式跑——`python3 -u`（或 `PYTHONUNBUFFERED=1`）把输出写进文件，并以子 shell/后台形式启动进程；否则进程被杀时块缓冲的 stdout 全部丢失，磁盘日志停在 0 字节，看起来像"根本没跑"，中间证据无法回收。

**为什么**：Python 的 stdout 接到管道/文件（非 tty）时是**块缓冲**，正常退出才 flush。于是同一个命令有两种截然不同的结果：跑完 → 日志完整（进程退出时 flush）；被超时杀掉 → 文件 0 字节（缓冲区随进程消失）。0 字节因此**不能**作为"没执行/挂在开头"的证据——这正是本条的实测现象。落盘 + `-u` + 后台化把"能否留下证据"与"进程活多久"解耦：即使工具侧超时，进程仍继续跑完并把结果留在文件里。

**反例/边界**：
- 只在"被中断"时暴露；进程正常结束时块缓冲无害（本会话 SR61 那次走管道也拿到了完整输出）。
- `-u` 解决的是**可见性**，不解决"为什么慢/为什么挂"；疑似挂死要先用堆栈取证（见 related `faulthandler-dump-traceback-later-hang`）。
- 落盘文件本身要能回收才算数：起完进程后要 `cat <log>` / `ps` 轮询确认，而不是等前台返回（后台启动的探活陷阱见 related `stdio-mcp-server-shell-background-probe-false-dead`）。

**证据**（session:01a0a575…，algommw 仓库，afm761_ddm `--check`）：
- 前台重定向跑、被工具超时杀掉：`time python3 python/radar_viz/view_tracks_3d.py --check --profile-dir profiles/afm761_ddm > /tmp/af_check.txt 2>&1` → `✗ Command timed out after 600 seconds`；随后 `cat /tmp/af_check.txt` 无任何内容（该行切片只剩 `== procs killed`）——600 秒运行在磁盘上零字节。
- 同一条命令改成 `-u` + 落盘 + 子 shell 形式启动：`rm -f /tmp/af2.txt && (time python3 -u python/radar_viz/view_tracks_3d.py --check --profile-dir profiles/afm761_ddm > /tmp/af2.txt …` → 工具侧报 `✗ started / Command timed out after 180 seconds`，但进程继续跑完；回收文件得到 `载入 profile: profiles/afm761_ddm 帧 1000 · 检测点 24748 · ours 航迹点 991(回归基线 ✓)` 与 `real 0m55.468s`（即该命令稳态只要 ~55 s，先前 300 s/600 s 的"卡住"至少不是稳态算力造成的）。
- 对照：同会话 SR61 那次 `python3 … --check 2>&1 | tail -8` 进程正常退出 → 输出完整（`帧 1180 · 检测点 27879 · ours 航迹点 2432`），说明差别出现在"被杀"而不是"重定向"本身。
