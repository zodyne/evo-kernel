---
id: httpx-single-timeout-slows-connect-failure
type: lesson
status: candidate
scope: global
domain: http-client
tags: [httpx, timeout, llm-api, python, 长请求]
triggers:
  - "给 httpx.AsyncClient/Client 配超时，写了单一的 timeout=秒数"
  - "LLM/生成类长请求要等几分钟，但连接失败也傻等同样的时长（失败信号）"
  - "端点挂了/代理断了，客户端几分钟才报错而不是秒级失败"
  - "封装多模型 API 调用工具，设计 connect/read 分离的超时策略"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:0a908942-190f-4fef-b7db-437423af1169
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [llm-api-proxy-timeout-wall-retry-futile]
---

`httpx.AsyncClient(timeout=300.0)` 这一个值会同时作用于 connect/read/write/pool 四个阶段：端点或代理层故障时，**连接失败也要等满 300 秒**才报错。长生成请求的正确配法是拆分：`httpx.Timeout(connect=10.0, read=300.0, write=30.0, pool=30.0)`——connect 短（故障秒级暴露），read 长（容纳生成耗时）。

会话证据：`multi_model_mcp.py` 里多处 `httpx.AsyncClient(timeout=300.0)`（grep 命中 736/780 行等）被统一替换为模块级 `_DEFAULT_TIMEOUT = httpx.Timeout(connect=10.0, read=300.0, write=30.0, pool=30.0)`（173 行定义、185 行使用）；改后 `python3 -m py_compile` 通过、`.venv/bin/python3 -m unittest` 23 个测试全绿。

边界：替换时注意散落的多处字面量（本会话 sed 全局替换后仍有残留命中，需 grep 复查）；超时对象宜提成模块级常量，避免各处字面量漂移。
