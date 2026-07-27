---
id: claude-code-sleep-blocked-poll-output
type: lesson
status: validated
scope: global
domain: claude-code
tags: [claude-code, harness, background-task, sleep-blocked, gui-launch, polling]
triggers:
  - "Claude Code 里 `sleep N; cat <file>` 被 tool_use_error 拒绝"
  - "后台启动 GUI/服务后想等它就绪再读输出文件"
  - "轮询后台任务输出文件判断进程已启动还是已崩溃"
  - "sleep 紧跟后续命令的组合被 harness 拦截"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:6f9c92c5-482a-40a9-8810-6dd388611e95
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# Claude Code 拦截 `sleep N; <cmd>`，等待后台任务就绪改用输出文件轮询

## 主张
Claude Code 的 bash 工具会拦截 `sleep <N>; <后续命令>` 这种模式，直接返回 `<tool_use_error>Blocked: sleep <N> followed by: <后续命令>`，根本不执行。需要"等后台进程就绪再读输出"时，**不要**用固定 sleep 盲等，改用**对输出文件做条件轮询**：`until grep -q "就绪标志\|Traceback\|Error" <output_file>`（这条 until 本身可放进一个后台命令块），就绪或崩溃都能尽快拿到结果。

## 为什么
harness 把"sleep 后紧跟命令"判定为浪费/反模式而直接拒绝。轮询 grep 既实现了"等到条件成立再继续"，又比固定 sleep 高效——进程就绪即可读，进程崩溃（打印 Traceback/Error）也能立即被条件捕获跳出，不会死等。

## 证据（本会话命令对照）
- ❌ `sleep 25; cat .../tasks/b0cponrxs.output` → `✗ <tool_use_error>Blocked: sleep 25 followed by: cat ...`
- ✅ 改用 `until grep -q "启动查看器\|Error\|Traceback" .../tasks/<id>.output 2>/dev/null` 轮询（作为后台命令块），随后 `grep -c "Traceback\|Error" .../tasks/<id>.output` 返回 `0`，确认 GUI 正常启动。
- 该 `until grep -q "启动查看器\|Traceback"` 模式在会话内被**反复使用**（后台任务 bguu0bamw / b3hnhv0m0 / bozc3gyhh / bpqpjyk3j / bqtu07yvm 等多次 viewer 启动均以此确认就绪），是稳定的替代写法。

## 边界 / 反例
- 轮询条件要同时纳入"就绪行"与"崩溃标志"（本例 viewer 自己打印的 `启动查看器 ...` + `Traceback`/`Error`），这样成功和失败两条路都能尽快结束，避免死等。
- 该 sleep-block 是 Claude Code harness 行为；在普通终端/CI shell 里 `sleep N; cmd` 正常可用。
- 若进程没有可观测的"就绪"输出行，轮询无从 grep，此时需换其它同步机制，别退回 sleep。

## 失败信号（未来命中即该想起本条）
- 在 Claude Code 里写 `sleep <N>; <cmd>`，立即拿到 `Blocked: sleep <N> followed by:` → 切到输出文件轮询。
