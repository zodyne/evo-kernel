---
id: pyflakes-absent-ast-unused-code-check
type: lesson
status: candidate
scope: global
domain: static-analysis
tags: [python, ast, pyflakes, ruff, dead-code, unused-imports, offline]
triggers:
  - "`python3 -m pyflakes` 报 No module named pyflakes（ruff 也没有），但要查未使用 import / 死代码"
  - "用 stdlib ast 自研未使用符号检查，输出里出现可疑名字（如 `annotations`）"
  - "怀疑某个模块级私有函数只定义未调用，想确认（`grep -c <name> <file>` 计数 = 1）"
  - "没有 lint 工具链的离线/受限环境里给 Python 代码做静态自检"
  - "自研静态检查报了候选，要不要直接照单删代码"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a810-9275-7719-ba82-31fb903a37e1
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [bare-venv-test-with-stdlib-unittest]
---
# 没装 pyflakes/ruff 时：stdlib ast 列候选 + `grep -c` 交叉确认

## 主张
环境里 pyflakes/ruff 都没有时，别跳过未使用代码检查：用 stdlib `ast` 遍历源码，输出
①"可能未使用"的 import 名字（名字 → 位置）与 ②"模块级私有函数未被引用"集合；对每个候选再用
`grep -c "<name>" <file>` 做**交叉确认**——计数 = 1 表示该符号只出现在定义处，才可判定为死代码。
自研检查是候选生成器，不是判决器；假阳性必须人工过滤。

## 为什么
仓库只需要一个文件的标准库就能跑这类检查，不必为"装 linter"先联网/改环境。但自研 AST 检查基于静态名字匹配，
对 `__future__`、动态引用（`getattr`、字符串注册表）一律看不见，所以必须用第二种独立手段（文本计数）复核，
形成"AST 提名 → grep 计数确认"的双人复核，避免照单误删。

## 证据（本会话命令 ↔ 结果）
- 先试真 linter，确认不可用：
  `grep -c "_hollow_pen" spc865/ui/views.py; python3 -m pyflakes spc865/ui/views.py tests/python/test_ui_views.py` →
  `1` / `/opt/homebrew/opt/python@3.14/bin/python3.14: No module named pyflakes no ruff`
- 自研 AST 脚本（`python3 - <<'PY' … import ast …`）输出：
  `spc865/ui/views.py 可能未使用: {'annotations': 29} tests/python/test_ui_views.py 可能未使用: {'annotations': 16}
  模块级私有函数未被引用: {'_h…`（切片在 `{'_h` 处截断）
- `grep -c "_hollow_pen"` = `1`：该私有名只在定义处出现一次；两个独立来源（AST 提名 + 文本计数）相互印证，
  据此确认死代码候选。

## 边界 / 反例
- **假阳性已知**：两个文件都被报出 `annotations`（29 / 16）。切片没有给出该名字的判定依据，不要照单删，
  需人工复核（`__future__`/注解相关名字是常见噪声源）。
- AST 看不到动态引用：测试通过 `DATA_VIEWS` 之类的注册表间接使用、或 `getattr`/字符串引用时，
  "未被引用"≠可以删；删除前跑一遍该模块的测试与裸 import 校验。
- 能装上真 linter（flake8 / ruff / pyflakes）时优先用真 linter；本条只覆盖装不上/离线时的兜底路径。
- 切片对 AST 脚本正文与输出都有截断（`{'_h…`），完整实现需回原始会话核对。

## 失败信号（未来命中即该想起本条）
- `python3 -m pyflakes` / `ruff` 报 No module named，准备放弃未使用检查。
- 自研 AST 检查输出里出现 `annotations` 这类名字——提醒这是假阳性、需人工过一遍。
- 某个模块级私有函数 `grep -c` 计数 = 1（只有定义没有调用），却还没被处理。
