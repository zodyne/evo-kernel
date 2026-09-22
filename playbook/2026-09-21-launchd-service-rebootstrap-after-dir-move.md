---
id: launchd-service-rebootstrap-after-dir-move
type: playbook
status: validated
scope: global
domain: macos-tooling
tags: [launchd, launchctl, bootstrap, plist, port, connection-refused]
triggers:
  - "本机 launchd 托管的服务（本地 router/gateway）报 Connection refused，curl 被拒"
  - "服务程序目录被搬迁（~/Dev/x → ~/.claude/x）后 launchd agent 不再运行（失败信号：launchd 日志里 service inactive、端口无人监听）"
  - "launchctl bootstrap 返回 0 后，要确认服务真的在跑而不是只是注册成功"
  - "要重新注册一个 plist 已知、label 空闲的 launchd job"
  - "LaunchAgents 里的 plist 软链已指向新路径，但服务仍没起来"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0c1f4-ba46-7370-8301-baf14cc85c89
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [launchctl-list-print-diagnose-job, brew-services-start-not-equal-port-listening, launchd-silent-output-disk-only]
---

# 目录搬迁后 launchd 服务掉线：launchctl bootstrap 重注册，成功要 bootstrap exit=0 + print state=running + 端口/进程验活

**主张**：launchd 托管的本机服务（如 `<localhost>:<port>` 上的本机 router）在程序目录被搬迁后会处于未运行态，
症状是 `lsof -nP -i :<port>` 无人监听、launchd 日志里该 service 显示 inactive。
处置顺序：先确认端口确实没监听，再用 `launchctl bootstrap gui/$(id -u) <plist>` 重新注册；
判成功不能只看 exit code —— 还要 `launchctl print gui/$(id -u)/<label>` 看 `state = running`（最好带 pid）、并 `ps`/`lsof` 看到真实进程与端口。

**为什么**：目录搬迁会让原注册的 program 路径失效、job 消失；`bootstrap` 是把 plist 重新登记进 launchd 的动作。
它 exit=0 只代表登记被接受，不代表 job 正在运行，所以必须用 `print` 的 state 和进程/端口双重验活。

**证据**（本会话切片，命令 ↔ 结果）：
- `lsof -nP -i :<port>` → `NOTHING LISTENING`（11:14，端口确无监听）。
- `log show --last 45m --predicate 'eventMessage CONTAINS "claude-router"'` → `2026-09-21 11:05:03.679 Df launchd[1:205611] [gui/501 [100017]:] service ina...`（切片截断，launchd 对该 service 的记录）。
- `ls -la ~/Library/LaunchAgents/ | grep -i -E 'claude|router'` → `com.zodyne.claude-router.plist -> /Users...`（软链已在 11:09 指向新位置）。
- `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.zodyne.claude-router.plist` → `bootstrap exit=0`。
- `launchctl print gui/$(id -u)/com.zodyne.claude-router | rg '^\s+(state|path|pid) '` → `path = /Users/zodyne/.claude/claude-router/com.zodyne.claude-router.plist`、`state = running`；
  同时 `ps` 里出现 `node /Users/zodyne/.claude/claude-router/router.mjs` 进程。

**边界 / 反例**：
- 本会话没有「bootstrap 失败后 bootout 再 bootstrap」的对照；若 label 仍被占用，bootstrap 会失败，先 `launchctl bootout`（切片未覆盖）。
- launchd 日志行在切片里被截断成 `service ina...`，不能据此引用完整措辞。
- plist 语法检查（`plutil -lint ...` → `OK`）只证明 plist 合法，不证明 program 路径存在；搬迁后的路径要自己验。
