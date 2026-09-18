---
id: ps-script-name-match-hits-unrelated-copy
type: lesson
status: candidate
scope: global
domain: ops
tags: [ps, process-matching, false-positive, watcher, attribution]
triggers:
  - "用 `ps | awk '/xxx.sh/'` 判断某个后台脚本/任务是否还在跑"
  - "轮询的完成条件迟迟不满足，但日志与锁文件都显示任务已经结束"
  - "同机存在把脚本 cp 到 /tmp 或别的 root 再跑的测试夹具（失败信号：进程列表里多出不属于本任务的 PID）"
  - "给 watcher/看门狗写存活判据，手上只有脚本名、没有 PID"
  - "报告里出现无法归属到本轮次的进程（失败信号：把别人的活算成自己的）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b211-aaee-73b1-bdd8-c2cfeae4ad73
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [stop-condition-on-hour-scale-metric-is-not-a-stop-condition, bash-source-root-breaks-when-script-moved]
---

# 用脚本名匹配进程 = 不是身份判据：别的 root 下的同名副本会混进你的存活判据

## 主张

判"我的后台任务还在不在"时，用脚本名做 pattern（`ps -eo pid,etime,command | awk '$0 ~ /evo-distill\.sh/ && $0 !~ /awk/'`）**不是身份判据**：同一台机器上任何把同一脚本 `cp` 到别处再跑的副本（测试夹具、临时改造、包装脚本）都会命中同一 pattern。后果是双向的——判据可能永远不满足（任务其实早结束了），也可能把别人的进程算成自己的任务（状态误报）。判据要绑**身份**：锁文件里的 PID + 参数形状（如 `--slot N --slots 4`）+ 启动路径，而不是裸文件名。

## 证据（本会话，命令 ↔ 结果）

轮次正常成员是 runner `86143` 与 4 个 worker `86154–86157`（都是 `bash ./ops/bin/evo-distill.sh ...`）。01:41:43Z 的存活检查里，同一条 pattern 多捞到两个**无关**进程：

```
67697  00:06  /bin/bash -c cd /tmp/evo-verify && rm -rf drainroot && mkdir -p drainroot/ops/bin ... \
              cp ~/Dev/evo-kernel/ops/bin/evo-drain.sh ~/Dev/evo-kernel/ops/bin/evo-distill.sh drainroot/ops/bin/ ... \
              bash drainroot/ops/bin/evo-drain.sh --until 5 --round-max 12 --budget-hours 1 ...
67723  00:06  bash /tmp/evo-verify/drainroot/ops/bin/evo-distill.sh --max 12
```

两个要点：

1. 这对进程是**另一个会话的 /tmp 验证夹具**（复制到 `/tmp/evo-verify/drainroot/` 后跑），与本次被等待的轮次无任何关系，却同时命中 `evo-distill\.sh`。
2. 该夹具 `cp` 的是**两个**脚本（`evo-drain.sh` 与 `evo-distill.sh`），所以"等 drain 结束"这类判据（`awk '$0 ~ /evo-drain\.sh/'`）同样会被它污染——即污染面取决于有人复制了哪些脚本，事前不可枚举。

正确处置（本会话实际做法）：识别出这条 PID 不属于本轮次后，把结论限定到轮次自己的 PID（`86143` 与带 `--slot N --slots 4` 的 worker），并在报告里把它记为 anomaly，而不是据此宣布"任务还在跑"。

## 边界 / 反例

- 单人单机、脚本无副本时，裸名字匹配够用；本条只在**同机存在副本或包装调用**时成立（`cp` 到 /tmp、`bash -c` 里内嵌脚本路径、wrapper 调同名脚本都算）。
- 另一端的同类坑：pattern 不带 `$0 !~ /awk/` 时，**自己这条 `ps | awk` 命令**也会命中（本会话的命令里显式排除了）。
- 只靠 `ps` 的 PID 也非永久身份：PID 会被复用。短期轮询里 PID 足够；跨小时还要配 etime/启动时间或锁文件内容。

## 失败信号（未来命中即该想起本条）

- 轮询判据长时间不满足，但日志/锁文件/队列都指向"任务已结束"。
- 进程列表里出现无法归属到本轮次的 PID（路径不在本仓库、参数形状不符）。
- 你在报告里写下某个 PID，却说不清它是谁的。
