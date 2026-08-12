---
id: gitignore-blocks-handwritten-makefile
type: lesson
status: candidate
scope: global
domain: git-hygiene
tags: [gitignore, makefile, staticlib, c-porting]
triggers:
  - "手写的 Makefile 加不进 git"
  - "git add 提示被 ignore"
  - ".gitignore 的 Makefile 规则误伤"
  - "静态库要保留但 Makefile 被挡"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:fecf8853
last_verified: 2026-07-31
superseded_by: null
schema_version: 1
---

**主张**：.gitignore 里为构建生成物写的宽泛规则（如裸 `Makefile`、`*.a`）会误伤同名源码文件——嵌入式/C 项目里手写的模块 Makefile 会被「CMake 生成物」规则一起挡住。解法：给规则加注释说明意图，并用否定规则显式放行源码路径（如 `!src/signalProcess/false_alarm_filter/Makefile`、`!src/tracker/lib/*.a`）。

**为什么**：移植 false_alarm_filter 到 libucm221 时，模块自带手写 Makefile 编译静态库，顶层 `Makefile` 规则将其静默排除出版本库——静默丢失构建入口比编译错误更难发现。

**边界**：写完 ignore 规则后用 `git check-ignore -v <path>` 验证关键源码路径不被误伤；否定规则要具体到路径，避免重新放开生成物。

**证据**：2026-07-31 libucm221 会话 .gitignore diff，规则注释+否定放行落地。
