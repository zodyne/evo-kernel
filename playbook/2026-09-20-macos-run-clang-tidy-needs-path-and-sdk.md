---
id: macos-run-clang-tidy-needs-path-and-sdk
type: fact
status: validated
scope: global
domain: build-system
tags: [macos, clang-tidy, run-clang-tidy, sdk, xcrun, homebrew-llvm]
triggers:
  - "在 macOS 上对 CMake 项目跑 run-clang-tidy -p build，报 failed to find clang-tidy in $PATH or at build/bin/clang-tidy"
  - "run-clang-tidy 能启动但每个 TU 报 error: 'type_traits' file not found [clang-diagnostic-error]"
  - "想用 clang-tidy 批量修老式转换/风格问题，tidy rc 非 0，分不清是代码问题还是工具链没配全"
  - "要在本机复现 CI 或上一轮会话里的 clang-tidy 结果"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4a3-ae96-7475-af70-36ad39adaba4
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [clangd-subproject-missing-compile-commands-failed-to-find]
---

**主张**：macOS 上跑 `run-clang-tidy`（Homebrew LLVM 版）需要两件前置同时就位：① `PATH` 里有 LLVM 的 bin 目录（本机为 `/opt/homebrew/opt/llvm/bin`）；② `export SDK=$(xcrun --show-sdk-path)`。缺 ① 报 `failed to find clang-tidy in $PATH`；缺 ② 每个 TU 报 `'type_traits' file not found [clang-diagnostic-error]`，rc 非 0，看起来像代码错误。

**为什么**：`run-clang-tidy` 脚本本身要能找到 `clang-tidy` 可执行文件；而 clang-tidy 解析 C++ 标准库头时需要 Xcode SDK 的 libc++ 头路径，CMake 的 compile_commands.json 里通常没有 `-isysroot`，要靠环境变量补。

**证据（本会话切片，命令 ↔ 结果）**：

- 直接跑（PATH 未含 LLVM）：`tidy rc=1  error: failed to find clang-tidy in $PATH or at build/bin/clang-tidy`。
- 加 `export PATH="/opt/homebrew/opt/llvm/bin:$PATH"` 后：`tidy rc=1  Found compiler error(s).  Applying fixes ...`，错误样本 `core/include/math/matrix.hpp:4:10: error: 'type_traits' file not found [clang-diagnostic-error]`（另 `core/src/chain/chain.cpp` 同因）。
- 再加 `SDK=$(xcrun --show-sdk-path)`（值 `SDK=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk`）后：`tidy rc=0 errors=0 ... 50 files changed`，后续干净树复跑同样 `tidy rc=0 errors=0`。

**边界 / 反例**：

- LLVM bin 路径依安装方式而变（Intel Homebrew 是 `/usr/local/opt/llvm/bin`，也可用 `brew --prefix llvm`）；本条不主张该路径是唯一的。
- 若项目自带 `-isysroot` 或使用 Apple clang 自带的 clang-tidy（如有），缺 SDK 导出可能不报错；本会话用的是 Homebrew LLVM。
- `'type_traits' file not found` 也可能是 compile_commands.json 本身生成了坏参数，需先排除这种可能再归因到 SDK。

**失败信号（未来命中即该想起本条）**：`tidy rc=1` 且日志里同时出现上面两条错误之一；此时先补 PATH/SDK，别把 rc 非 0 当成「代码里有很多问题」。
