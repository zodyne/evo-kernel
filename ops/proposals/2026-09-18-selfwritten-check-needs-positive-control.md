---
id: selfwritten-check-needs-positive-control
type: lesson
status: candidate
scope: global
domain: static-analysis
tags: [verification, positive-control, ast, self-check, false-negative]
triggers:
  - "自写脚本（ast / grep / 正则）做静态检查、死代码扫描，输出『全部干净』"
  - "检查脚本里出现 `名字 not in 源码文本` 这类恒为假的过滤条件（失败信号）"
  - "pyflakes / ruff / flake8 未安装（No module named），临时自研替代检查"
  - "要拿『未使用 import 检查通过』当收尾结论"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a80b-0eeb-7719-ba82-31f86fbaeaa7
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# 自写的检查脚本必须先喂已知坏样本做阳性对照：恒假判据会把"没检查"伪装成"全绿"

**主张**：自写的检查脚本（静态扫描、未使用符号检查、正则巡检）在用于真实代码之前，**必须先用一个已知坏样本做阳性对照**（例如故意留一个未使用 import，看它是否被报出）。否则当判据写错——尤其是恒假条件——脚本会对所有输入输出"干净"，把"没检查"伪装成"检查通过"。

**证据（会话 01a0a80b，命令与输出原样）**：
- 环境里没有现成 linter：`python3 -m pyflakes ...` → `No module named pyflakes`；退而 `python3 -m flake8 ...` → `No module named flake8`。
- 于是自研 stdlib `ast` 检查，关键一行（原样）：
  `unused = [i for i in sorted(imported) if i not in names and f'"{i}"' not in src and f"'{i}'" not in src and i not in src]`
- 对 5 个文件跑出来的结果全是空表：`spc865/tools/__init__.py -> unused: []`、`spc865/tools/cli.py -> unused: []`、`spc865/tools/batch.py -> unused: []`、`spc865/tools/report.py -> unused: []`、`tests/python/test_cli.py -> unused: []`。
- **该判据恒假**：`imported` 里的每个名字都出现在它自己那行 `import` 语句里，也就必然出现在 `src` 中，`i not in src` 永远为 False → 列表永远为空，这个输出不携带任何信息。
- 会话里模型自己发现并放弃该检查（原文）："my heuristic is weak, since `i not in src` almost always False... the check is useless"；随后退回第二种手段逐个计数：`for n in field is_dataclass ...; do grep -c "\b$n\b" <files>; done`。

**做法**：① 先构造两个合成样本——一个含已知未使用 import（期望报出）、一个全部使用（期望不报），脚本对二者行为正确后才用于真实代码；② 判据不要用"源码文本里是否出现该名字"（import 行本身就含该名字），要基于 ast 收集的 Name/Attribute 引用集合；③ 自研检查定位为候选生成器，输出还要用第二种独立手段交叉确认（`grep -c <name> <file>` 计数 = 1 才可能是死代码）。

**边界 / 反例**：阳性对照只能排除"恒不报"这类假阴性，**不排除假阳性**——`__future__`、字符串注册表、`getattr` 动态引用都会被误报；所以"检查通过"永远不能单独作为删除代码的依据。

**失败信号（未来命中即该想起本条）**：自研检查对所有输入输出同一个"空/干净"结果；或脚本里出现 `X not in src` / `X not in text` 这种"被检对象不可能不在"的条件。
