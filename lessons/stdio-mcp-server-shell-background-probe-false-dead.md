---
id: stdio-mcp-server-shell-background-probe-false-dead
type: lesson
status: candidate
scope: global
domain: mcp
tags:
- mcp
- stdio
- smoke-test
- shell
- background-process
- stdin-eof
triggers:
- 用 `cmd > log 2>&1 &` + sleep + kill -0 探活一个 stdio MCP server
- MCP server 后台启动后立刻退出，重定向的日志却是 0 字节、无任何报错（失败信号）
- '依赖修好了、import 也过了，但 server 一启动就『FAILED: server exited』'
- 想脱离宿主（Claude Code/pi）验证 stdio MCP server 能不能跑
created: 2026-07-30
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: session:9df36dfc-790a-4022-b8d8-620e0ced67ea
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related:
- stdio-mcp-probe-handshake-not-help
---

**主张**：stdio MCP server 不能用 shell 后台方式探活——`python server.py > /tmp/log 2>&1 & sleep 3; kill -0 $PID` 会**假死误判**：server 启动后因 stdin 立即 EOF 而干净退出，退出时不写任何错误，重定向的日志是 0 字节，看起来莫名崩溃。同一环境改用 `subprocess.Popen(..., stdin=PIPE)` 持住 stdin 探活，server 存活正常。验收 stdio server 要么管道喂 JSON-RPC 帧（见 related），要么用 Popen 持住 stdin，不要裸 `&`。

**证据（切片硬证据）**：
- 依赖已修好（`FastMCP import OK`）之后：`$ python tools/multi_model_mcp.py & sleep 3; kill -0 $PID` → `FAILED: server exited`。
- 加重定向再试：`> /tmp/mcp_test_out.log 2>&1 &` → 仍 `FAILED: server exited`，且 `cat /tmp/mcp_test_out.log` 为空、`ls -la` 显示 **0 字节**——无 traceback，排除代码报错。
- 换手法：`$ python -c "subprocess.Popen([...server...]) ..."` → `alive: True terminated OK`，同环境同脚本存活。

**边界**：「stdin EOF 导致干净退出」是对现象对照的最合理解释，切片未直接打印退出原因；硬证据是「shell `&` 必退 + 空日志 / Popen 持 stdin 则活」这组对照本身。此坑的凶险在于**零错误输出**——容易误导人回去瞎改 server 代码。
