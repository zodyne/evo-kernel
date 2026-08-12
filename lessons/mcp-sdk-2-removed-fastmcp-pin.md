---
id: mcp-sdk-2-removed-fastmcp-pin
type: lesson
status: candidate
scope: global
domain: mcp-toolchain
tags: [python-mcp, fastmcp, dependency-pin, claude-mcp]
triggers:
  - "ModuleNotFoundError: mcp.server.fastmcp"
  - "pip install mcp 装完跑不起来"
  - "新建 venv 装 mcp 2.x API 重构"
  - "claude mcp add 全局生效"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:9df36dfc
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
---

**主张**：Python MCP SDK 2.0 已重构 API、移除 `mcp.server.fastmcp`；依赖 FastMCP 的脚本在新 venv 里 `pip install "mcp[cli]"` 会装到 2.x 直接 `ModuleNotFoundError`。解法：锁定 `mcp[cli]==1.29.0`（或迁移到新 API）。新建环境装完先跑冒烟再注册。

**为什么**：requirements 写 `mcp[cli]` 不带版本时 pip 取最新 2.0.0，脚本 import 即崩；锁定 1.29.0 后冒烟通过。

**边界**：另记一条 claude mcp 事实——`claude mcp add --scope user` 写入全局用户配置，任意目录会话可用且不进 git，`-e KEY=value` 直接传密钥安全；project scope 写 `.mcp.json` 跟 git 走，密钥只能走环境变量。

**证据**：2026-07-29 graph-lab multi-model MCP 搭建会话，venv 重建踩坑后锁定版本修复。
