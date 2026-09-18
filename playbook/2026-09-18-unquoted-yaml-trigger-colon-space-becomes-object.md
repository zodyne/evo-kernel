---
id: unquoted-yaml-trigger-colon-space-becomes-object
type: lesson
status: validated
scope: project:evo-kernel
domain: tooling
tags: [evo-kernel, yaml, js-yaml, triggers, catalog, dedup, silent-failure]
triggers:
  - "`evo catalog` 的 triggers 列里出现字面 `[object Object]`（失败信号）"
  - "给条目写 frontmatter triggers 列表项，文本含『冒号+空格』却没有加引号"
  - "查重时 grep 某个关键词，明明有条目写过却零命中（失败信号：该词只存在于被解析成对象的 trigger 里）"
  - "某条目 triggers 看起来齐全，recall 却从不命中它"
  - "蒸馏器落笔前拿 catalog 做查重基准，要自查基准有没有静默盲区"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b37f-3278-73b1-bdd8-c2e52b31a9ae
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pi-subagents-frontmatter-colon-strict-yaml, js-yaml-silently-parses-iso-date-to-object, frontmatter-edit-must-use-setfmfield]
---

# 未加引号的 triggers 项含「冒号+空格」会被 js-yaml 解析成对象：catalog 显示 `[object Object]`，该触发词静默失明

**主张**：evo 条目 frontmatter 的 `triggers:` 列表项如果**不加引号**且文本内含「冒号+空格」（`: `），js-yaml 会按 YAML 语法把它解析成**映射对象**而不是字符串。`evo catalog` 用 `triggers.join(' | ')` 输出该行时，这一项变成字面 `[object Object]`：该 trigger 里的关键词（如 `createPlatformOpenGLContext`）在 catalog 里 grep 不到，蒸馏器做查重时看不见这条已入库的经验；recall 的 triggers 通道对非字符串项走 `String()`（`bin/evo:420-423`），同样只剩 `"object"` 这个通用 token，真实关键词不参与匹配。

**为什么**：YAML plain scalar 里的 `: ` 是映射分隔符，列表项 `- foo: bar` 本来就是一个 map。evo 的 frontmatter 走 js-yaml 宽松解析且坏字段容错，不报错；`evo audit` 的 LOW 档只检查 triggers 是不是**非空数组**，不检查元素类型（`bin/evo:1206`）。于是错误完全静默，唯一可见痕迹就是 catalog 里的 `[object Object]`。

**证据**（session 01a0b37f 与 2026-09-18 复跑，命令 ↔ 结果）：
- 会话拿到 catalog 后 `head -3 /tmp/evo-triage/catalog.tsv`，第 3 行即 `2026-07-27-qt-offscreen-opengl-context-warnings-nonfatal	playbook	在无显示器机器/CI 上跑 PyQt/PySide/pyqtgraph 应用… | [object Object] | pyqtgraph.opengl 在 headless 环境…`；同一次 catalog 的 `2026-07-27-zsh-unquoted-glob-arg-no-matches` 行里也有一个 `[object Object]` 项。
- 溯源：`playbook/2026-07-27-qt-offscreen-opengl-context-warnings-nonfatal.md:10` 的 triggers 项未加引号，原文含 `"QOpenGLWidget: Failed to create context"`；`playbook/2026-07-27-zsh-unquoted-glob-arg-no-matches.md` 的对应项含 `"no matches found: <那个参数>"`。js-yaml 解析探针：这两项 `typeof === 'object'`（其余项均为 string）。
- 查重失明的实证：`rg -i 'createPlatformOpenGLContext' /tmp/cat-r3.tsv` → 0 命中，而该串就写在上述 trigger 原文里；`rg '那个参数' /tmp/cat-r3.tsv` → 0 命中。2026-09-18 复跑时全库 catalog 里以整项形态出现 `[object Object]` 的行共 2 行（qt 与 zsh 两条）。
- 自查/修法：写 triggers 时整项加引号（含 `: ` 的项必须加）；机器自查别只 grep `object Object`——它会命中本条这种『讨论该现象』的条目（本条入库后全库该类命中数就从 2 变 3），要断言类型：用 js-yaml 解析全部条目 frontmatter，要求 `triggers.every(x => typeof x === 'string')`，或检查 catalog 里 `[object Object]` 是否作为**整项**出现（前后是 ` | ` 或制表符边界）。

**反例 / 边界**：
- 空 triggers 数组有 audit 的 LOW 档兜底（"无 triggers → 该条目 recall 永不命中"），但"数组非空、元素是对象"没有任何告警——本条覆盖的正是这个盲区。
- 与 `pi-subagents-frontmatter-colon-strict-yaml` 同源（冒号+空格），但那边是严格解析器直接报错、整文件跳过（硬失败）；evo 的 js-yaml 是宽松解析成对象、静默失明，失败形态与排查手段都不同。
- 本条只涉及列表项的 plain scalar 写法；引号包裹或块标量不受影响。文件名/正文里出现 `: ` 不受影响，只有 frontmatter 的 YAML 解析面会被改写。
