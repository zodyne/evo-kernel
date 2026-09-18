---
id: static-audit-regex-must-pin-function-signature
type: lesson
status: candidate
scope: global
domain: c-style
tags: [c, naming, regex, audit, ripgrep, prv-prefix]
triggers:
  - "审计 C 模块静态函数命名（静态函数是否带 prv 前缀）"
  - "用 rg '^static ' 加排除词筛静态函数"
  - "审计输出里混进 static 变量/常量，被当成命名违规（失败信号）"
  - "正则漏写函数签名的左括号，命中 static eWindowType eWindow = …（失败信号）"
  - "要一次性列出所有不符合前缀约定的静态函数"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a5f0-9954-7353-8a3d-42d3da5cbafa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [bare-c-locals-regex-audit]
---

**主张**：用正则审计"静态函数是否带 `prv` 前缀"时，模式必须**锚定函数签名**（行首 `static` + 返回类型 + 标识符 + `(`）；只用 `^static ` 再排除 `prv` 会把**静态变量/常量**一起捞进来——它们按约定用类型/const 前缀（`eWindow`、`xWindow`、`cPInit`），不带 `prv`，于是形成成片误报或把真违规淹在噪声里。

**为什么**：`static` 修饰两类实体，"prv 前缀"约定只约束函数；以 `static` 为唯一锚点时变量声明与函数定义无法区分。误报的典型形态是把 `static eWindowType eWindow = eWindowHann;` 这类合法静态变量写进命名违规清单。

**做法**：把函数签名写进正则，例如
`rg -n '^static [^(]*\b[a-zA-Z_][a-zA-Z0-9_]*\s*\(' core/src | rg -v '\bprv'`
确有必要用宽口径（只 `^static `）时，先跑窄口径出结论，再用宽口径输出交叉人工确认哪些是变量。

**证据（session:01a0a5f0…，algommw 审查）**：
- 窄口径（带 `(`）：`rg -n '^static [^(]*\b[a-zA-Z_][a-zA-Z0-9_]*\s*\(' core/src | rg -v '\bprv'` → 无输出，即静态函数全部带 `prv` 前缀，零误报。
- 宽口径（只 `^static `）：`rg -n '^static ' core/src | rg -v '\bprv[A-Z]' | head -20` → `core/src/dpu/range/range.c:21:static eWindowType eWindow = eWindowHann;`、`core/src/dpu/range/range.c:24:static Real_t xWi…` —— 命中的是静态变量/常量，不是函数。

**边界**：若项目约定静态变量也带某个固定前缀，本条改判——判据以项目自己的命名文档为准（本会话在 `docs/naming.md` 与 FreeRTOS 风格规范下确认静态变量走类型前缀）。窄口径正则假定返回类型与函数名之间不跨行；返回类型含 `*` 或函数指针的签名需相应放宽，否则会漏报（漏报方向与误报方向相反，收紧前先各跑一遍对照）。
