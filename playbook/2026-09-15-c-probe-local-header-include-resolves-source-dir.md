---
id: c-probe-local-header-include-resolves-source-dir
type: lesson
status: validated
scope: global
domain: c-embedded
tags: [c, probe, include, gcc, adversarial-verification]
triggers:
  - "抽取测试文件前缀（head -N test_x.c）写成独立 C 探针单独编译"
  - "cc 报 'xxx.h' file not found，但该头文件明明就在 tests/ 子目录下"
  - "对抗式验证：写探针直接调用被测函数观察返回值"
  - "从 /tmp 编译一个带本地 #include \"helpers.h\" 的 C 文件"
  - "给 C/C++ 单测套件做独立冒烟/证伪探针"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a6aa-18b7-7353-8a3d-42de2066d8d8
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [c-test-undef-ndebug-before-assert-include]
---

# 主张

`#include "本地头.h"`（引号包含）先相对「**包含它的源文件所在目录**」解析，之后才查 `-I` 路径；把测试文件前缀 head 出来当独立探针、放到 `/tmp` 编译时，引号包含的本地头（如 `helpers.h`）会找不到。把探针 `cp` 回该头文件同目录后即可编译通过。

# 为什么

引号包含的语义是「本地头文件」，GCC/Clang 优先在**当前源文件所在目录**找，`-I` 只影响尖括号包含与搜索顺序。本例 `helpers.h` 位于 `tests/integration/`，而编译命令只给了 `-I tests`（没给 `tests/integration`），故探针在 `/tmp` 时引号包含必炸。不是头文件路径写错，而是探针放错了目录。

# 边界 / 反例

- 尖括号 `#include <x.h>` 不受此规则影响，走 `-I` 搜索路径。
- 也可把被复用头文件所在目录显式加进 `-I`（如 `-I tests/integration`）规避，但引号包含仍会先查源文件目录，只是多一条兜底。
- 严格 ISO C 下探针里的 `printf` 会报 `call to undeclared library function 'printf'`，需补 `#include <stdio.h>`（次要坑，随手带上）。

# 证据

对抗式验证 algommw 测试闸门缺口时，用 `head -115 tests/integration/test_doa_beam.c` 拼探针：
1. `/tmp/probe_guard.c` 编译 → `error: call to undeclared library function 'printf'`（缺 stdio.h）。
2. 补 `#include <stdio.h>` 后从 `/tmp` 用 `cc -I core/include -I tests` 编译 → `"helpers.h" 1 error generated`，`/tmp/probe_guard` 未生成。
3. `cp /tmp/probe_guard.c tests/integration/probe_guard.c` 后同命令编译 → 成功，探针输出 `zero-grid dbf2d eChainInit=2 (eErrParam=2), with-grid=0 (eOk=0), bDirect=1`。
