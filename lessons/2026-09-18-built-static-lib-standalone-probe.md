---
id: built-static-lib-standalone-probe
type: lesson
status: candidate
scope: global
domain: c-testing
tags: [c, probe, static-library, read-only-audit, edge-case]
triggers:
  - "只读审查 C 库，要验证单测没覆盖的边界组合（退化入参/极端配置）"
  - "被测仓库不让改或不想改，不能靠加测试用例来取证"
  - "仓库已有 build/ 下的静态库（如 build/core/libcore.a），想直接调它的公共 API"
  - "想给某个 C 函数写最小复现，却卡在『要重新配置/编译整个项目』"
  - "只有『测试全绿』一条证据，需要独立于测试框架的第三种证据（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5b31-7353-8a3d-42c878dd751c
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [c-probe-local-header-include-resolves-source-dir, mmw-cpp17-port-golden-equivalence]
---

# 主张

对 C 库做只读审查时，最省事的硬证据路径是：在 /tmp 写一个最小 C 探针，`-I <repo>/core/include` 后用 `<repo>/build/**/lib*.a` 直接链接，调用公共 API 打印实际数值——不用改被测仓库、不用重配构建，输出即可作为边界行为的证据。

# 证据（切片命令 ↔ 结果）

- 已构建产物存在：`ls /Users/zodyne/Dev/algommw/build/core/` ↳ `… libcore.a …`；`find … -name "*.a"` ↳ `/Users/zodyne/Dev/algommw/build/core/libcore.a`。
- 探针 1（DDM 折叠）：
  `clang -std=c99 -O1 -I /Users/zodyne/Dev/algommw/core/include probe_ddm_fold.c /Users/zodyne/Dev/algommw/build/core/libcore.a -lm -o probe_d…`
  ↳ `eWaveformValidate(subbands=384) = 0 (0=eOk) eDopplerDdmInit = 0 ulFftSize = 768 (期望 768) eDopplerDdmProcess = 0 xFold[0]…`
- 探针 2（spectra attach）：同目录 `/tmp/probe_spectra_ddm.c` ↳ `[TDM] eChainInit = 0 [TDM] eChainDoaSpectraAttach = 0 (0=eOk, 2=eErrNotImpl) … [TDM] eChainDoa = 0, 检出点…`
- 本会话把这条路径列为方法：末尾结论写 `针对测试未覆盖的组合写 3 个 /tmp 探针拿硬证据`；写/改文件清单为 `/tmp/probe_ddm_fold.c`、`/tmp/probe_spectra_ddm.c`。

# 边界 / 反例

- 探针只覆盖写进去的那组入参：结论必须写明入参（如 `subbands=384`），不能由一次探针推广成「该 API 在所有配置下正确」。
- 链接的是**已构建**的静态库：它能证明库当前产物的行为，不能证明「重新构建后行为不变」；改了源码要重新 build 再跑探针。
- 探针放 /tmp 时 `#include "本地头"` 的解析规则见 related 条目（引号包含先查源文件所在目录），必要时改用尖括号或用 `-I` 兜底。
