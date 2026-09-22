---
id: using-namespace-injection-requires-namespace-declared-in-tu
type: lesson
status: validated
scope: global
domain: cpp
tags: [cpp, using-directive, namespace, bulk-edit, compile-error]
triggers:
  - "按 glob 给一批头文件/源文件批量注入 `using namespace <ns>;`"
  - "编译报 error: expected namespace name，指向刚注入的 `using namespace ...;` 行（失败信号）"
  - "被注入的文件只 include 标准库头，没有 include 任何声明该命名空间的核心头"
  - "复核『对所有 tools/xxx/*.{hpp,cpp} 都加 using namespace』这类按字面全量执行的动作"
  - "少数文件不满足注入前提，纠结该跳过注入还是给它补 include"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-60e8-7475-af70-36b8b52e029c
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [using-directive-vs-shim-namespace-ambiguity, zero-include-header-still-has-includers, cpp-namespace-wrap-must-follow-last-include]
---

**主张**：`using namespace X;` 注入到某个翻译单元时，若该 TU（经它包含的头链）根本没有声明 `X`，编译会直接失败（Apple clang 实测 `error: expected namespace name`），不是「多引入一点重载候选」的软风险。按 glob 批量注入前必须按「该文件是否（间接）包含声明该命名空间的核心头」分档：不满足前提的文件要么跳过注入，要么先补相应 include；按字面全量注入必然在少数「零核心头」文件上炸。

**为什么**：using-directive 的前提是名字查找能找到那个命名空间；纯标准库 TU 里 `amw` 这个名字从未被声明，编译器在解析 using 行时就直接报错。这类文件在批量扫描里往往只占少数（本例 parity 目录里唯一一个），所以「先跑一个文件试试」或「按目录整体看」都看不到它。

**证据（切片命令 ↔ 结果）**：

- 施工脚本按 glob 执行注入后（同批输出 `patched headers wrapped: 32 extern-open removed: 29 extern-close removed: 29 cpp wrapped: 25 …`），构建 parity 目标：
  `cmake --build build --target parity -j1` ↳ `parity rc=2 1 4:/tmp/review-scan-tests/repo/tools/parity/decoder.hpp:16:17: error: expected namespace name`。
- 该文件正是「零核心头」形态：`tools/parity/decoder.hpp` 只 include `<cstddef>/<string>`，不包含任何 core 头（末条 assistant 复核结论：parity 目录里唯一不包含任何 core 头的头文件；动作 7 字面要求对 `tools/parity/*.{hpp,cpp}` 都加 `using namespace amw;`）。
- 处置与复验：`sed -i '' '/^using namespace amw;$/d' repo/tools/parity/decoder.hpp && cmake --build build --target parity -j1` ↳ `parity rc=0 0`。

**边界 / 反例**：

- 报错形态依赖编译器：本会话是 macOS Apple clang 的 `error: expected namespace name`；GCC 同类语义的文案不同，别只按字面 grep 这一句认定「不是同一个错」。
- 「包含声明该命名空间的头」不等于「本文件直接写了 include」——间接包含也算；分档要按预处理后的名字可见性，不能只数本文件 `#include` 行里的核心头（见 `zero-include-header-still-has-includers` 的出入度区分）。
- 跳过注入只是让编译通过；该文件是否本应适配新命名空间（即是否漏了一个该改的文件）是另一个判断，不由本条回答。

**失败信号（未来命中即该想起本条）**：批量注入 `using namespace X;` 后，编译在某个只 include 标准库的文件上停在 `expected namespace name`；或复核清单里出现「该目录所有文件都加」而其中个别文件不含核心头。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
# 自包含最小复现（本机实测 2026-09-22，Apple clang 17.0.0 / arm64-apple-darwin24.6.0）
cd "$(mktemp -d)" && printf 'using namespace amw;\nint main(){return 0;}\n' > t.cpp \
  && clang++ -std=c++17 -c t.cpp -o /dev/null; echo "rc=$?"
# 实测：t.cpp:2:17: error: expected namespace name      rc=1
#       （列号 17 = `using namespace ` 之后的命名空间名首字符，与切片 decoder.hpp:16:17 同形态）

# 对照 1 —— 同 TU 内声明该命名空间：
printf 'namespace amw {}\nusing namespace amw;\nint main(){return 0;}\n' > ok.cpp \
  && clang++ -std=c++17 -c ok.cpp -o /dev/null; echo "rc=$?"      # 实测 rc=0

# 对照 2 —— 只靠被包含的头间接声明（证明「间接包含也算」）：
printf 'namespace amw {}\n' > a.hpp; printf '#include "a.hpp"\nusing namespace amw;\nint main(){return 0;}\n' > b.cpp \
  && clang++ -std=c++17 -c b.cpp -o /dev/null; echo "rc=$?"       # 实测 rc=0
```

**审核给出的修改意见（要点）**：核心主张站得住（本机 clang++ 一条三行 TU 即复现，列号 17 与切片 decoder.hpp:16:17 同形态），故留注入集；改三处。  1) 换证据（必做）。现有三条证据全绑在 /tmp/review-scan-tests 沙箱 + apply_card.py 改过的 algommw-plus 副本上，而该沙箱与副本都已不存在；两条构建命令在切片里还被尾部截断（L101 悬空 `|`、L105 断在 `> build_pa`）——连原样照抄重跑都做不到。把「证据（切片命令 ↔ 结果）」节改成自包含最小复现（见 minimalRepro 字段：三条 clang++ 命令 + 期望输出），沙箱那条 rc=2→rc=0 的构建记录降为「当时的现场复现」附注。  2) 收窄第一条越界断言。删掉「必然在少数『零核心头』文件上炸」的量词，改为条件式：「凡是该 TU（含间接包含）里看不到该命名空间的文件，注入后都会在这一行硬报错；是否真有这样的文件、有几个，取决于目录构成」。原因：「必然/少数」是从一个目录里恰好一个文件这次观测升格出来的，切片（一个 parity 目录）不支持它当一般律。  3) 删掉或改写第二条越界断言。「先跑一个文件试试」或「按目录整体看」都看不到它——后半句被本会话自身反证：这个错正是**整体构建 parity 目标**（编译整目录）才冒出来的。本意应是「

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 按字面全量注入必然在少数「零核心头」文件上炸。
- 所以「先跑一个文件试试」或「按目录整体看」都看不到它。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
