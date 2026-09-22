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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
依赖仅 clang（本机 Apple clang 17.0.0），与 algommw-plus 仓、/tmp 沙箱无关，可当场重跑。两条命令（我实测过，输出逐字如下）：\n\n# 坏形态（naive 改写：先转函数指针再调用）\nprintf 'typedef float Real_t;\\nstatic Real_t f(Real_t a,Real_t b,Real_t c){return a+b+c;}\\ndouble g(void){return static_cast<double>( f )( (Real_t)1,(Real_t)2,(Real_t)3 );}\\n' > /tmp/cast_bad.cpp && clang++ -std=c++17 -fsyntax-only /tmp/cast_bad.cpp\n# 期望（rc=1）：error: static_cast from 'Real_t (*)(Real_t, Real_t, Real_t)' (aka 'float (*)(float, float, float)') to 'double' is not allowed\n\n# 好形态（调用并入 cast 作用域）\nprintf 'typedef float Real_t;\\nstatic Real_t f(Real_t a,Real_t b,Real_t c){return a+b+c;}\\ndouble g(void){return static_cast<double>( f( (Real_t)1,(Real_t)2,(Real_t)3 ) );}\\n' > /tmp/cast_good.cpp && clang++ -std=c++17 -fsyntax-only /tmp/cast_good.cpp\n# 期望（rc=0）：无输出\n\n（我实际用等效的 castrepro/bad.cpp、castrepro/good.cpp 跑过：bad rc=1 且报错行与切片 L1121/L1128 的诊断同字；good rc=0。）
```

**审核给出的修改意见（要点）**：核心主张成立且可复验，留在注入集；只需修三处：(1) 证据节第 3 条顺序说反了——改成「首次检测脚本（`static_cast<([\w]+)>(\s*)(\w+)\s*\)\s*\(`）报『函数调用并入 0 处』、build 仍 rc=2 errors=23；换用 `static_cast<(\w+)>\( (\w+) \)\('` + 括号配平后报『并入 7 处』，errors 降到 16；再改 PARITY_FIELD 宏后 build 才 rc=0 errors=0」——即把「0 处」定位为第一次失败检测（而非修后复审），并注明 rc=0 不是本步单独达成。(2) 删掉主张末尾「或在非函数场景下静默改变语义」——切片只取证了编译报错，无静默改义的实例。(3) 「为什么」段把「括号同时充当『转换』和『函数调用』」改为：「老式转换 `(T) f(args)` 里被转换的是**整段调用表达式 `f(args)`**；只把标识符 `f` 包进 static_cast 会得到 `static_cast<T>(f)(args)`，语义变成先转函数指针、再对转换结果发起调用。」

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 或在非函数场景下静默改变语义
- （补充：主张把两个不同的括号组说成同一组——原文「老式函数式 cast `(T) f(args)` 里，括号同时充当『转换』和『函数调用』」。切片只记录了错误与修复，未做此机制阐述；且 `(T)` 前缀与 `f(args)` 的调用括号是两组独立括号，此处表述不准。）

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
