---
id: clang-record-layout-dump-needs-instantiated-record
type: lesson
status: candidate
scope: global
domain: c-abi
tags: [clang, struct-layout, fsyntax-only, silent-empty, abi]
triggers:
  - "clang -Xclang -fdump-record-layouts 跑完什么都不打印，怀疑结构体没布局或命令写错（失败信号：零输出）"
  - "只想核对头文件里某个结构体的 sizeof/对齐，TU 里没有实例化它"
  - "dump 输出里只有 __NSConstantString_tag 之类的内置记录，找不到目标 struct（失败信号）"
  - "用 -fsyntax-only 跑 record layout dump，结果与项目里能出结果的那条命令不一致"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-52aa-73b1-bdd8-c2d3487bea9e
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [clang-fdump-record-layouts-verifies-struct-layout]
---
**主张**：`clang -Xclang -fdump-record-layouts`（不带 `-complete`）只打印**在 codegen 中真正被实例化/使用**的记录；TU 里只定义、从未使用的 struct 会得到**零输出**，不能据此判断「布局没问题/无布局」。要 dump 某结构体，必须在同一 TU 里真的用到它并至少编译到 `-c`（`-o /dev/null` 即可）；只想核对头文件里的定义而不想构造使用点时，改用 `-Xclang -fdump-record-layouts-complete`（它列出全部已定义记录），但它的输出**以编译器内置记录开头**，容易看漏目标 struct。

**为什么**：plain flag 挂在 AST 消费/codegen 路径上，未被实例化的记录根本不产生 layout 输出；`-complete` 才遍历所有已完成的记录。把前者在 `-fsyntax-only` 下的空输出当作「结构体没有被 dump = 无布局」，会直接漏掉要核对的对象。

**证据**（会话 01a0b2ce 切片，命令↔结果）：
- 只定义未使用 + `-fsyntax-only` + plain flag → 段头 `=== V16 fdump-record-layouts ===` 之后**没有任何输出**（紧接下一段 `=== V24 … ===`）；
- 同一结构体加一行 `struct s v;` 且用 `-c -o /dev/null` 编译 → `*** Dumping AST Record Layout … 0 | struct s … [sizeof=4, align=2]`（本机 Apple clang 17.0.0）；
- `-fsyntax-only -Xclang -fdump-record-layouts-complete` 在只定义的 TU 上，最先打出的是内置记录 `struct __NSConstantString_tag [sizeof=32, align=8]`。
- 注：切片里 `-complete` 那条被 `head -8` 截断，未看到目标 struct；同一环境下去掉截断复跑，`struct s` 的布局块排在 `__NSConstantString_tag` 之后。

**边界/反例**：
- 「使用」是必要条件之一：只加 `-c` 而记录仍未使用，同样零输出；`-complete` 不需要使用点。
- 该 flag 是 clang 前端专用（`-Xclang` 透传）；换 gcc 需另找等价开关。
- dump 只给布局（sizeof/align/偏移），不校验语义与字节序；字节级一致性仍要逐位 golden 对拍（见 related 条目）。
