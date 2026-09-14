---
id: cwd-script-shadows-stdlib-module
type: lesson
status: candidate
scope: global
domain: python
tags: [python, import, stdlib-shadow, cwd, tmp-scripts, lxml, python-docx]
triggers:
  - "在 /tmp 或项目根写一次性 python 脚本，文件名撞 stdlib（inspect.py / types.py / json.py / copy.py）"
  - "同一个脚本刚才还能跑，现在在同一目录下报第三方库导入错误（失败信号）"
  - "traceback 里 lxml.etree / docx 的 import 链指向 /private/tmp/xxx.py 这种自己写的文件"
  - "python3 -c 'import <某库>' 在某个 cwd 下失败、cd 到别处就成功"
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e9b77b86-b6b5-441e-a133-e72516849e75
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [make-nothing-to-be-done-check-cwd]
---
# 一次性脚本撞 stdlib 名字，会把同目录下所有 python 调用一起搞坏

## 主张
在工作目录里放一个与 stdlib 同名的临时脚本（本次是 `/tmp/inspect.py`），会通过 `sys.path[0]=cwd` 抢占 stdlib 模块，
使**同目录下任何** python 调用在导入第三方库时炸掉；报错位置指向第三方库内部（`lxml.etree`），与真实原因无关。
症状是"脚本没改却突然坏了"。排查动作：看 traceback 里有没有指向自己写的文件的那一行，`rm` 掉同名脚本与 `__pycache__` 即恢复。

## 为什么
第三方库内部会 `import inspect` 之类的 stdlib，而 cwd 优先于 stdlib 路径，于是拿到的是本地脚本；
本地脚本执行到自己的 `from docx import ...` 又反向触发导入，栈顶显示成 lxml/docx 的问题。
错误信息把因果关系完全颠倒，是这条教训的价值所在——不看 traceback 中间层就会去怀疑库装坏了/版本冲突。

## 证据（本会话命令对照）
- 早前 `python3 /tmp/dump_docx.py "<合同>.docx"` 正常产出 251 行；此后写入 `/tmp/inspect.py` 并运行，报
  `Traceback ... File "src/lxml/parsertarget.pxi", line 5, in lxml.etree / File "/private/tmp/inspect.py", line 3, in <module>`。
- 复现最小化：`cd /tmp && python3 -c "import docx"` → 同一条 `lxml.etree` → `/private/tmp/inspect.py` traceback（脚本自身没被显式调用）。
- 此时**原本能跑**的 `python3 /tmp/dump_docx.py "<合同>.docx" | head -3` 也开始报同一 traceback（"脚本没改却坏了"）。
- 修复：`rm -f /tmp/inspect.py && rm -rf /tmp/__pycache__ && cd /tmp && python3 -c "import docx; print('docx OK')"` → `docx OK`，dump 随即恢复正常输出。

## 边界 / 反例
- 本次同时删了 `.py` 与 `__pycache__`，**无法区分**单删 `.py` 是否已足够；保守做法是两者同删。
- 只影响以该目录为 cwd（或该目录在 sys.path 前部）的调用；换目录跑同一脚本可能"看起来好了"，会掩盖根因。
- 命名规避比事后排查便宜：一次性脚本统一加前缀（`dump_docx.py` 这次没出事，正因为它不撞 stdlib）。

## 失败信号（未来命中即该想起本条）
- 第三方库 traceback 里夹着一行自己写的临时脚本路径。
- "我什么都没改，它自己坏了" + 报错来自 import 阶段。
