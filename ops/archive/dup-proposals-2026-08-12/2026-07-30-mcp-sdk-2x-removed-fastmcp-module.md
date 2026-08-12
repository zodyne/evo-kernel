---
id: mcp-sdk-2x-removed-fastmcp-module
type: lesson
status: candidate
scope: global
domain: mcp
tags: [mcp, fastmcp, pip, dependency-pin, python, sdk-major-version]
triggers:
  - "按教程/模板写 Python MCP server，from mcp.server.fastmcp import FastMCP"
  - "pip install mcp 后脚本启动即 ImportError / ModuleNotFoundError（失败信号）"
  - "教程里的 mcp SDK 导入路径在本机装上后不存在"
  - "给 FastMCP 风格的 MCP server 脚本装依赖，pip 默认解析到 mcp 2.x"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:9df36dfc-790a-4022-b8d8-620e0ced67ea
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [pal-mcp-server-pin-mcp-sdk-1x]
---

**主张**：`pip install mcp` 现在默认装 2.x，其中**整个 `mcp.server.fastmcp` 模块已不存在**（`grep -r "class FastMCP"` 在 site-packages/mcp/ 里零命中）——任何按教程写的 `from mcp.server.fastmcp import FastMCP` 脚本启动即 ImportError。给这类脚本装依赖必须显式 pin 1.x，如 `pip install "mcp[cli]==1.29.0"`。

**证据（切片硬证据）**：
- `$ pip show mcp` → `Name: mcp Version: 2.0.0`（默认解析到 2.x）。
- `$ python tools/multi_model_mcp.py` → `Traceback ... line 19, in <module>`（导入即崩）。
- `$ grep -rl "class FastMCP" .venv/lib/python3.14/site-packages/mcp/` → 空；`mcp.server` 子模块列表里无 `fastmcp`。
- `$ pip install -q "mcp[cli]==1.29.0" httpx` 后 `python -c "from mcp.server.fastmcp import FastMCP"` → `FastMCP import OK`。

**边界**：与 `pal-mcp-server-pin-mcp-sdk-1x` 是同一主版本跃迁的**不同断点**——那条断在低层 `Server.list_tools` 装饰器（AttributeError），本条断在 fastmcp 模块整体移除（ImportError）；场景也不同（本条是通用教程脚本，非 pal 专有）。共性：`mcp>=x` 不设上限 = 定时炸弹。2.x 里 FastMCP 的替代形态（切片中 `grep FastMCP` 命中的一个 `MCPServer` 类来自另一包）未实测，本条只主张"1.x 写法 + pin 1.x 可用"。
