---
id: argv-json-over-argmax-silently-bypasses-guard
type: lesson
status: validated
scope: global
domain: tooling
tags: [argv, arg-max, e2big, fail-open, guard, stdin, subprocess]
triggers:
  - "把 JSON / 大段文本当命令行参数传给外部 CLI 或子进程（--input-json、--data 之类）"
  - "旁路校验进程在输入变大后不再产生任何判定，但调用侧不报错（失败信号）"
  - "审查 fail-open 包装（try/catch → 返回空串）的外部调用，想知道哪些异常会被静默吞掉"
  - "在 macOS 上把 512KB–1MB 量级的参数传给 execFileSync / spawn（失败信号：E2BIG）"
  - "设计扩展/钩子把宿主工具输入转发给旁路闸门，要选 argv 还是 stdin 传参"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bc84-d38b-76aa-9257-83bbda1ace9a
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [pi-extension-sync-exec-blocks-event-loop]
---

# 大 JSON 走 argv 会在 ~1MB 撞 E2BIG：fail-open 的调用侧把它吞成"守卫静默放行"

## 主张

把工具输入 JSON 作为命令行参数传给旁路守卫进程（`evo guard --tool write --input-json <json>`）
会撞上进程创建的参数上限：**实测 512KB 通过、1MB 抛 `E2BIG`**（在 `execFileSync` 里同步抛出），
阈值落在 512KB–1MB 之间（macOS ARG_MAX ≈1MB）。
由于调用侧是 fail-open（`catch → ""`），异常被当成"没有输出"而非"检查失败"：
`return ""` 之后 handler 直接 return，**大 payload 的工具调用被整段跳过校验，且没有任何落盘信号**。
大 JSON 必须走 stdin（同仓 `hook-guard` 已是该形态）；fail-open 的 catch 至少应写降级账，
否则"守卫在跑"只是小输入下的假象。

## 为什么

E2BIG 不是守卫逻辑的限制，而是 exec 系统调用的限制（参数+环境总量的上限，macOS ≈1MB；
Linux 单参数 `MAX_ARG_STRLEN` 更小，约 128KB），所以它不随守卫代码改进而消失。
危险组合是"argv 传大输入" + "catch 后按无结论处理"：
写大文件（`write` 工具 content 直接进 argv）恰好是最需要检查的操作之一，
而它的检查失败路径与"没有规则命中"在调用侧完全同形——不 block、不 warn、不留痕。

## 证据（本会话命令 ↔ 结果）

- 体积递增复现（node 内直接对 `execFileSync("/Users/zodyne/Dev/evo-kernel/bin/evo", ["guard","--tool","write","--input-json", json])` 调用）：

  ```
  === 大参数 E2BIG 测试 ===
  51200 OK
  204800 OK
  266240 OK
  524288 OK
  1048576 FAIL E2BIG
  ```

- 扩展源码：guard 调用把输入塞进 argv —— `["--tool", event.toolName, "--input-json", JSON.stringify(event.input ?? {})]`；
  `call()` 是 `try { execFileSync(...) } catch { return "" }`，`out` 为空即 `return`，不 block / 不 warn / 不落账。
- 对照：同仓 `hook-guard` 用 stdin 传 JSON，说明改造路径存在且成本极低。
- 附带泄漏（边界提示，未验证）：argv 对同机其它进程可见（`ps`），bash 命令里嵌的 token/密钥会暴露。

## 边界 / 反例

- 未二分精确阈值：只证明 512KB OK / 1MB FAIL；且 ARG_MAX 是"参数 + 环境"总量，环境变量变长会降低可用额度。
- "大 payload 被静默跳过"是"复现 E2BIG + 读 catch 代码"推出的；**没有**端到端跑一次 >1MB 的 write 调用确认守卫真的无判定。
- NUL 字节参数会在 Node 层抛错，从而同样静默跳过——未实测。
- 跨平台阈值不同（Linux 单参数上限更低），换平台要重测。
- 若调用侧改成 fail-close（异常即拒绝），要另行评估误拒代价；本条只主张"别把失败伪装成放行，且大 JSON 走 stdin"。
