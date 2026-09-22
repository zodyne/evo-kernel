---
id: libm-shadow-guard-impact-needs-ast-overload-resolution
type: lesson
status: candidate
scope: global
domain: cpp
tags: [clang, ast-dump, overload-resolution, libm, verification, read-only]
triggers:
  - "复核 D10 类 libm 遮蔽守卫（namespace 内同名 + 删除 float 重载）会上报哪些 call to deleted function 的调用点"
  - "准备用 rg 数 libm 函数名出现次数来给守卫的影响面/爆炸半径出数"
  - "只读仓库里没法真编译带守卫的变体，却要枚举受影响的调用点集合"
  - "文本扫出的 libm 调用点数量与编译错误/报告里的处数对不上（失败信号：把差异当遗漏或当命中）"
  - "rg 命中里出现注释/宏里的 sin/cos，被当成真实调用计入影响面"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-6062-7475-af70-36b57a4c1bf9
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [libm-symbol-chosen-by-arg-type-not-call-syntax, libm-call-audit-via-artifact-symbols, line-regex-cannot-decide-token-in-comment-or-string, clang-analyze-warning-verify-before-defect]
---

# 枚举 libm 遮蔽守卫的受影响调用点必须按编译器选中的重载（AST qualType），不能按源码里的函数名计数

**主张**：「namespace 内同名遮蔽 + 删除 float 重载」这类 libm 守卫（D10 类）会打破哪些调用点，由**编译器的重载解析结果**决定：只有实际选中的重载形如 `float(float)` / `long(float)` 等返回 float 参数版的调用点才会变成 `call to deleted function`。因此影响面要用 `clang -ast-dump=json` 逐调用点读被选重载的 `qualType` 来枚举，不能用源码里 `rg` 数 `sin/cos/...` 出现次数——文本计数与真实受影响集合双向不一致（注释里的函数名会被算进来），而 `sinf(` 这类显式 float 写法只是同一机制的一个写法，不能当全集判据。

**为什么**：守卫的语义是重载解析的语义。调用点是否被兜住，取决于实参类型、可见的命名空间和转换序列，这些都不是词法属性；相反，源码里写 `sin(float)` 还是 `sin(double)` 文本上看起来一样，而写 `fabsf(` 与写 `fabs(` 在重载解析上也可能落到同一个被删版本。文本扫描只能回答「名字出现在哪」，回答不了「选中的是哪个重载」。

**证据（本会话切片，命令 ↔ 结果）**：

- 在只读仓库的 `/tmp` 副本上逐 TU 跑 `clang -ast-dump=json`（`-I core/include -I core/src/dpu/track -std=c++17` 等与构建一致的 flags），由 `scan2.py` 汇总每个 TU 的调用与选中签名：
  `## core/src/chain/chain.cpp -> 0 calls ## core/src/chain/route.cpp -> 0 calls ## core/src/dpu/cfar/cfar.cpp -> 2 calls …`
- 抽出「被选重载是 float 参数版」的集合（切片标题即 `=== AST-selected float overloads (the D10-blocked set) ===`）：
  `core/src/dpu/doa/beam.cpp	274	37	lround	long (float) noexcept …`（每行 = 文件、行、列、函数名、被选签名）。
- 反向控制（防止「写了 float 实参但选中非 float 版本」被漏掉）：
  `=== all calls where written arg is float-ish but selected fntype is NOT float === (none) …`
- 文本扫描与 AST 集合的差异逐条归因：文本侧 `rg -n '\b(sin|cos|…|hypot)\s' core` 有命中，AST 对比脚本报
  `text sites (non comment-only lines) not matched by AST scan: ('core/src/dpu/doa/beam.cpp', 742, 'cos') textcount= 1 …`；
  回读该行 `=== core/src/dpu/doa/beam.cpp:742 === dWx = 2.0*(double)lSCol/(double)DOA_ANGLE_BINS; /* 方位空间频率 = sin(az…`
  —— 命中落在 `/* … */` 注释里，是文本扫描的假阳性，不是漏掉的调用点。
- 排除其它同名来源（保证 AST 与文本差异不是宏/条件编译造成的）：`=== macros defining libm names === (none) === using namespace std in core === (none) …`、`=== .c files in core === (end) === #if 0 blocks === (none) …`、`=== std:: anywhere in core === (none) …`。
- 结论锚（末条 assistant 原文，切片截断）：用 AST「读被选重载的 `qualType`」逐调用点核对后，D10 会报 `call to deleted function` 的集合**恰好就是报告那 11 处**（beam 274/275/711、music 1…）。

**边界 / 反例**：

- AST 结论绑定于生成它时用的 flags/include 路径；要与真实构建一致（本例复用了 `-std=c++17`、项目 include 路径），并逐 TU 扫编译单元——调用点都在 `.cpp` 里，只扫头文件会得到 `0 calls`。
- 选错实现是另一层问题：本条只判「哪些调用点会撞上守卫」，不判撞上后数值路径对不对。产物侧的真值层是 `nm -u`（见 related 两条），AST 是**构建前/只读条件下**的预测层。
- 文本差异不总是假阳性：差异集合里每一条都要回读源码行（注释、宏、`#if 0`、字符串）才能归类；本例逐条归因后差异来自注释，且 `.c / #if 0 / 宏` 均已排除。
- 单个 TU 的 AST JSON 实测 26,391,806 字节（切片 `26391806 t.json`），要落盘成文件再解析，不要指望内联一段 python 一次说完。

**失败信号（未来命中即该想起本条）**：给守卫影响面出数时手上只有 `rg -c 'sin|cos|…'` 之类的名字计数；文本处数与编译错误/报告处数对不上却不逐条归因；把 `sinf(` 的出现与否当成「float 重载有没有被调用」的判据。
