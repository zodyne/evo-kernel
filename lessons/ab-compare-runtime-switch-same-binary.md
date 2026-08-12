---
id: ab-compare-runtime-switch-same-binary
type: lesson
status: candidate
scope: global
domain: methodology
tags: [ab-test, benchmarking, build, algorithm-comparison]
triggers:
  - 要对比新旧两条算法/过滤路径的效果
  - A/B 两组结果有差异，怀疑差异来自编译选项而不是算法
  - 设计离线仿真/回放的对比实验
  - 为对比实验分别构建两个二进制或两个分支
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:da720f38-036f-42ec-820d-ce8538a4fc1f
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [compile-flag-zero-cost-verification]
---

# A/B 对比两条算法路径：同一份二进制里运行期切换，不分两个构建

对比新旧实现时，把两条路径编译进**同一个产物**，用运行期开关（如 `SP_setPipelineMode()` / 命令行模式参数）选择，再用同一个离线程序、同一批输入各跑一遍。这样两组输出之间的差异里**没有编译器、编译选项、构建配置的份**，归因干净；也避免「A 组是上个月的构建、B 组是今天的构建」这类隐性漂移。

编译期开关留给「旧路径是否存在于产物里」这种存在性问题，并用 `nm` 验证（默认构建不含旧路径符号、`LEGACY=1` 构建含）。

**证据**（session da720f38）：libucm221 的 legacy/faf 两条点云过滤路径在同一份 `libSPX_ALG.dylib` 里运行期切换，`make ab DATA=...` 对 000028（15,040 帧）跑出 legacy vs faf 两组，`compare_runs.py` 直接对比（总点数 -21.6%）；`nm -gU` 验证默认构建 `bestIdx` 符号数为 0、LEGACY=1 构建存在。
