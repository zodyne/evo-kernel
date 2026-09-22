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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
rm -rf /tmp/tk && mkdir -p /tmp/tk && cd /tmp/tk
printf '\\documentclass{article}\n\\usepackage{tikz}\\usetikzlibrary{arrows.meta}\n\\tikzset{dash/.style={-{Stealth[length=2mm]}, semithick, dashed}}\n\\begin{document}\\begin{tikzpicture}\\draw[dash](0,0)--(1,1);\\end{tikzpicture}\\end{document}\n' > d.tex
pdflatex -interaction=nonstopmode d.tex >/dev/null 2>&1; echo "d.tex exit=$?"; grep -m1 '^!' d.log
#   实测：d.tex exit=1
#         ! Package pgfkeys Error: The key '/tikz/dash' requires a value.   （报在 l.4 \draw[dash]，即使用处）
#   旁证：把定义整条删掉只留 \draw[dash] 也报同一错 —— 证明 /tikz/dash 是 TikZ 既有 key，非「使用处漏传值」
sed -e 's/{dash\//{aux\//' -e 's/\[dash\]/[aux]/' d.tex > a.tex   # 定义与使用处一并 dash->aux（避开 dashed 子串）
pdflatex -interaction=nonstopmode a.tex >/dev/null 2>&1; echo "a.tex exit=$?"; grep -m1 '^!' a.log || echo "(no error)"
#   实测：a.tex exit=0  / (no error)   —— 改名后报错消失
```

**审核给出的修改意见（要点）**：核心主张（命名为 dash 撞内置 key → 报 requires a value → 改名即消失）经本机最小复现逐字证实，真值稳定（TikZ/pgfkeys 语义），保留在注入集，但需两处收窄：(1) 边界/反例第 1 条改为只列 `dash` / `dash pattern`（取值类内置 key），删掉 `dashed`——实测 `dashed` 作自定义 style 名不报此错（自定义 .style 静默覆盖），仅样式体自引用时才 `TeX capacity exceeded` 递归超限，失败模式不同；并把「其他宏包（如 pgfplots 的 addplot）同理」降为指向 related 条目的待验引述，勿当已证。(2) 证据节把两条被截断、不可照抄重跑的命令（`s.replace('  dash/.style={-{S…`、`xelatex …adaptive_thres…`）替换为 minimalRepro 里的自包含最小复现（可逐字重跑、含期望输出）。主张措辞、证据三处引用的行号/报错文本/最终 `错误: 0` 小结均与切片对齐，无需改动。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 「`dash` / `dashed` / `dash pattern` 是 TikZ key 名高发区」——把 `dashed` 并入同一失败族：切片里根本没有 `dashed`，且本机实测不成立（`\tikzset{dashed/.style={blue, very thick}}` + `\draw[dashed]` → exit 0、正常出 PDF，自定义 .style 静默覆盖、不报 requires-a-value；只有样式体自引用 `dashed` 时才 `! TeX capacity exceeded` 递归超限，失败模式与 `requires a value` 不同）。只有 `dash` / `dash pattern` 才复现该错。
- 「其他宏包（如 pgfplots 的 `addplot`）同理」——切片无任何 pgfplots 观测（仅指向 related 条目），属未验证的跨包推广。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
