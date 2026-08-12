---
id: pal-mcp-server-pin-mcp-sdk-1x
type: lesson
status: candidate
scope: global
domain: mcp
tags: [pal-mcp, pip, dependency-pin, mcp-sdk, attributeerror]
triggers:
  - "安装/部署 pal-mcp-server（BeehiveInnovations PAL）"
  - "pip install -r requirements.txt 后 MCP server 启动即 AttributeError"
  - "server.py 报低层 Server 没有 list_tools 装饰器（失败信号）"
  - "给一个锁定 mcp SDK 1.x API 的 Python 项目装依赖"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fae52-a170-7aba-bfe6-f7e1676655d0
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [pyside6-old-version-fails-on-new-python]
---

**主张**：pal-mcp-server 依赖 mcp SDK 1.x 的低层 API；pip 现在会把 `mcp>=1.0.0` 解析到 2.0.0（低层 Server 删了 `list_tools` 装饰器），server.py 启动即 AttributeError。装依赖必须显式 pin `mcp>=1.0.0,<2.0.0`。

**证据**：会话中按 requirements.txt 安装后手动 JSON-RPC initialize 冒烟，server.py line 630 抛 AttributeError 崩溃；`pip install "mcp>=1.0.0,<2.0.0"` 后 `pip show mcp` 显示 1.29.0，再次 initialize 返回 `INIT ok: {'name': 'PAL', 'version': '9.8.2'}` 并列出 6 个工具。

**边界**：与 `pyside6-old-version-fails-on-new-python` 方向相反——那条是老包跟不上新 Python，这条是新主版本 SDK 砍了老 API。共性教训：声明 `>=` 不设上限的依赖，主版本跃迁即定时炸弹。
