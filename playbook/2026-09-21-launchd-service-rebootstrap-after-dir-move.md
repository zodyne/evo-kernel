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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含最小复现（本机已跑，uid=501；用一次性 label，跑完 bootout+rm，不碰用户服务）：

# 1) bootstrap exit=0 ≠ job 在运行：program 指向不存在的路径
PLIST=$(mktemp -d)/com.zodyne.evorepro.plist
cat > "$PLIST" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.zodyne.evorepro</string>
  <key>ProgramArguments</key><array><string>/nonexistent/dir/prog</string></array>
  <key>RunAtLoad</key><true/>
</dict></plist>
EOF
launchctl bootstrap gui/$(id -u) "$PLIST"; echo "bootstrap exit=$?"
launchctl print gui/$(id -u)/com.zodyne.evorepro 2>&1 | rg '^\s+(state|pid|last exit) '
# 实测：bootstrap exit=0；但 print 显示  state = xpcproxy / last exit code = (never exited)，并非 state = running，进程随即不在 ps 里。
launchctl bootout gui/$(id -u)/com.zodyne.evorepro

# 2) 正常程序也要等它「settle」：bootstrap 后立刻 print 常是 xpcproxy，2s 后才是 running
#    /bin/sleep 300 那次：immediately → state = xpcproxy, pid=96522；2s 后 → state = running, pid=96522，ps 见 `/bin/sleep 300`。

# 3) 支持条目边界「label 被占用时 bootstrap 会失败，先 bootout」：
launchctl bootstrap gui/$(id -u) "$PLIST2"   # 第一次 exit=0
launchctl bootstrap gui/$(id -u) "$PLIST2"   # 第二次：Bootstrap failed: 5: Input/output error（exit=5）
```

**审核给出的修改意见（要点）**：保留在注入集，但做三处收窄/换证（核心技法稳定且本机可复验，故不降级）：(1) 收窄「为什么」中的「job 消失」→「该 job 未在运行（日志显示 service inactive）」，删去「消失」这一未证据化的措辞；(2) 把「目录搬迁 → agent 不再运行」从「一般因」降为「本起事故的可疑触发」，触发器改写为「launchd 托管的本地服务端口无人监听 / 日志 service inactive」这类可观测症状，别把推断出来的根因写死为触发条件；(3) 证据节补入自包含最小复现（见 minimalRepro）替换/补强依赖被截断历史命令的那两条，把「bootstrap exit=0 ≠ running」由机制叙述变成可当场重跑的命令证据；同时保留并显式引用「label 被占用时 bootstrap 失败(exit=5) → 先 bootout」这条边界（本机已复现）。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 「目录搬迁会让原注册的 program 路径失效、job 消失」——切片里 launchd 日志是 `service ina...`（inactive，即服务已注册但未运行），且没有任何命令显示该 job 从 launchctl 中「消失」（bootstrap 前未跑过 `launchctl print/list` 证明 job 缺位）。「job 消失」是超出证据的断言，与「inactive」并不等同。
- 触发条件把一次观测升格：「服务程序目录被搬迁（~/Dev/x → ~/.claude/x）后 launchd agent 不再运行」被当成一般因果律。切片未给出隔离因果的命令，且同会话时段并存 /model 切换、settings.json 改写（10:54/11:09）、1080 代理事件；日志显示服务 11:05 即 inactive，而「迁移完成」报告在 11:17——切片不足以把「目录搬迁」定为根因。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
