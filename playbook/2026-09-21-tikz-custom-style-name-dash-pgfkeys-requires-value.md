---
id: tikz-custom-style-name-dash-pgfkeys-requires-value
type: lesson
status: validated
scope: global
domain: latex
tags: [xelatex, tikz, pgfkeys, style, build-error]
triggers:
  - "xelatex 编译报 Package pgfkeys Error: The key '/tikz/<name>' requires a value（失败信号）"
  - "自定义 TikZ style 名撞上内置 key 名（dash / dashed / dash pattern 一族）"
  - "改了 .tex 后编译中断，但日志指向的 key 在文档里明明有 .style 定义"
  - "给 TikZ 图新增/重命名自定义样式，起名用了短单词"
  - "重构 TikZ 样式后构建失败，不确定是不是命名冲突"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bcf1-4733-7265-ada1-fb36116f6be1
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [pgfplots-3d-addplot3-not-addplot]
---

# 自定义 TikZ 样式命名为 dash：pgfkeys 报 requires a value，改名即消失

## 主张

在 XeLaTeX/TikZ 文档里把自定义样式命名为 `dash`（与 TikZ key 域已有 key 同名）时，编译报 `! Package pgfkeys Error: The key '/tikz/dash' requires a value.`；把样式名改成不撞内置名字的 `aux`（样式体原样保留 `-{Stealth[length=2mm]}, semithick, dashed`）后该错误从日志消失，最终构建到 `错误: 0`。

## 为什么

pgfkeys 的 key 名是路径化的全局命名空间（`/tikz/...`）；自定义 style 与同路径的内置 key 撞名时，使用处会按内置 key 的签名解析（要求传值），而不是按新写的 `.style` 展开——报错看起来像"使用处漏传值"，实际是命名冲突。改名是本次验证过的零风险修法；自定义样式应起不与 TikZ/pgfplots key 冲突的名字（加项目前缀）。切片只展示"报错 → 改名 → 错误消失"的可复现链条，未展开 pgfkeys 内部解析细节，本条不据此断言更深的机制。

## 证据（session 01a0bcf1，suc221-pointcloud-2.0）

- 报错：`docs/build_docs.sh adaptive_threshold_design` 失败；`grep -n "^!" adaptive_threshold_design.log` → `1394:! Package pgfkeys Error: The key '/tikz/dash' requires a value.`
- 修复：对 `docs/adaptive_threshold_design.tex` 执行 `s.replace('  dash/.style={-{S…`（dash → aux）；改后文件里是 `182:  aux/.style={-{Stealth[length=2mm]}, semithick, dashed}`。
- 验证：随后两次 grep 日志只余 `! Missing $ inserted.` 与 `! Extra }, or forgotten \endgroup.`（另一批生成表格的问题），pgfkeys 错误不再出现；最终 `/Library/TeX/texbin/xelatex -interaction=nonstopmode -halt-on-error …` 输出 `未定义引用: 0 | 缺字符: 0 | 错误: 0 | Overfull: 3 | 页数: ['14']`。

## 边界 / 反例

- `dash` / `dashed` / `dash pattern` 是 TikZ key 名高发区；其他宏包（如 pgfplots 的 `addplot`）同理，同族不同坑见 `pgfplots-3d-addplot3-not-addplot`。
- 同为 `pgfkeys ... requires a value` 时，先确认 .tex 里是不是真的定义了同名 `.style`（rg 该名字）；若只是使用处真的漏传值，改名不对症。
- 切片未展示 pgfkeys 报错对应的 .tex 使用现场与 .log 完整上下文，主张按"观测 + 修法 + 复验"收口，不推广为对所有 pgfkeys 冲突的解释。

## 失败信号（未来命中即该想起本条）

- xelatex 日志出现 `Package pgfkeys Error: The key '/tikz/<name>' requires a value`，而 `.tex` 能找到 `<name>/.style={...}`。
- TikZ 样式重命名/新增后构建中断，报错里的 key 名正是刚起的短名。
