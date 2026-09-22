---
id: falsifiable-probe-for-type-tightening
type: lesson
status: validated
scope: global
domain: cpp
tags: [cpp, units, strong-typedef, compile-time-dimension, falsifiable-probe, acceptance]
triggers:
  - "做完单位标签（Deg_t/Rad_t/Log2_t）或编译期维度（Mat_t<N,M>）的类型收紧，要证明错配真的编不过"
  - "验收只有合法路径的编译/测试通过，没有一条必须失败的负例（失败信号：无法证伪）"
  - "想验证 delete 的 float 重载 / 零隐式转换承诺是否成立，需要可证伪的编译探针"
  - "设计类型收紧类改动的验收清单，不知道该写哪些断言"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4a3-ae96-7475-af70-36ad39adaba4
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [clang-fdump-record-layouts-verifies-struct-layout]
---

**主张**：类型收紧类重构（单位标签、编译期维度、强 typedef）的验收必须包含**可证伪探针**：故意写非法转换/错配维度的片段，断言它**编译失败**（本会话 `error: no viable conversion from 'Rad_t' to 'Deg_t'`）；再配合法路径探针断言编译通过。「编译通过」本身不能证明标签拦住了错配——一个全是隐式转换的空壳类型也能全绿。

**为什么**：类型收紧的价值全在「错配不编译」；这条只能用负例来证。另外，探针要小而独立（单片编译），因为一旦混进主构建，失败会被其他地方的成功掩盖。

**证据（本会话切片，命令 ↔ 结果）**：

- 负例探针：`/tmp/amw-units/probe1.cpp` 编译输出 `===== 可证伪检查 1(必须失败) ===== /tmp/amw-units/probe1.cpp:5:11: error: no viable conversion from 'Rad_t' to 'Deg_t'`；切片同时显示存在第二段 `可证伪检查`（内容被截断）。
- 收紧后主构建的真实拦截也可见：`1 error: invalid operands to binary expression ('Real_t' (aka 'float') and 'const Deg_t')`（全库 74 个错误经归并后的代表），说明标签确实没有提供隐式算术。
- 同批做法还有施工前布局探针（只 printf sizeof/alignof/offsetof、不改代码）与 `sizeof(amw::Chain)=4392272` 探针；本条只主张「负例必须失败」这一条。

**边界 / 反例**：

- 「必须失败」的探针需要与「必须通过」的合法探针成对；只有负例时，编译器参数错误（缺 include、写错 flag）也会「失败」，是假阳性。
- 探针所用的非法操作要选得精确（如 Rad_t→Deg_t 的整值赋值），否则失败原因可能来自别的编译问题。
- 本条不主张所有重构都要负例探针；只对「类型收紧/编译期拦截」这类验收成立。

**失败信号（未来命中即该想起本条）**：类型收紧改动交付时只有「构建 rc=0 / 测试全绿」；或问「怎么证明错配编不过」时拿不出一个必须失败的片段。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含、不依赖 algommw-plus 与已消失沙箱。在 scratchpad 跑：\n\ncat > probe_units.cpp <<'EOF'\nstruct Deg_t { float xV; explicit constexpr Deg_t( float x ) : xV( x ) {} };\nstruct Rad_t { float xV; explicit constexpr Rad_t( float x ) : xV( x ) {} };\nusing Real_t = float;\nint main( void ){\n    Rad_t r( 1.0f ); Deg_t d = r;                 /* 1) 必须失败: Rad_t→Deg_t */\n    Real_t z = 1.0f; const Deg_t e{ 2.0f };\n    Real_t w = z - e;                             /* 2) 必须失败: float-Deg_t */\n    ( void ) d; ( void ) w; return 0;\n}\nEOF\nclang++ -std=c++17 -fsyntax-only probe_units.cpp; echo \"rc=$?\"\n\n实测输出（Apple clang version 17.0.0, arm64-apple-darwin24.6.0，本机 2026-09-22 复跑）：\nprobe_units.cpp:9:11: error: no viable conversion from 'Rad_t' to 'Deg_t'\nprobe_units.cpp:11:18: error: invalid operands to binary expression ('Real_t' (aka 'float') and 'const Deg_t')\n2 errors generated.\nrc=1\n\n即条目引用的两条错误串（`no viable conversion from 'Rad_t' to 'Deg_t'`、`invalid operands to binary expression ('Real_t' (aka 'float') and 'const Deg_t')`）在同构强 typedef 下逐字复现，证明『负例必须编译失败』是真值稳定、可当场证伪的语言/工具链属性。
```

**审核给出的修改意见（要点）**：核心主张成立且真值稳定（clang 强 typedef 行为，本机已逐字复现），保留在注入集，但证据须换：1) 把证据节从 session 绑定的 /tmp/amw-units/ 片段改为 minimalRepro 里的自包含强 typedef 探针（含期望输出），或在保留现引用时同时给出该自包含复现；2) 现有三条引用全部依赖被截断的命令与已消失产物，注明『不可照抄重跑』；3) 把「为什么」两条机制（『空壳类型也能全绿』『单片编译隔离，否则被主构建成功掩盖』）标注为通用推理而非本会话观测——切片 `空壳`/`单片`/`掩盖` 0 hits；4) 把 74 错误的措辞由『经归并后的代表』收敛为『本步主构建 rc=2、74 处 error 中可见此条』。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 「编译通过」本身不能证明标签拦住了错配——一个全是隐式转换的空壳类型也能全绿。（切片无此论证：`空壳`/`全绿` 0 hits；仅 base/units.hpp 提交信息出现 `无隐式转换`）
- 探针要小而独立（单片编译），因为一旦混进主构建，失败会被其他地方的成功掩盖。（切片无支撑：`单片`/`掩盖` 均 0 hits；sesssion 里负例确实在 /tmp 独立编译，但『混进主构建会被成功掩盖』这一机制未在切片中出现）

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
