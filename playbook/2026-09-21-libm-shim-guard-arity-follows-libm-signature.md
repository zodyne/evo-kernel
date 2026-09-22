---
id: libm-shim-guard-arity-follows-libm-signature
type: lesson
status: validated
scope: global
domain: cpp
tags: [cpp, libm, d10, shim, arity, overload, delete, adversarial-review]
triggers:
  - "复核『libm 遮蔽 shim / D10 头形状非法（ill-formed）』类发现，要在 confirm/refuted 之间定级"
  - "给 atan2/pow/fmod/hypot 这类二元 libm 函数写同名 wrapper 探针，在定义处硬报错（失败信号：报错出在探针自己写的一元形状上）"
  - "看到 `inline double dSin(double); double dSin(float) = delete;` 这类声明型守卫，要判断它和 wrapper 定义是不是同一种形状"
  - "审计/复现 D10 的 20 个函数遮蔽形状，需要逐条按真实 arity 写声明"
  - "发现方说某 libm 形状编不过，但卡片/PLAN 原文里搜不到那个 arity 的写法（失败信号：拿改写形状指控原文）"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-edbe-7475-af70-36c4f1906a8d
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [synthetic-sandbox-mechanism-is-not-target-repo-risk, adversarial-review-repro-as-written, falsifiable-probe-for-type-tightening, using-declaration-conflicts-with-shim-in-namespace]
---

# libm 遮蔽守卫的形状按真实 arity 写声明，不是同名 wrapper 定义

## 主张

判「libm 遮蔽（D10 类）形状非法」之前，先把探针形状和卡片原文的形状在两个维度上对齐：**arity**（atan2/pow/fmod/hypot 是二元函数）与**声明 vs 定义**（卡片的编译期守卫是「按真实 arity 的声明 + delete 一个错误实参类型的重载」，没有函数体）。给二元 libm 函数写字面一元 wrapper 定义会在定义处硬报错，但那是探针自己的形状错误，不能归因给卡片；换成 arity 正确的整张声明头（20 个函数）并带一次调用，编译 rc=0。

## 为什么

二元函数的真实调用形态是两参（本会话 core 里 `atan2(dPx, dPy)`），按一元写出来的同名 wrapper 与它根本不是同一种形状；而声明型守卫不产生 wrapper 定义，走不到那条硬错误路径。用一个自己改写、少一个参数的形状去复现错误，得到的失败只能证明「改写形状编不过」，不能证明「卡片的形状编不过」。

## 证据（切片命令 ↔ 结果）

- 卡片原文形状：`rg -n "inline double|inline l…"`（P1.0b 卡）↳ M12 行 68 给出探针 `inline double dSin(double); double dSin(float) = delete;`，`dSin( xFloat )` → error（声明型守卫）。
- 真实调用 arity：`rg -n "\b(atan2|pow|fmod|hypot)\s*\(" core --glob '*.cpp' --glob '*.hpp'` ↳ `core/src/dpu/track/unit.cpp:54: pxMeas->xAzimuth = ( Real_t ) atan2( dPx, dPy );`（两参调用）。
- minprobe 变体（`/tmp/review-refute-d10-wrapper-shape-illformed-for-binary-libm/minprobe/` 下写了 `libm_min.hpp` / `use_libm.cpp` / `include_only.cpp` / `libm_fixed.hpp` / `use_fixed.cpp` / `libm_full.hpp` / `use_full.cpp`）：`D) full 20-function header, arity-correct, with call` → `rc=0`；紧接着 `E) confirm float arg still hits the delete guard`（切片在 E 的结果处截断）。
- 末条 assistant：`Reproduced the narrow technical fact: literal one-arg wrappers for atan2/pow/fmod/hypot are hard errors at the definition site`；裁决 `Verdict: not real (misreading) — isReal = false`。
- 佐证归因错位：发现方归到卡片上的短语 `20 个 inline` 在 card/PLAN 里零命中（`rg rc=1 (1=none)`）。

## 边界 / 反例

- 本条只主张「形状要按真实 arity / 声明 vs 定义核对」，不主张 D10 设计本身无风险。
- 一元 libm 函数（sin/cos/exp 这类）的守卫形状确实是一元；arity 对齐是对每个函数逐条做的，不是全表统一。
- 若卡片原文真的写了错 arity 的形状，则发现成立，不适用本条。
- verified_by=command 依据切片中的 clang++ 探针 rc 与末条 assistant 复述的硬错误结论；切片未给出完整错误文本，正文不引用具体错误串；E 的最终结果在切片中被截断，未据此下断言。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
实测（Apple clang 17.0.0, arm64-apple-darwin24.6.0，全部 rc 已复核）：

