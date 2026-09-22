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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
docker 无关、自包含、本机刚跑过：

  cd /Users/zodyne/Dev/evo-kernel && node -e 'const{execFileSync}=require("node:child_process");const EVO="/Users/zodyne/Dev/evo-kernel/bin/evo";for(const n of[524288,1048576]){const p=JSON.stringify({content:"x".repeat(n)});try{console.log(n+" -> "+execFileSync(EVO,["guard","--tool","write","--input-json",p],{timeout:6000}).toString().trim())}catch(e){console.log(n+" -> THROW "+e.code)}}'

期望输出（已实测）：
  524288 -> {"action":"allow"}
  1048576 -> THROW E2BIG

（对照的纯 OS 最小版：node -e 'const{execFileSync}=require("node:child_process");[524288,1048576].forEach(n=>{try{execFileSync("/bin/echo",["x".repeat(n)],{stdio:"ignore"});console.log(n+" OK")}catch(e){console.log(n+" FAIL "+e.code)}})' → 524288 OK / 1048576 FAIL E2BIG。）
```

**审核给出的修改意见（要点）**：核心主张站得住、可当场复跑，留在注入集（playbook），只做三处轻改：1) 证据节标题「（本会话命令 ↔ 结果）」名不副实——第 2、3 条实为「读源码断言」，切片里没有对应输出（相关命令的输出被截断）。改按文件引用：~/.pi/agent/extensions/evo-kernel.ts 的 tool_call 处理器 + call()（argv 数组字面量、catch{return ""}、if(!out) return）、bin/evo 的 'hook-guard'()（readStdin）。2) 把可复跑命令写进证据，替换「边界」里那句「没有端到端跑一次 >1MB 的 write 调用确认守卫真的无判定」——本机已复现 512KB→{"action":"allow"}、1MB→THROW E2BIG，即 >1MB 时守卫进程根本没启动、扩展 catch 吞成空串静默 return。3) 阈值收窄为「768KB OK / 1MB FAIL，阈值落在 768KB–1MB 之间」（原 512KB–1MB 偏松，不算错）。「为什么」里的 ARG_MAX/MAX_ARG_STRLEN/Linux≈128KB 是切片外的通用机制补充，正确且已在边界节限定了跨平台，可保留但建议标为「通用背景，非本会话证据」。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- Linux 单参数 MAX_ARG_STRLEN 更小，约 128KB

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
