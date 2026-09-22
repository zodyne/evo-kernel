---
id: cmake-keep-going-collect-all-compile-errors
type: lesson
status: validated
scope: global
domain: build-system
tags: [cmake, keep-going, compile-errors, impact-surface, error-histogram]
triggers:
  - "批量改写后要评估全树编译影响面，却只拿到第一个失败目标的前几条报错（失败信号）"
  - "修复循环里每次构建只暴露少量 TU 的错误，想一次看全"
  - "要按错误种类统计（`unknown type name` / `undeclared identifier` 各多少）而不是逐条读日志"
  - "需要判断一次机械改造的爆炸半径，构建日志却在中途停止"
  - "把 `cmake --build` 接在脚本里做影响面采样，不知道要不要让它在失败后继续"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-60a5-7475-af70-36b72f8c98e6
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [clang-ferror-limit-caps-bulk-error-counts, bulk-edit-verification-must-build-all-targets]
---

# 要一次拿到全树编译错误面：`cmake --build ... -- -k` + 日志直方图

## 主张

要评估一次批量改写的影响面，给 `cmake --build` 传 `-- -k`（把 keep-going 透传给底层构建器）并重定向日志，让构建在失败目标之后继续跑完其余 TU，再把日志按错误种类聚合（`grep/awk | sort | uniq -c`），一次得到跨目标的错误分布；不带 `-k` 的默认构建会在第一个失败目标停住，错误面被低估。

## 为什么

影响面是「哪些 TU、多少处、什么种类」的集合，而默认构建的语义是「失败即停」：它给出的报错子集看起来完整（rc=0/rc=2 明确），但没有覆盖面信息。keep-going 把「继续收集」与「退出码」解耦，配合重定向就能在一次运行里攒齐全量日志；直方图则把几百条报错压成可核对的种类计数，用于判断根因（例如本次是「首条 include 被替换导致公共类型找不到」）。

## 证据（切片命令 ↔ 结果）

- keep-going 构建 + 日志 + 直方图：
  `(cmake --build build2 -j8 -- -k 2>&1 || true) > /tmp/review-scan-core/build2_keepgoing.log` →
  `done === error summary === 57 error: unknown type name 'Real_t' 16 error: use of undeclared identifier 'Real_t' 15 …`
  —— 一次运行拿到 57/16/15… 的跨 TU 错误分布。
- 对照（不带 `-k`）：同会话早先 `cmake --build build -j1 > build_core_j1.log 2>&1` → `rc=2`，日志里只有首批错误（`2 error: redefinition of 'tan'`、`2 error: redefinition of 'sin'`、`2 error: redefinition of 'cos'` …），种类数远少于 keep-going 日志。

## 边界 / 反例

- `-k` 只解除构建驱动（make 等）在首个失败目标上的停止；**不解除 clang 单 TU 的 `-ferror-limit`**（默认 20），所以直方图仍是每 TU 截断后的下限，要可信总数得另配 `-ferror-limit=0` 或逐 TU 编译（见 related）。
- 切片没有回显所用 generator 与完整 flags；不同 generator 透传 `-k` 的写法/语义可能不同，复用时先在本地确认参数被接受（本会话的 `-- -k` 确实生效）。
- 直方图只覆盖编译层错误；链接失败、测试失败是另外的面，不能拿这份分布当「全树验证通过」的证据。

## 失败信号（未来命中即该想起本条）

批量改写后的影响面报告只引用了第一个失败目标的前几条报错；或修复循环连续多轮都只暴露一两个 TU 的错误——先问「构建有没有 keep-going / 有没有跑全目标」。