# 1) 卡片 §5-D10 的真实形态（PLAN.md:262 逐字，arity 正确、带体、放在 namespace amw）→ rc=0
printf '#include <cmath>\nnamespace amw{\ninline double atan2(double y,double x){return std::atan2(y,x);}\nfloat atan2(float,float)=delete;\ndouble f(double a,double b){return atan2(a,b);}\n}\n' > /tmp/card_shape.cpp
clang++ -std=c++17 -fsyntax-only /tmp/card_shape.cpp; echo "rc=$?"   # rc=0

# 2) 发现方实际写的形状（一元 wrapper，体内 std::atan2 只给 1 参）→ 定义处硬报错
printf '#include <cmath>\nnamespace amw{\ninline double atan2(double d){return std::atan2(d);}\nfloat atan2(float,float)=delete;\n}\n' > /tmp/finding_shape.cpp
clang++ -std=c++17 -fsyntax-only /tmp/finding_shape.cpp; echo "rc=$?"  # rc=1: error: no matching function for call to 'atan2'  （指 body 里的 std::atan2( d )）

# 3) 关键对照：一元「定义」本身合法——错误来自体内一元调用，不是一元定义
printf '#include <cmath>\ninline double atan2(double x){return x;}\ndouble f(double a,double b){return atan2(a,b);}\n' > /tmp/one_arg_def.cpp
clang++ -std=c++17 -fsyntax-only /tmp/one_arg_def.cpp; echo "rc=$?"    # rc=0

# 4) 原沙箱仍在，重跑：D=use_full.cpp rc=0；E=use_float_guard.cpp rc=1 'call to atan2 is ambiguous'
D=/tmp/review-refute-d10-wrapper-shape-illformed-for-binary-libm/minprobe
clang++ -std=c++17 -fsyntax-only $D/use_full.cpp;  echo "D rc=$?"   # rc=0
clang++ -std=c++17 -fsyntax-only $D/use_libm.cpp;  echo "finding rc=$?"  # rc=1
clang++ -std=c++17 -fsyntax-only $D/use_float_guard.cpp; echo "E rc=$?"  # rc=1

注：D10 的 `float f(float)=delete` 只有在 namespace amw 内才合法；放全局作用域会与 <math.h>/<cmath> 的 float 重载冲突（error: declaration conflicts with target of using declaration）。所以最小复现必须带上 namespace amw。
```

**审核给出的修改意见（要点）**：保留（可注入），但必须改三处，否则会误导未来会话：  1) 改【主张】与标题的核心刻画（这是最严重的错）：现文写「卡片的编译期守卫是『按真实 arity 的声明 + delete 一个错误实参类型的重载』，没有函数体」「不是同名 wrapper 定义」。这与卡片实际相反——PLAN.md:251-270（§5-D10，本发现审计的对象）写的正是**带函数体的同名 wrapper 定义**：`inline double atan2( double y, double x ) { return std::atan2( y, x ); }   float atan2( float, float ) = delete;`（我实测 rc=0）。『声明型、无函数体』是 M12（另一里程碑的 dSin 探针，PLAN.md:68）。应改为单一维度：**arity 必须与真实 libm 签名一致（wrapper 的两参、体内 std::atan2(y,x) 的两参、delete 重载的两参）**，因为 D10 的载体就是同名遮蔽 wrapper 定义。删除「声明 vs 定义」这一维度，或明确它只属于 M12、与本发现无关。  2) 改【主张】中「写字面一元 wrapper 定义会在定义处硬报错」的因果：错的是**函数体内的一元调用** `std::atan2( d )`，不是一元定义本身（一元定义

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 卡片的编译期守卫是「按真实 arity 的声明 + delete 一个错误实参类型的重载」，没有函数体
- （标题/主张）libm 遮蔽守卫的形状按真实 arity 写声明，不是同名 wrapper 定义
- 给二元 libm 函数写字面一元 wrapper 定义会在定义处硬报错
- 换成 arity 正确的整张声明头（20 个函数）并带一次调用，编译 rc=0

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
