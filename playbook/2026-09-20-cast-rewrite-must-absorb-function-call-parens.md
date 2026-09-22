---
id: cast-rewrite-must-absorb-function-call-parens
type: lesson
status: validated
scope: global
domain: refactoring
tags: [cpp, static-cast, old-style-cast, bulk-rewrite, function-pointer]
triggers:
  - "用脚本/正则把旧式转换 (T) 批量改成 static_cast，改写对象是函数调用 (T) f(args)"
  - "批量改 cast 后编译报 static_cast from 'T (*)(...)'（失败信号：把函数指针当值转换了）"
  - "审查别人提交的 old-style-cast → static_cast 全树替换，想知道还该盯什么形态"
  - "写括号配平/词法级的转换改写器，要决定 static_cast<...> 的作用域到哪结束"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4a3-ae96-7475-af70-36ad39adaba4
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [mass-cast-rewrite-macro-holes-need-handfix, cast-auto-rewrite-pollutes-comments-audit-diff]
---

**主张**：批量把 `(T) f(args)` 改成 `static_cast` 时，**调用括号必须并入 cast 的作用域**，写成 `static_cast<T>( f( args ) )`。只把被转换的标识符包起来会得到 `static_cast<T>( f )( args )`——先转换函数指针、再对转换结果发起调用，编译直接报 `static_cast from 'T (*)(...)'`，或在非函数场景下静默改变语义。

**为什么**：老式函数式 cast `(T) f(args)` 里，括号同时充当「转换」和「函数调用」；正则/词法改写器若只按 token 找标识符，会吃掉 `(` 的调用含义。这类改写器需要识别「标识符后紧跟 `(`」并做括号配平，才能把整段调用表达式并入 cast。

**证据（本会话切片，命令 ↔ 结果）**：

- 改动后构建报错：`tests/unit/test_postproc.cpp:222:23: error: static_cast from 'Real_t (*)(Real_t, Real_t, Real_t)' (aka 'float (*)(float, float, float)') ...`。
- 出错形态可见：`fabs( static_cast<double>( xPeakParabolicOffset )( static_cast<Real_t>( 5.0 ), ...` —— 函数指针被转换后才调用。
- 修复记录：脚本 `并入 7 处`（把函数调用并进 static_cast），后续审计为 `并入 0 处`；构建 `rc=0 errors=0`。

**边界 / 反例**：

- 只针对「被转换对象是函数调用」这一形态；普通 `(T) expr`、`(T)(expr)` 不受影响。
- 反过来，若函数名是宏或成员指针调用（`(T) pxObj->*pmf(args)`）形态更复杂，切片未取证，需单独处理。

**失败信号（未来命中即该想起本条）**：批量 cast 改写后出现 `static_cast from '<函数指针类型>'` 的编译错误；或 diff 里出现 `static_cast<...>( name )( ... )` 这种「cast 后紧跟调用」的形态。
