---
id: sed-delimiter-collision-use-python-pathlib
type: lesson
status: deprecated
scope: global
domain: shell
tags: [sed, python, text-replace, tooling]
triggers:
  - "用 sed -i 's|...|...|' 做定点文本替换"
  - "sed 报 bad flag in substitute command（失败信号）"
  - "替换内容本身含 | 、 & 、 / 等 sed 特殊字符（JS/正则/路径文本）"
  - "脚本里要改文件某一行，sed 一行流和 python 二选一"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-29
superseded_by: skill:python-launch-patterns
schema_version: 1
---

# 替换文本含 sed 分隔符直接报 bad flag：含代码/正则的机械替换用 python pathlib，不用 sed 一行流

## 主张

`sed -i.bak 's|OLD|NEW|'` 在 OLD/NEW 文本里出现分隔符（如 JS 代码中的 `|`）时，不预警直接 `bad flag in substitute command` 失败。对含代码、正则、路径等不可控字符的机械替换，用 `python3 -c "pathlib.Path(f).write_text(s.replace(old,new))"`——replace 是纯字符串语义，没有转义陷阱。

## 为什么

改 `/tmp/replay.js` 里一行 JS（含 `lost.slice(0,14).forEach(...)` 与 `||` 等字符）时，选 `|` 当分隔符仍撞上内容里的 `|`：

```
sed: 1: "s|lost.slice(0,14).forE ...": bad flag in substitute command: '|'
```

换成 python3 pathlib 的 `s.replace(old, new)` 一次成功。sed 的替换语法把分隔符、`&`、反斜杠都当元字符，而 python replace 无任何元字符语义。

## 反例/边界

- 替换内容是干净标识符、固定短语（无 `|/&\` 等字符）时 sed 完全可用，不必一刀切。
- 需要正则匹配（捕获组、字符类）的场景仍该用 sed/perl——本条只针对"已知确切旧串的机械替换"。
- python replace 默认替换全部出现；只改一处时先 `s.count(old)` 断言数量，避免误改它处同名文本。

## 证据

- 命令：`sed -i.bak 's|lost.slice...'` 报 bad flag 退出 1；随后 `python3 -c "import re,pathlib; p=pathlib.Path('/tmp/replay.js'); s=p.read_text(); s=s.replace(...)"` 成功，修改后脚本正常输出。
