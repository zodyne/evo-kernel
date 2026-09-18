---
id: nvim-quit-sighup-not-crash-triage
type: lesson
status: candidate
scope: global
domain: nvim
tags: [nvim, pi, sighup, crash-report, forensics, triage]
triggers:
  - "用户/自己报告某个 TUI 程序（nvim）『闪退』，要判断是真崩溃还是被外部退出连带杀死"
  - "在 nvim 内嵌终端里跑的 CLI agent（pi/codex）会话 jsonl 在半途截断（失败信号）"
  - "要去 ~/Library/Logs/DiagnosticReports 确认闪退有没有留下崩溃报告"
  - "agent 会话末条 toolCall 是 `nvim … +qa` / `+qa!` 且没有配对 toolResult（失败信号：宿主正好在此后消失）"
  - "想把『闪退』直接归因到内存/渲染/插件崩溃，准备按崩溃方向排查"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a7af-25c7-725c-a75a-f990cf4e0e58
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [flatten-nvim-nest-headless-crashes-host, pi-jsonl-toolresult-toolcallid-pairing]
---

# 定性"闪退"先查崩溃报告：没有报告 + agent 会话半途截断 ⇒ 是干净退出被 SIGHUP 带走，不是崩溃

**主张**：面对"nvim 闪退"这类报告，先用**有没有崩溃报告**把两类终结分开：macOS 看 `~/Library/Logs/DiagnosticReports` 里有没有对应进程的条目。没有条目 ⇒ 进程是**干净退出**（`EXIT`/被信号带走），不要按"崩溃"方向排查内存/渲染/插件。再补第二条证据：在 nvim 内嵌终端里跑的 agent，其会话 jsonl 会**半途截断**（末条是用户看不到结果的 toolCall），而末条那条 toolCall 的内容（如 `nvim --headless "+checkhealth" +qa`）就是"谁把宿主关掉的"自证。

**为什么**：崩溃报告是操作系统对异常终止的登记，干净退出（`:qa!`）不产生报告——所以"用户看到的是闪退"和"进程崩了"是两件事。nvim 内嵌终端里的子进程处在宿主 PTY 的前台进程组：宿主 nvim 一退，内核给它们发 SIGHUP，agent 来不及写 toolResult 就被杀，因此 transcript 停在一个未配对的 toolCall 上。两条证据合起来才能把现象定性成"外部退出命令把宿主带走了"，从而把根因指向命令来源而不是崩溃。

**证据（本会话）**：
- 会话里对被复核的 09-14 会话做整体检索：`echo "=== 崩溃报告/干净退出 in all parts ==="` 命中的文本为『nvim 执行了 `:qa!` → 正常退出 → 终端里的 pi 收到 SIGHUP 一起死 → 会话日志在半途截断。所以看到的是"闪退"（干净退出，没有崩溃……）』；同批检索里还有一条 `=== crash report / 崩溃报告 ===` 命中段带 `=== DiagnosticReports`（即确实去看了崩溃报告目录）。
- 末条 assistant 复核摘要：『核心结论站得住（会话 A/B 末事件确为无 toolResult 的 `+qa`/`+qa!` toolCall、nvim.log 重启序列吻合、flatten core.lua:55-90 转发机制源码逐字吻合、sidekick spec 与 settings.json 吻合……）』。
- **诚实标注**：本条验证强度为 human——切片对每条命令的结果做了截断，"没有崩溃报告"与"末事件是无 toolResult 的 toolCall"两个关键事实来自被复核会话的结论文本 + 本会话复核者的判定，切片里没有可见的一手列目录输出/配对 diff 输出。

**边界 / 反例**：
- **反向不成立**：没有崩溃报告 ≠ 一定是 SIGHUP。SIGKILL / OOM / 父进程清理 / `kill` 同样不产生报告；要再问"谁先死、谁发的退出命令"（pairing 判据见 related 的 `pi-jsonl-toolresult-toolcallid-pairing`）。
- 本条只管**定性顺序**，不管修法；flatten.nvim 场景的机制与逃生门见 related 的 `flatten-nvim-nest-headless-crashes-host`（两条互补，不重叠）。
- `~/Library/Logs/DiagnosticReports` 是 macOS 专属路径；Linux 要走 `coredumpctl` / `/var/crash`，别照搬。

**失败信号（未来命中即该想起本条）**：报告只说"闪退/崩了"就开查渲染/插件；或复核清单里出现"SIGHUP 杀死"却拿不出一条"无崩溃报告"的取证。
