---
id: bash-loop-child-steals-stdin
type: lesson
status: candidate
scope: global
domain: shell-scripting
tags: [bash, stdin, while-read, batch-driver, silent-failure]
triggers:
  - "写 while read 循环批量处理一份清单"
  - "循环里调用外部命令/子进程（pi、ssh、ffmpeg、docker）"
  - "批处理只处理了第一条就退出，退出码还是 0"
  - "--max/--limit 这类批量参数看起来没生效"
  - "后台驱动器日志显示『本轮完成 1 个』但队列没怎么变短"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
`while read ... done <<< "$LIST"`（或 `done < file` / 管道喂入）的循环里，**任何读 stdin 的子进程都会继承那份清单并把剩余行吃光**，循环下一圈立刻读到 EOF 正常退出——**退出码 0，日志看起来像"处理完了"**。批量参数因此形同虚设。

**修法**：给子进程显式接空输入 `cmd < /dev/null`。这是唯一稳的写法——无论脚本自己的 stdin 是什么都成立。

**不要只换独立 fd**：`while read -u 3 ...; done 3<<< "$LIST"` 确实护住了清单，但子进程会转而去读脚本继承来的 stdin；在交互式终端里那是个不会 EOF 的 tty，**直接挂死**（比只跑一圈更糟）。实测三种写法：裸写→1 圈；子进程 `< /dev/null`→3 圈（脚本 stdin 是 tty 或 /dev/null 都对）；只换 fd 3→脚本 stdin 是 tty 时挂死，是 /dev/null 时才 3 圈。要用 fd 3 就必须**同时**给子进程 `< /dev/null`，那 fd 3 本身就成了多余的。

**证据**：`ops/bin/evo-distill.sh` 的 `pi -p --no-session "$PROMPT" > "$OUT" 2>&1 &` 继承了 `done <<< "$QUEUE"` 的 stdin。`--max 13` 实际只蒸馏 1 个会话、日志写"本轮完成 1 个；剩余队列 12"、exit 0。加 `< /dev/null` 后，用一个 `cat > /dev/null; exit 1` 的 pi 桩重跑 `--max 13`（退出码非 0 → 不 mark-distilled、不改状态），日志新增 **12 条 `start`**，正是队列全量。

**为什么难发现**：失败是静默的且方向"安全"——少做事、不报错、退出码 0。当默认批量小（该脚本默认 `--max 2`）时，"只跑 1 个"和"正常"几乎无法从日志区分；我据此错误推算过整体耗时。**排查信号**：批量数与实际处理数长期差 1 圈，先怀疑 stdin 而不是队列逻辑。

**边界**：只影响会读 stdin 的子进程。`echo`/纯计算命令不触发，所以同一份脚本换个子命令可能"突然就好了"，容易误判成别的原因。
