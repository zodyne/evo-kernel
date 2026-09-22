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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
本机复跑（2026-09-22，Homebrew LLVM 22.1.8，SDK=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk）：

  B=$(mktemp -d); cd $B; mkdir build
  printf '#include <type_traits>\nint main(){ return 0; }\n' > t.cpp
  printf '[{"directory":"%s","command":"/usr/bin/c++ -std=c++17 -O3 -c %s/t.cpp -o /dev/null","file":"%s/t.cpp"}]' "$B" "$B" "$B" > build/compile_commands.json

  # 1) PATH 无 LLVM（用绝对路径调 run-clang-tidy）
  env -u SDKROOT /opt/homebrew/opt/llvm/bin/run-clang-tidy -p build -checks='-*,google-readability-casting'
  # 实测输出：error: failed to find clang-tidy in $PATH or at build/bin/clang-tidy   rc=1

  # 2) PATH 加 LLVM bin，无 sysroot
  env -u SDKROOT PATH="/opt/homebrew/opt/llvm/bin:$PATH" run-clang-tidy -p build -checks='-*,google-readability-casting'
  # 实测输出：t.cpp:1:10: error: 'type_traits' file not found [clang-diagnostic-error] / Found compiler error(s).   rc=1

  # 3) PATH 加 LLVM bin + 条目原处方 export SDK=...（env 前缀等价）
  env -u SDKROOT PATH="/opt/homebrew/opt/llvm/bin:$PATH" SDK="$(xcrun --show-sdk-path)" run-clang-tidy -p build -checks='-*,google-readability-casting'
  # 实测输出：与原处方相反 —— 仍是 error: 'type_traits' file not found / Found compiler error(s).   rc=1（SDK 这个变量名 clang-tidy 压根不读）

  # 4) 换成 SDKROOT
  env -u SDKROOT PATH="/opt/homebrew/opt/llvm/bin:$PATH" SDKROOT="$(xcrun --show-sdk-path)" run-clang-tidy -p build -checks='-*,google-readability-casting'
  # 实测输出：Running clang-tidy in 8 threads for 1 files ... 无任何 error   rc=0

同一结论对单文件 clang-tidy 也成立：`export SDK=...` 下仍 `'type_traits' file not found` rc=1；`SDKROOT=...`（或 `-extra-arg=-isysroot -extra-arg=$(xcrun --show-sdk-path)`）才 rc=0。附带反证（排除「默认就能找到头」）：纯 `clang++ -std=c++17 -c t.cpp` 无任何 sysroot 提示即可编译通过，所以那行报错只出现在 clang-tidy/run-clang-tidy 这条路径上。
```

**审核给出的修改意见（要点）**：三处要改，都是变量名/证据换血，不动骨架：  1) 主张里的前置 ②：把「② `export SDK=$(xcrun --show-sdk-path)`」改成「② 给出 SDK sysroot —— `export SDKROOT=$(xcrun --show-sdk-path)`（或 `-extra-arg=-isysroot -extra-arg=$(xcrun --show-sdk-path)`）」。`export SDK=...` 这个名字对 clang-tidy / run-clang-tidy 完全无效（本机实测：设了它每条 TU 照样 `'type_traits' file not found`、rc=1；换 SDKROOT 才 rc=0）。照现文照抄，人会照着一个无效处方试，然后把 rc=1 归因成「代码有问题」——正是本条想防止的误判，反而由本条制造。  2) 「为什么」末句「要靠环境变量补」点名为 SDKROOT，别只说「环境变量」（这正是错的地方：通用机制对，变量名错）。  3) 证据节第 3 条：删掉「加 SDK= 后 rc=0」这个因果读法，换成上面 minimalRepro 的四步（含第 3 步仍 rc=1 的反例）。理由是切片里那两条 rc=0 命令尾部均被截断（`... && run-clang-tidy -p buil`），无法证明 `$SDK` 

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- ② `export SDK=$(xcrun --show-sdk-path)`

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
