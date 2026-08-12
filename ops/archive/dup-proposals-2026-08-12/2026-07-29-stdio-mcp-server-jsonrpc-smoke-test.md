---
id: stdio-mcp-server-jsonrpc-smoke-test
type: lesson
status: candidate
scope: global
domain: mcp
tags: [mcp, smoke-test, jsonrpc, stdio, acceptance]
triggers:
  - "装完/改完一个 stdio MCP server，想不启动宿主（Claude Code/pi）就验证它能不能用"
  - "MCP server 注册进宿主后没反应，要定位是 server 本身坏还是宿主配置错"
  - "pip 依赖装完想分钟级确认 MCP server 能 initialize（失败信号：启动即 traceback）"
  - "验收 MCP server 只跑了 --help 或 import 检查"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fae52-a170-7aba-bfe6-f7e1676655d0
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [untested-tool-config-bugs-stay-invisible]
---

**主张**：stdio MCP server 可以脱离宿主直接冒烟——用 printf 把 JSON-RPC 帧（initialize → tools/list → tools/call）按行管道进 server 进程的 stdin，看 stdout 应答即可分钟级验证真活。

**证据**：会话中对 pal-mcp-server 连续三次用 `(printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize",...}' ...; sleep 1) | .pal_venv/bin/python server.py` 验证：第一次暴露 mcp 2.0.0 启动即 AttributeError；修依赖后 `INIT ok` + 列出 6 个工具；再 `tools/call` 暴露 chat 缺必填参数、补参后拿到 `PAL-GLM-OK` 真实模型响应。全程没重启 Claude Code。

**边界**：这是 `untested-tool-config-bugs-stay-invisible`（必须真实调一次）的具体手法；注意 stderr 要和 stdout 分开看——traceback 走 stderr，应答 JSON 走 stdout。
