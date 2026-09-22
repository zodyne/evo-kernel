---
id: python-heredoc-nested-double-quote-syntax-error
type: lesson
status: validated
scope: global
domain: shell
tags: [heredoc, python, syntax-error, 引号]
triggers:
  - "用 python3 - <<'EOF' 跑命令行长脚本，报 SyntaxError 且指向某一行（失败信号）"
  - "heredoc 里的 Python 字符串要引用中文词，内层直接嵌了 ASCII 双引号"
  - "同一段命令行脚本里多处 print 中文，个别行解析失败、整段一行都没执行"
  - "把报错行贴进 .py 文件看不出问题，因为要看的是引号配对"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bdef-64b5-738d-af4a-290ada962882
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [bash-nested-heredoc-parse-error-whole-line-dead]
---

# heredoc 里的 Python 字符串再嵌 ASCII 双引号会整段解析失败

## 主张

用 `python3 - <<'EOF'` 跑命令行 Python 时，若某个双引号字符串内部又嵌了 ASCII 双引号（如 `print("…这就是"抖动"的数学根源…")`），Python 词法解析在该行断开，整个 heredoc 脚本一行都不执行；heredoc 用 `<<'EOF'` 引起来只影响 shell，不会改变 Python 的引号解析。中文引用改用全角引号或外层换单引号即可避开。

## 证据（session 01a0bdef，wtr10）

- 失败命令：`python3 - <<'EOF'`（含 numpy/scipy 推导的 heredoc），输出 `✗ File "<stdin>", line 19` 并回显源行 `print("   ⇒ 只要两者均值相当（Δ≈0），单帧就是在抛硬币：这就是"抖动"的数学根源。\n")`。
- 修复后重跑同一段推导（不再内嵌 ASCII 双引号）正常输出：`解析推导（假设：水面=粗糙面复高斯散斑 => 功率指数…`。

## 边界 / 反例

- 同类问题也会出现在 `print(f"...")`、字典字面量等任何 Python 字符串里；与 shell 层的 heredoc 嵌套无关（那是另一条：bash 嵌套 heredoc 解析失败）。
- 若字符串里确实要保留 ASCII 双引号，用 `\"` 转义或外层单引号包裹；报错行号指向 `<stdin>`，不是磁盘上的 .py 文件。
