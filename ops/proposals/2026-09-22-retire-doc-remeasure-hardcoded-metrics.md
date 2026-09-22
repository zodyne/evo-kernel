---
id: retire-doc-remeasure-hardcoded-metrics
type: lesson
status: candidate
scope: global
domain: documentation
tags: [doc-retirement, sizeof, probe, struct-layout, evidence-handover]
triggers:
  - "判定旧方案/旧文档里写死的实测数字（struct 尺寸、指标）是否已被代码承接"
  - "旧文档要删除，但它记录的数字在现行文档里找不到备份（失败信号）"
  - "要核对文档里的 sizeof/尺寸表与当前代码是否仍一致"
  - "退役 PLAN.v1 前要证明它独有的实测数据仍有代码版本可查"
  - "文档中的数字与当前编译产物实测对不上（失败信号）"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b3d9-1442-7475-af70-367c26fa603f
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [clang-fdump-record-layouts-verifies-struct-layout, algommw-plus-type-widths-for-offsetof]
---

# 退役旧方案前，对它独有的硬数字用当前代码编探针复测

**主张**：判定旧文档里的实测数字（本会话是 struct 尺寸表）能否随文档一起退役，用当前头文件编一个 sizeof 探针复测：实测值与旧文档一致，该数字就有代码版本可查，删文档不等于丢事实；对不上则说明文档里还有没落码的信息，不能删。

**证据（本会话命令 ↔ 结果）**：

- 残留项定位 `for p in 4718594 6340608 4437768 ...（全仓，排除 .git）` → 第一项 `./PLAN.v1.md:144: AdcFrame_t 4718594 B（注意 alignof=2，因为 int16）…`。
- 探针 `/tmp/v1rescue/p.cpp`（`#include <cstddef>`、`#include "core/types/radar.h"` 等当前头，printf sizeof）编译运行 → `AdcFrame_t 4718594 align 2 / Cube_t 9437184 / SnapCube_t 6340608 / RdMap_t 196608 / Cloud_t 10244 …`，与 PLAN.v1:144 的数字一致。
- 代码侧佐证：`rg -n "static_assert" --glob '*.h' --glob '*.hpp' core/ tools/` → `tools/parity/decoder.hpp:5` 注释「偏移表来自本仓 core 头的 offsetof；布局已 static_assert 与旧版相同」。
- 复测通过后 `PLAN.v1.md` 被 `git rm`（同会话）。

**为什么**：旧方案里常有一批只有它记录过的实测数字（本会话的 4718594 B 等）。若直接以「v2 更全」为由删除，丢掉的可能正是这些数。用当前代码实测一次，等价于把「文档中的历史测量」转成「代码可复现的当前事实」，这也是判断旧文档独有内容是否已被承接的证据。

**边界/反例**：该探针只覆盖尺寸/布局口径，不证明旧文档其余结论仍成立——本会话没有逐条复测 PLAN.v1 的其他数据。探针必须 include 当前头实测，不能拿文档里的数字回填断言（否则是自证）。验证结构体布局的专门机制见 related（clang record-layouts dump）。
