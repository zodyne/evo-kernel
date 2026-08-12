---
id: bare-venv-test-with-stdlib-unittest
type: lesson
status: candidate
scope: global
domain: python-testing
tags: [unittest, pytest, venv, 工具仓库, 测试]
triggers:
  - "给无 CI 的单机工具仓库（tools/ 脚本集合）写测试"
  - "项目 .venv 里没装 pytest，import pytest 报 ModuleNotFoundError（失败信号）"
  - "验收改动要跑测试，但不想为跑测试先装一堆依赖"
  - "测试框架选型：pytest 还是 stdlib unittest"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:0a908942-190f-4fef-b7db-437423af1169
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
---

无 CI 的工具仓库，测试用 **stdlib unittest** 写：裸 venv（只有 python，没装 pytest）也能 `python3 -m unittest <模块>` 直接跑，验收不引入额外安装步骤。

会话证据：`graph-lab/.venv` 里 `.venv/bin/python3 -c "import pytest"` 直接 Traceback（ModuleNotFoundError）；同一 venv 跑 `.venv/bin/python3 -m unittest tools.test_multi_model_mcp` 则 `Ran 23 tests ... OK` 全绿——测试文件本身就是 unittest 风格，零额外依赖完成验收。

边界：这只覆盖"能跑"；py_compile/测试全绿不代表外部 API 真实调通（见 untested-tool-config-bugs-stay-invisible），涉及真实端点的工具仍需一次直连 smoke。
