---
id: qt-ui-readonly-recon-anchored-grep
type: playbook
status: candidate
scope: global
domain: code-recon
tags: [recon, read-only, grep, pyside6, ui-architecture]
triggers:
  - "只读侦察陌生 PySide6/Qt UI 代码库，要产出供镜像重写的结构地图"
  - "想先拿到 class/def/Signal 声明骨架与行号，再决定精读哪几个文件"
  - "recon 报告需要『哪个视图/面板/参数定义在哪个文件哪一行』的定位锚点"
  - "失败信号：报告里的结构描述没有行号、只能靠通读源码或凭印象画架构"
  - "为保持被审仓库只读，不想在里面写探针脚本，只靠 shell 命令取材"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7de-9984-7719-ba82-31eaed505fb4
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [2026-07-27-zsh-unquoted-glob-arg-no-matches, survey-large-notebook-repo-via-registry-index, pyside-probe-script-needs-qapplication]
---

**主张**：对陌生 PySide6/Qt UI 代码库做只读侦察时，按文件跑锚定 grep（`^class ` / `^def ` / `^    def ` / `Signal(`，参数模块再补 `^_大写常量`）就能在一条命令里拿到「声明名 + 行号」的骨架；把各文件骨架拼起来即结构地图的骨架层，全程不写文件（`ls`/`find`/`grep -n`/`wc` 足够），不必为了解架构去通读实现或往被审仓库里写探针脚本。

**为什么**：recon 报告要交付的是「谁定义在哪一行」的导航信息，不是实现正文（样式字符串、布局细节对地图没有增量）。`grep -n` 天然带行号，锚定前缀把大文件输出压到声明级、一次调用覆盖一个文件或一类符号；行号同时是后续精读和写报告引用时的定位锚点。Qt UI 里 `class`/`def` 给结构、`Signal(` 给事件契约，二者合起来就是可移植的架构骨架。

**怎么做**：
1. 先 `ls -la` + `find <目标目录> -type f -name "*.py" | sort` + `wc -l`（多段输出用 `echo "---段名---"` 分隔）拿文件清单与体量。
2. 对每个 UI 文件跑 `grep -n '^class \|^def \|^    def \|Signal(' <file>`；参数/配置模块改用 `grep -n '^_SPEC\|^_WINDOWS\|…' <file>` 扫模块级常量。
3. 需要跨文件同屏对比时，在一条命令里 `echo "=== views.py ===" && grep ... && echo "=== widgets.py ===" && grep ...`。
4. 把带行号的声明清单整理成结构地图；接线细节（connect 目标、动态属性）再按行号定点 `read` 补。

**反例 / 边界**：
- 骨架只含**显式声明**：`connect()` 目标、装饰器/`setattr`/`getattr` 动态注册、运行时装配的 widget 树都不在输出里——地图的接线层必须定点精读补齐。
- 模式里的 `|`、`*` 必须用单引号包住（如 `'^class \|^def '`、`-name '*.py'`），否则 zsh 会先展开（见 `2026-07-27-zsh-unquoted-glob-arg-no-matches`）。
- 需要验证 Qt 运行时 API 存在性时，锚定 grep 无能为力，那才轮到探针脚本，且探针须先建 `QApplication`（见 `pyside-probe-script-needs-qapplication`）。
- 本会话只证明该法足以产出结构地图骨架，未证明地图完整覆盖了所有运行时接线。

**证据（slice 命令 ↔ 结果）**：5 条命令全部只读（`ls`/`find`/`grep -n`/`wc -l`），其中 3 条是锚定 grep——`grep -n '^class \|^def \|^    def \|^    [a-zA-Z_]* = QtCore.Signal\|Signal(' ui/workbench.py` 返回 `82:def _c … 86:def _stylesheet … 149:def _config_qss …`；同样锚点扫 `ui/views.py` + widgets 返回 `40:def track_color … 45:def _gather_history …`；`grep -n '^_SPEC\|^_WINDOWS\|^_DOA\|…'` 扫 `ui/params.py` 返回 `48:_WINDOWS = _choices(WINDOW_NAMES) … 52:_AVG = …`。「写/改文件」段为空（只读约束全程保持），末条 assistant 交付的正是 `UI Reconnaissance Report … Read-only structural map`。
