---
id: unittest-discover-needs-importable-start-dir
type: lesson
status: validated
scope: global
domain: python-testing
tags: [unittest, test-discovery, python39, packaging]
triggers:
  - "把 python3 -m unittest discover -s tests -t . 写成仓库验收命令"
  - "unittest discover 报 ImportError: Start directory is not importable（失败信号）"
  - "新建 tests/ 目录放 test_*.py，仓库根跑测试发现"
  - "测试文件明明存在，discover 却一个测试都没收集到或直接抛异常"
created: 2026-08-26
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:4d3d2ce6-7892-45c1-a48b-f1a8bd781b98
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [bare-venv-test-with-stdlib-unittest]
---
一句话主张：用 `python3 -m unittest discover -s tests -t .` 作验收命令时，`tests/` 必须是可 import 的包（放一个空 `tests/__init__.py`），否则本机 python3 3.9.6 直接抛 `ImportError`（切片中错误文本截断为 `ImportError('Start d`…），与 `tests/` 里有没有测试文件无关。

为什么：`-t .` 指定 top-level dir 后，discover 会把 start dir 当成相对 top-level 的可导入包来加载；start dir 不可 import 时 discover 在收集阶段就失败，不是"收集到 0 个测试"这种软失败，而是异常退出——所以只写好 `tests/test_*.py` 却不建 `__init__.py` 的方案，验收命令必然跑不通。

边界/证据链接（均来自会话 4d3d2ce6 的命令 ↔ 结果切片）：
- `python3 --version` → `Python 3.9.6`（Xcode CommandLineTools 自带的系统 python3）。
- 空仓库场景：`python3 -m unittest discover -s tests -t . -p 'test_*.py' -v` → `Traceback ... ImportError('Start d`…，即 `tests/` 无 `__init__.py` 时无测试文件也照样抛异常。
- mktemp 最小复现：临时目录里造 `math_utils.py` + `tests/`（含 unittest 测试）后跑 `=== without tests/__init__.py ===` 分支 → 同样 traceback。
- 未在切片中看到"加上 `__init__.py` 后通过"的完整输出（结果文本被切片截断），所以"补空 `__init__.py` 即修复"这一半是评审员结论而非本次实测；引用时对修复侧留一分保守。
- 2026-09-16 独立复验（交互模型，非原会话）：`tests/` 无可 import 包时 `python3 -m unittest discover -s tests -t .` → `ImportError: Start directory is not importable`
