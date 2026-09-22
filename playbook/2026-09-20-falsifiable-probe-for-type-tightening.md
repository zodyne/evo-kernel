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
