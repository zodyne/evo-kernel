---
id: using-directive-vs-shim-namespace-ambiguity
type: lesson
status: validated
scope: global
domain: cpp
tags: [cpp, using-directive, namespace, libm-shim, ambiguity, design-card-preflight]
triggers:
  - "设计卡要求在消费者 TU（tests/*.cpp 等）include 之后加 using namespace <核心命名空间>;，准备照做"
  - "核心命名空间里有遮蔽 libm 的同名子命名空间 / delete 的 float 重载，未限定 sin/fabs 调用会二义（失败信号）"
  - "加 using namespace 后编译报 call to 'fabs' is ambiguous，但去掉就编过"
  - "要评估一次全库注入 using 指令的爆炸半径，而不是先改一个文件试试"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4a3-ae96-7475-af70-36ad39adaba4
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [using-declaration-conflicts-with-shim-in-namespace, cpp-namespace-wrap-must-follow-last-include]
---

**主张**：在消费者 TU（典型是 `tests/*.cpp`）的 include 之后注入 `using namespace <核心命名空间>;` 之前，必须**逐个 TU 编译预检**。若核心命名空间内有同名 libm 遮蔽（`sin/cos/fabs` 的 float 重载被 `delete`），原本能编的未限定数学调用会变成二义；本会话该动作影响 20/24 个测试 TU、136 处二义错误（复核更正为 176 处），成为设计卡阻塞项、卡被改成 r2。

**为什么**：using 指令把核心命名空间的成员拉进候选集，与全局 `::sin(double)` 等形成重载竞争；遮蔽层用 `delete` 显式封死 float 版本时，实参是 float 的调用没有唯一最佳匹配，直接报二义。逐个 TU 预检 + 最小复现才能量化爆炸半径；只改一个文件看不出面。

**证据（本会话切片，命令 ↔ 结果）**：

- 预检结论原文：`## 阻塞 B: 卡片动作 7 'tests/*.cpp include 之后加 using namespace amw;' ...`；扫描汇总 `合计: 20/24 个测试 TU 受影响, 136 处二义错误`，REPORT 同口径 `受影响面 20/24 TU、136 处`。
- 最小复现（`/tmp/review-e2check/e2.cpp`）：`e2.cpp:11:31: error: call to 'fabs' is ambiguous`。
- 复核更正：`## 2026-09-19 多 agent 复核更正: 测试二义计数 136 → 176`（同批二义，计数口径修正）。
- 结果：预检作为阻塞上报后，设计者改卡：`cdcc360 docs: 卡 P1.0b r2 —— 吸收 pi 预检的 2 个阻塞 + 7 条卡面缺陷`。
- 遮蔽层的存在与形态由同批探针直接佐证：`== probe_float == probe_float.cpp:8:5: error: call to deleted function 'sin'`（`libm_probe.hpp` 里把 float 版 `sin` 显式 delete），以及 wrap 探针里 `beam.cpp:274:37: error: call to deleted function 'sin'`。

**边界 / 反例**：

- 具体数字（20/24、136/176）是本仓当次树 + 当时遮蔽实现的快照，换库/换版本会变；可迁移的是「凡注入 using 指令前先逐 TU 编译预检」。
- 若 TU 内所有数学调用本来就写了 `std::` 或经显式 using 声明，二义不会出现；本条的失败面只覆盖未限定调用。
- 「怎么修」（逐处加限定 / 删 using / 调整遮蔽层）是设计决策，切片里由设计者拍板，本条不预设。

**失败信号（未来命中即该想起本条）**：某个 TU 加了 `using namespace X;` 后 `call to '...' is ambiguous`；或卡片声称「只是加一行 using」却在多个 TU 触发不同错误。
