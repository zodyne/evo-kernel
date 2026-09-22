---
id: byte-frozen-cpp-adapt-via-its-header
type: lesson
status: validated
scope: global
domain: c-porting
tags: [byte-identical, freeze-constraint, header-adaptation, namespace, hash-object, adversarial]
triggers:
  - "复核『某文件字节冻结』与『计划要做的命名空间/符号变换』冲突、被列为阻塞项"
  - "要在不改动某个 .cpp 的前提下让它适配新命名空间/新类型定义"
  - "被冻结文件必须参加编译或闸门，但直接改它会违反零改动约束（失败信号）"
  - "需要机械证明某文件在实验前后字节未变（git hash-object 前后相同）"
  - "把 using namespace / 适配声明放进配套 .hpp，替代改 .cpp"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b753-55b9-7475-af70-36cbee149f9f
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [byte-freeze-exempts-include-path-lines, cpp-namespace-wrap-must-follow-last-include, readonly-verify-tmp-variant-git-status-proof]
---

# 主张

「某 .cpp 一个字节都不能改」与「要把它的依赖符号移进 namespace」**不构成冲突**：把适配（如 `using namespace <ns>;`）放进该 .cpp 配套的 .hpp，.cpp 保持字节不变也能继续编译，并让后续 parity 闸门跑出 `status mismatches: 0`。因此「字节冻结」不构成该变换的阻塞——前提是用机械证据证明 cpp 未变（`git hash-object` 前后相同）且变换后行为过闸。

# 为什么

冻结约束约束的是**文件内容**，不是构建结果。符号查找发生在编译期：只要该 .cpp 的编译单元里这些名字仍可见（通过它包含的头），变换就不需要落在这个文件上。`using namespace` 放在头里会把名字带进所有包含它的 TU——本例冻结文件属于工具目标，代价可接受；换成被广泛包含的公共头要另行评估。

# 证据（切片命令 ↔ 结果）

- `git hash-object tools/parity/frame_source.cpp` → `49d5e8874bb4960f2c1c4930c1`；/tmp 副本内确认完整 blob `49d5e8874bb4960f2c1c4930c16da4159f6b41d0`（同一文件）。
- 在 /tmp 副本里包装 core 头（`headers=32 sources=25 wrapped`）后，**只** `patched frame_source.hpp`，补 `using namespace amw;`。
- `echo "=== syntax-only frame_source.cpp (cpp UNTOUCHED, using only in hpp) ==="` → `rc=0 === frame_source.cpp still byte-identical t…`（不改 cpp、通过语法编译、字节不变）。
- 闸门：`=== frame_source.cpp hash before gate === 49d5e8874bb4960f2c1c4930c16da4159f6b41d0 === run full G3 gate (8 items) on tra…`；parity 跑出 `g4 check triple (frames by usFrameIdx, points, tracks) = (24, 4644, 0)`、`status mismatches: 0`。
- 复核裁决（末条 assistant）：`isReal = false`——「frame_source.cpp 不可动 vs 动作 7」的冲突不成立。

# 边界 / 反例

- `using namespace` 会污染该 .hpp 的**所有**包含者；只在头的作用域局限（或确认仅被该冻结 TU 包含）时用。本切片未展开 `frame_source.hpp` 的全部 includer，落地前先查。
- 「只改头」不保证其它文件不动：同一变换仍让 `tools/parity/driver.hpp:27`、`decoder.cpp:43` 等出现命名空间相关编译错误，需同步修那些**未被冻结**的实现文件；冻结豁免只覆盖被冻结的那一个。
- `rc=0` 只是语法证据，不是行为证据；行为证据是 parity 的 `status mismatches: 0`。两者不能互相替代。
- 与 `byte-freeze-exempts-include-path-lines` 是两种解法：那条主张在任务约束里明文豁免 include 路径行，本条主张不动被冻结文件、把适配下移到头文件。

# 失败信号（未来命中即该想起本条）

- 把「X 文件字节冻结」直接当成某变换的阻塞项上报，却没有先试等价路径（改配套头/包装层）。
- 声称某文件未改动，却拿不出 `git hash-object` / 状态对照一类的机械证据。
