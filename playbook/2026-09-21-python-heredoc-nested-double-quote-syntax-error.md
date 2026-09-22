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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
python3 - <<'EOF'
print("LINE1-SHOULD-NOT-RUN")
print("   ⇒ 只要两者均值相当（Δ≈0），单帧就是在抛硬币：这就是"抖动"的数学根源。\n")
EOF
# 实测：stdout 无 LINE1；stderr:
#   File "<stdin>", line 2
#     print("   ⇒ 只要两者均值相当（Δ≈0），单帧就是在抛硬币：这就是"抖动"的数学根源。\n")
# SyntaxError: invalid syntax. Is this intended to be part of the string?
# exit=1  → 证实「整段一行都不执行」
# 修复（外单内双）同样实测通过：print('   ⇒ 这就是"抖动"的数学根源。') → 打印 LINE1 与整行，exit=0
# 全角引号修复亦通过：print("   ⇒ 这就是「抖动」的数学根源。\n") → exit=0
# 另证 heredoc 引号只作用于 shell：X=world 下 <<EOF 得 "hello world"，<<'EOF' 得 "hello $X"，Python 侧解析不变。
```

**审核给出的修改意见（要点）**：主张本身正确且真值稳定（Python 词法与 shell heredoc 语义的通用属性），verified_by: command 标得对。需改的是证据节：两条证据引用的都是 wtr10 会话里被切片截断的命令（失败命令截于 `prin`，修复命令截于 `print("解析推导（假设：水面=粗糙`），照抄不能重跑。建议把证据节替换/补充为一条自包含最小复现（见 minimalRepro：嵌套 ASCII 双引号的 heredoc 必报 SyntaxError 且前序 print 不执行；改全角引号或外层单引号后 exit=0），并在正文注明「整段一行都不执行」已由本机 Python 实测复验；「用 \\\" 转义或外层单引号包裹」与「f-string/字典字面量同理」属切片外的通用知识，可保留但宜标注为通用规律而非本次观测。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 整个 heredoc 脚本一行都不执行（切片只给 SyntaxError 行，未显示前序 print 缺失；本机复现已独立证实为真）
- 同类问题也会出现在 `print(f"...")`、字典字面量等任何 Python 字符串里
- 用 `\"` 转义或外层单引号包裹

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
