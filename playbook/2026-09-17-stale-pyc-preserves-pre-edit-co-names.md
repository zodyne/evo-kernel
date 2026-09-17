---
id: stale-pyc-preserves-pre-edit-co-names
type: lesson
status: validated
scope: global
domain: python
tags: [python, pyc, marshal, dis, bytecode, design-review, debug]
triggers:
  - "评审/调试时发现源码被编辑过，拿不准改动前的实现是什么样"
  - "需要还原被改动前的函数/常量/符号，但没 git 历史或备份"
  - "怀疑 __pycache__ 里的 .pyc 还留着编辑前的字节码（失败信号：源码与 .pyc 内容不一致）"
  - "设计走查发现文档结论与当前代码对不上，想确认差异是改前还是改后引入的"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a439-0f30-763d-a251-9f16df59b5d4
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
---

# 源码被编辑后，过期 __pycache__/*.pyc 保留编辑前的 co_names，可作还原改动前实现的线索

## 主张

评审/调试中发现源码被编辑过、拿不准改动前实现时，`__pycache__/*.pyc` 里可能还留着编译时的字节码——用 `marshal` + `dis` 能读出 header（magic + 时间戳）和 `co_names`，据此判断 .pyc 是否早于源文件，并把编译时的符号表当改动前的对照线索。

## 为什么

`.pyc` 是源文件在某个时刻被 import/编译的产物，源文件后续改动不会同步更新 .pyc（除非重新编译）。所以当源码被改过、又没 git 历史可查时，过期 .pyc 是少数能「看见改动前编译状态」的旁证：header 里的时间戳可判编译时刻，`co_names` 列出编译时引用到的顶层符号（函数名/导入名/常量），比纯读当前源码更能还原改动前的结构。

## 反例 / 边界

- .pyc 只在源文件上次编译时存在；若源码编译后从未改动，.pyc 与源一致，没有「改动前」信息可用。
- 依赖 `__pycache__` 未被清理、且 .pyc 的 magic 版本与当前 Python 匹配（`simulate.cpython-314.pyc` 只能被 3.14 读）。
- 本会话证据只到「读出 header + co_names」；「完整反解改动前字节码/常量值」未在会话内跑完，属待验证的下一步，不能当已验证事实引用。

## 证据

切片命令↔结果（session 2026-09-15 对抗式评审 2T8R BPM 仿真，发现源码被编辑过）：

- 命令 `python3 -B -c "import marshal, dis; b=open('__pycache__/simulate.cpython-314.pyc','rb').read(); ..."` 成功输出 `header 2b0e0d0a000000004cfda86af8180000` 与 `co_names: ('__doc__', '__future__', 'annotations', 'typing', 'Optional', 'numpy', ...)`，证明 .pyc 可经 marshal/dis 读出 header 时间戳与编译时符号表。
- 末条 assistant 结论：「The `__pycache__` .pyc files predate the edited sources — that may let me recover the pre-change bytecode.」——即 .pyc 早于被编辑的源文件，可作为恢复改动前字节码的线索（该恢复动作尚未在会话内验证完成）。
