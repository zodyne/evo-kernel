---
id: clang-analyze-warning-verify-before-defect
type: lesson
status: candidate
scope: global
domain: verification
tags: [clang, static-analysis, false-positive, c, audit, index]
triggers:
  - "clang --analyze 报 uninitialized value / Undefined or garbage value 警告，准备写进审查结论"
  - "审查 C 代码的索引越界/未初始化读，想系统收集线索而不是只信静态分析"
  - "静态分析命中处的上游有前置条件（守卫/调用前提），警告可能不可达"
  - "用 rg 枚举 `[expr - 1]` 这类下标站点，想与静态分析报告交叉核对（失败信号：只扫 analyzer 报出来的那几处）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a575-5b31-7353-8a3d-42c878dd751c
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [adversarial-review-repro-as-written, verify-external-references]
---

# 主张

`clang --analyze` 的未初始化/垃圾值类警告是**线索不是结论**：每条都要回读命中处的调用前提（守卫、值域条件）做可达性核验，确认能真正触发才写进缺陷清单。本会话对 core/src 全量跑 `clang --analyze` 得到 3 条警告（切片可见 beam.c:923、cfar.c:162 两条），审查者逐条核验后全部证伪，未计入最终结论。

# 做法 / 证据（切片命令 ↔ 结果）

- 批量取线索：`for f in $(find core/src -name '*.c'); do clang --analyze -std=c99 -I core/include …`，日志落 /tmp/an，再 `grep -E "^[a-z/].*: (warning|error):"` 汇总。
  ↳ `core/src/dpu/doa/beam.c:923:5: warning: 2nd function call argument is an uninitialized value [core.CallAndMessage]`
  ↳ `core/src/dpu/cfar/cfar.c:162:5: warning: Undefined or garbage value returned to caller [core.uninitialized…]`
- 交叉枚举补漏（防止只看 analyzer 报的那几处）：`rg -n "\- 1U\]|\+ 1U\]|\[ *ul[A-Za-z]* *- *1" core/src`
  ↳ `core/src/dpu/cfar/cfar.c:162: return pxVals[ ulK - 1U ];`（正是 analyzer 命中处），`core/src/dpu/cfar/cfar.c:667: xDr = x…`
- 定性：本会话末尾结论写 `clang 静态分析(3 条警告逐条证伪)`——3 条警告经核验均不可达/误报，未进入 4 条最终结论。

# 边界 / 反例

- 「逐条证伪」是审查者对源码守卫做的判断（本条 verified_by 标 human）：切片没有留下每条警告各自的排除命令，未来若要以本条为据反驳某条 analyzer 警告，必须重新核验，不能直接引用「本会话已证伪」。
- 反向也不成立：analyzer 没报不等于没有越界——`rg` 枚举出的站点要逐个读上下文（本会话继续 `sed -n '600,700p' core/src/dpu/cfar/cfar.c` 看 667 行附近）。
- 这类未初始化警告常与「某分支只在外部保证下才可达」纠缠，核验对象是**该调用的可达域**，不是函数本身。
