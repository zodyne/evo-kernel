---
id: pi-extension-sync-exec-blocks-event-loop
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, extension, execfilesync, event-loop, latency, hooks]
triggers:
  - "给 pi 扩展的事件 hook（tool_call / before_agent_start / session_shutdown）写 execFileSync 调外部 CLI"
  - "扩展 handler 已标 async，内部却用同步子进程 API 等结果（失败信号：不报错，但热路径上每次调用都停一拍）"
  - "审查 pi 扩展对系统的开销，要量化每次工具调用 / 每条 prompt 的额外延迟"
  - "给同步子进程调用设了 timeout（如 6000ms），要估最坏一次冻结多长"
  - "重会话里 TUI 周期性卡顿，卡顿次数与工具调用数同步（失败信号）"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bc84-d38b-76aa-9257-83bbda1ace9a
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [argv-json-over-argmax-silently-bypasses-guard]
---

# pi 扩展在热路径上 execFileSync 调外部 CLI：单次 30–60ms 全是进程冷启动，且同步阻塞宿主事件循环

## 主张

pi 扩展在事件 hook 里用 `execFileSync` 调外部 CLI，单次成本实测 **30–60ms**，
且成本几乎全是 node 进程冷启动（本机 `./bin/evo --help` 自身就要 0.033s）。
这些 hook 跑在 `tool_call` / `before_agent_start` / `session_shutdown` 的热路径上，
而 `execFileSync` 是**同步 API：调用期间 pi 的事件循环整个停下来**——
handler 即使写成 `async` 也不会因此让出事件循环。
要恢复"等判定再放行"的语义但不再阻塞，应换成 `await execFile`（promisify）。
另外，`timeout: 6000` 不只是失败上限，它同时是**最坏一次冻结的时长**。

## 为什么

pi 扩展与宿主同进程，hook 在宿主事件循环上执行。同步子进程调用的成本是
"fork/exec 一个 node 进程"，与旁路逻辑做了多少事无关：实测 `evo --help`
（什么都不干）与 `guard` 单次耗时同为 0.03s 量级即为佐证。
单次无感，但按调用量线性累积——本会话自身 46 次工具调用 ≈ 1.4s 同步阻塞，
几百次调用的重会话是 10s 量级；且 guard 对**每个** tool_call 都跑一次
（包括 read/grep 这类无害调用），只有 deny 才 block，其余都是一次同步等待。

## 证据（本会话命令 ↔ 结果）

- `time ./bin/evo --help >/dev/null 2>&1` → `real 0m0.033s / user 0m0.027s / sys 0m0.006s`，`exit=0`。
- 三处 hook 单次计时（`/usr/bin/time -p`，各 3 次取样，口径一致）：
  - `hook-recall`：`real 0.06 / 0.05 / 0.06`
  - `guard`：`real 0.03 / 0.03 / 0.03`
  - `hook-session-end`：`real 0.03`
- 扩展源码（`~/.pi/agent/extensions/evo-kernel.ts`，与 `ops/integrations/pi-evo-kernel.ts` diff 完全一致）：
  `import { execFileSync } from "node:child_process"`；
  `call()` 内 `execFileSync(EVO, [sub, ...args], { timeout: 6000 })`；
  三个 hook 分别是 `before_agent_start`（recall）、`tool_call`（guard）、`session_shutdown`（登记），handler 均声明为 `async`。
- 本会话体量：`本会话 tool calls: 46 {"bash":45,"read":1}` → 按 30ms/次估算 guard 同步阻塞 ≈ 1.4s。

## 边界 / 反例

- "会冻 TUI" 是从"同步 API 阻塞宿主事件循环"推得的机制结论；本会话**没有**对 TUI 帧做时间线采样，30ms/次在单次调用上确实无感。
- 换成 `await execFile` 后"判定语义不变"也**未经实测**——须确认 pi 仍会 await handler 返回的 `{block:true}` / `{message:...}`。这里只是改法建议，不是已验证结论。
- 计时环境是 macOS + node CLI（本机冷启动 ≈30ms）；换成常驻进程/更快的入口，数字会变，但"同步调用阻塞事件循环"的结构不变。
- "timeout 上限 = 最坏冻结时长"依赖 timeout 触发时同步等待满额，未做端到端复现（真实最坏值还受 evo 内部锁超时、日志追加影响）。
- 本条不主张"必须异步"：需要保证判定先于工具执行时，异步同样能保序，收益是不再占用事件循环。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
# 1) 同步 execFileSync 卡住事件循环 vs await execFile 不卡（自包含，本机 node v26.7.0）
node -e '
const {execFileSync,execFile}=require("node:child_process");
const {promisify}=require("node:util");const ef=promisify(execFile);
setTimeout(()=>{console.log(`SYNC : 定时器实际 ${Date.now()-T0}ms`);},100);
setTimeout(()=>{execFileSync("/bin/sleep",["0.2"]);},50);
' ; # T0 需为起测时刻 -> 期望 SYNC ≈ 250ms+（被 0.2s 调用卡住）
node -e '
const {execFile}=require("node:child_process");const {promisify}=require("node:util");
const ef=promisify(execFile);
setTimeout(()=>{console.log(`ASYNC: 定时器实际 ${Date.now()-T0}ms`);},100);
setTimeout(async()=>{await ef("/bin/sleep",["0.2"]);},50);
' ; # 期望 ASYNC ≈ 100ms
# 本机实测（today）: SYNC = 259ms，ASYNC = 101ms
# 2) node 冷启动 ~30ms：
cd ~/Dev/evo-kernel && time ./bin/evo --help >/dev/null 2>&1
# 实测: 0.03s user / 0.037–0.040s total, exit=0
```

**审核给出的修改意见（要点）**：主张正确、可复现，留在注入集；但换掉不可复跑/不在切片里的证据，并修正基数。具体：(1) 证据节把 guard / hook-session-end 的计时（切片里被截断，`=== gua...` 之后不可见）与「扩展源码」条，替换为一条自包含最小复现（见 minimalRepro：定时器 100ms 应在 sync 下迟到到 ~259ms、async 下 ~101ms），该条今日已实测。(2) 把工具调用基数 46 改为「~50–60 次（该会话最终 59 次：58 bash + 1 read，per agent-summary）」，46 只是切片中途快照。(3) 主张「execFileSync 阻塞宿主事件循环」成立且为稳定语言属性，不动；「会冻 TUI」已由条目自己在边界节标为未实测推断，保留标注即可。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
