---
id: c-test-undef-ndebug-before-assert-include
type: lesson
status: validated
scope: global
domain: c-testing
tags: [c, assert, ndebug, release, testing, cmake]
triggers:
  - "C 测试套件在 Release/-DNDEBUG 构建下断言全静默通过，怀疑 assert 被剥离"
  - "给 C/C++ 项目写单测，构建带了 -DNDEBUG 或 -O3，assert 不触发"
  - "test/ 里 assert 明明该失败却没 abort，怀疑 NDEBUG 在编译期禁用"
  - "审查/移植 C 测试，不确定 #undef NDEBUG 与 #include <assert.h> 的顺序是否影响断言生效"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5af2-7353-8a3d-42c70123dcc4
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
---
一句话主张：C 测试文件要保留断言判别力，必须把 `#undef NDEBUG` 写在 `#include <assert.h>` **之前**——顺序错了或漏了，`-DNDEBUG` 的 Release/`-O3` 构建会把 `assert()` 静默编译成 no-op，测试全绿却什么都没验到。

为什么：`<assert.h>` 里 `assert` 的展开在 include 时就定了：若此刻已定义 `NDEBUG`，`assert` 直接变成空操作。所以「构建系统传 `-DNDEBUG` + 源文件先 include 后 undef」这条路走不通——必须在头文件被 include 之前先 undef，让 assert.h 在「NDEBUG 未定义」的状态下展开 assert 宏。

边界/证据链接（均来自会话 01a0a575 的命令 ↔ 结果切片）：
- 切片里有独立探针实测：写 `/tmp/ndebug_probe.c`（先 `#undef NDEBUG` 再 `#include <assert.h>`），用 `/usr/bin/cc -O3 -DNDEBUG` 编译后运行，输出 `Assertion failed: (x==2) ... Abort trap: 6`——证实在 `-DNDEBUG` 下只要 undef 在前，assert 仍有判别力（命令+结果，非推测）。
- 同一会话按「undef 行号 < first_include 行号」口径逐文件核对，24/24 个测试文件 `#undef NDEBUG` 纪律全部合规，`compile_commands.json` 亦确认测试目标确带 `-DNDEBUG` 编译。
- 反例边界：仅靠读系统 `assert.h`（`#ifdef NDEBUG` 分支）只能确认「NDEBUG 下 assert 是 no-op」这一面，真正要证的是「顺序对是否仍生效」，这正是探针的价值——所以 verified_by 标 command 而非 human。
- 2026-09-16 独立复验（交互模型，非原会话）：`cc -O3 -DNDEBUG`：先 include 后 undef 的探针 exit=0（assert 被剥）；先 undef 的探针 Abort trap:6（断言保住），顺序即判别力
