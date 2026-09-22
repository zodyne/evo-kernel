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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含最小复现（本机实测：cmake 4.4.2 / Apple clang 17.0.0，macOS arm64，Unix Makefiles）：

mkdir -p /tmp/kdemo/src && cd /tmp/kdemo && cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.20)
project(ktest CXX)
add_library(t STATIC src/a.cpp src/b.cpp src/c.cpp)
EOF
for f in a b c; do printf 'int %s_fn(){ Real_t x=1; return (int)x; }\n' $f > src/$f.cpp; done
cmake -S . -B b >/dev/null 2>&1
cmake --build b -j1 > nok.log 2>&1; echo "no-k rc=$?"; echo -n "TUs compiled: "; grep -c 'Building CXX' nok.log; grep -E 'error:' nok.log | sed 's/.*error:/error:/' | sort | uniq -c
cmake --build b -j1 -- -k > k.log 2>&1; echo "keep-going rc=$?"; echo -n "TUs compiled: "; grep -c 'Building CXX' k.log; grep -E 'error:' k.log | sed 's/.*error:/error:/' | sort | uniq -c

实测期望输出：
no-k rc=2
TUs compiled: 1
   1 error: unknown type name 'Real_t'
keep-going rc=2
TUs compiled: 3
   3 error: unknown type name 'Real_t'

即：不带 `-k` 时 make 在第一个失败目标后停止（只编 1 个 TU），带 `-- -k` 时继续编完全部 3 个 TU；两者 rc 仍为 2（收集与退出码解耦，与条目主张一致）。

附带独立复验（-ferror-limit 边界）：
python3 -c "open('/tmp/kdemo/big.cpp','w').write('int f(){'+''.join(' Bad_t a%d;'%i for i in range(40))+' return 0;}\n')"
clang++ -std=c++17 -c /tmp/kdemo/big.cpp -o /dev/null 2>&1 | grep -c 'error:'   # → 20
clang++ -std=c++17 -ferror-limit=0 -c /tmp/kdemo/big.cpp -o /dev/null 2>&1 | grep -c 'error:'   # → 40
```

**审核给出的修改意见（要点）**：主张真值是稳定的工具链属性（cmake/make 的 keep-going 语义），不绑在 /tmp/review-scan-core 沙箱或 algommw-plus HEAD 上，本机已用自包含最小复现复跑，故留注入集；但证据要换、对照要收窄：  1) 换证据：两条切片证据所在沙箱（/tmp/review-scan-core）已消失，且证据命令在切片里被截断（L114 直方图命令、L115 输出、L72 命令尾部均被切），不能照抄重跑。改引 minimalRepro 里的自包含复现，并把完整直方图命令（`grep -E 'error:' log | sed 's/.*error:/error:/' | sort | uniq -c`）写全 —— 现在条目只描述了「grep/awk | sort | uniq -c」而没给可执行命令。  2) 对照收窄/去混杂：现有对照是 build(-j1, pristine 树) vs build2(-k, repo2 树)，跨树且混杂源码差异，不能单凭它证明「-k 带来更多错误面」。切片里已有同树对照 build2_j1.log（repo2，无 -k）→ 14 条 `unknown type name 'Real_t'`，build2_keepgoing（repo2，-k）→ 57 条；应改引这一对，或至少注明原对照非同一棵树。  3) 边

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
