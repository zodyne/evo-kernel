---
id: make-d-macro-change-skips-rebuild-silently
type: lesson
status: deprecated
scope: global
domain: build-system
tags: [make, makefile, compile-flags, dependency-graph, validation]
triggers:
  - "用 make 变量（make N_GRID=31 / make FOO=bar）切换一个编译期 -D 宏配置后跑验证"
  - "C 侧与参照侧数值对不上，却以为是算法/数值 bug"
  - "改了 make 变量但产物行为没变、且无任何报错（失败信号）"
  - "跨配置数值比对时，某一档的结果始终和另一档一模一样（说明根本没换档）"
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:fb616292-c015-42e4-9987-16229ad221f3
last_verified: 2026-07-28
superseded_by: skill:embedded-cross-compilation
schema_version: 1
---
# -D 宏配置用 make 变量切换不会触发重编——编译标志不在依赖图里，make 静默跳过

**主张**：当一个配置（如 `N_GRID`）是编译期 `-DfafN_GRID=31` 宏常量时，靠 `make libfaf N_GRID=31` 改变它的值**不会触发重新编译**：编译标志不在目标的依赖图里，make 判定 `Nothing to be done` 并静默退出。结果你拿旧二进制跑验证，C 侧数值与参照侧对不上，却去查算法 bug。

**根因**：make 的依赖图只追踪"文件"（源码、头、目标），不追踪"编译时命令行参数"。改 `-D` 宏不影响任何依赖文件的 mtime，make 认为无需重做。

**修法**：让编译标志进入依赖图——生成一个内容/名字编码配置的哨兵文件（如 `build/.ngrid-$(N_GRID)`），每次构建 `rm -f build/.ngrid-* && touch build/.ngrid-$(N_GRID)`，并让目标依赖该文件。这样切换 N_GRID 时哨兵文件名变化、依赖失效，才真正重编。

**反例/边界**：若配置完全由运行时参数传入（非编译期），则与此坑无关；专指 `-D` 宏 / 编译期常量。

**证据**（session fb616292）：
- 复现：`make libfaf N_GRID=31` → `make: Nothing to be done for 'libfaf'.`（静默跳过，仍用 n_grid=51 旧库）。
- 修复后：`make libfaf N_GRID=31` → `rm -f build/.ngrid-*  touch build/.ngrid-31  cc ... -DfafN_GRID=31 -fPIC -shared ...`（真正重编）。
- 捕获：`inbox/capture-2026-07-27-23-26-22-015-ljdc.md`。
