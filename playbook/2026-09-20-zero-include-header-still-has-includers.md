---
id: zero-include-header-still-has-includers
type: lesson
status: validated
scope: global
domain: verification
tags: [c, cpp, headers, dependency, include, dead-code]
triggers:
  - "用『头文件自身 0 行 #include』给一批头文件分类或判影响面"
  - "统计完头的 include 行数后直接写『这些头无消费者 / 与风险无关』（失败信号：只量了出度）"
  - "复核『某头文件不含 include ⇒ 该动作未定义 / 无风险』类发现，要定影响面"
  - "判定某个 C/C++ 头能否删或改，手上只有它自己的内容"
  - "在 manifest / 清单里 grep 到头文件名，就被当成代码消费者"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-ee02-7475-af70-36c7ee72ff22
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [libm-call-audit-via-artifact-symbols, pyflakes-absent-ast-unused-code-check, include-closure-per-tu-impact-count]
---

**主张**：把头文件自身的 `#include` 行数（出度）当成「有没有人用它」（入度），会得出错误的影响面——0 行 include 的头照样可能被真实 TU 引用。判影响面必须两向都查：它自己的 include 行 + 谁 include 它。

**为什么**：出度只说明这个头「不依赖别人」，与「别人是否依赖它」是两个方向的量。只用出度分类，会把「活依赖」和「死代码」放进同一个桶。

**证据（切片命令 ↔ 结果）**：

- 出度扫描：`for f in $(find core -name '*.hpp' -o -name '*.h'); do n=$(rg -c '^\s*#include' "$f" …); echo …` → 32 个 core 头里唯二打印出空计数的是 `core/include/base/compiler.hpp` 与 `core/include/types/sensor.hpp`（`rg -c` 零命中不打印 0，所以这两行没有数字，其余如 `core/include/dpu/doa/cfg.hpp 1`）。
- 入度查询（sensor.hpp）：`rg -n 'types/sensor\.hpp|"sensor\.hpp"|sensor\.h' …` → `core/src/types/waveform.cpp:14:#include "types/sensor.hpp"`、`core/include/types/radar.hpp:…` —— 有真实消费者。
- 入度查询（compiler.hpp）：`rg -n 'compiler\.h(pp)?' --glob '!build/**' --glob '!docs/**' .` → 只命中 `./PLAN.md:74`（M18 的检查行）；放进 docs 后也只有 `./docs/baseline-manifest.txt:25:<hash>` —— 零代码消费者，且清单里的哈希行不是引用。
- 两个头在「自身 0 行 include」这一维**完全相同**，影响面却一个是活依赖、一个是死代码：只用出度分类必然把它们归成一类。

**边界 / 反例**：

- 入度查询要限定范围（`--glob '!build/**'` 之类）并区分「真代码引用」与「文档/清单/哈希里的文件名」。
- 只覆盖按字面路径写的 include：宏拼接的头名、`-include` 强制包含、构建系统 GLOB 之类的隐式引用不会被 rg 命中，判死代码前要另查。
- 本条只管「消费者/影响面」判定，不判这个头该不该保留或该不该加 include。

**失败信号（未来命中即该想起本条）**：审计报告只给出「0 include 的头」清单，就下「无消费者 / 无风险」结论；或把 manifest 里的哈希命中当成代码使用证据。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含最小复现（scratchpad 下新建，已实跑）：\n\nmkdir -p r/core/include/base r/core/include/types r/core/src r/docs\nprintf '#ifndef W_H\\n#define W_H\\n#define WIDGET_MAX 8\\n#endif\\n' > r/core/include/base/widget.hpp   # 0 行 include\nprintf '#ifndef G_H\\n#define G_H\\n#include \"base/widget.hpp\"\\n#endif\\n' > r/core/include/types/gadget.hpp\nprintf '#include \"base/widget.hpp\"\\nint main(void){return WIDGET_MAX;}\\n' > r/core/src/use.cpp\nprintf 'deadbeefcafe  core/include/base/widget.hpp\\n' > r/docs/manifest.txt\ncd r\n# (A) 出度：只看头自身\nfor f in $(find core -name '*.hpp'); do n=$(rg -c '^\\s*#include' \"$f\" 2>/dev/null || true); echo \"$f ${n:-<EMPTY/0>}\"; done\n# 实测输出：\n#   core/include/types/gadget.hpp 1\n#   core/include/base/widget.hpp <EMPTY/0>      ← widget.hpp 出度 0\n# (B) 入度：谁引用它\nrg -n 'base/widget\\.hpp|\"widget\\.hpp\"|widget\\.h' --glob '!build/**' .\n# 实测输出：\n#   ./docs/manifest.txt:1:deadbeefcafe  core/include/base/widget.hpp   ← 清单哈希行，非消费者\n#   ./core/src/use.cpp:1:#include \"base/widget.hpp\"                ← 真实 TU 消费者\n#   ./core/include/types/gadget.hpp:3:#include \"base/widget.hpp\"    ← 头消费者\n\n结论复现：出度 0 的 widget.hpp 实际有真实 TU 消费者；只用出度会把它误归为死代码。同时复现了『清单哈希行会被 rg 命中但不是消费者』这一反例。此复现与 algommw-plus 无关，可在本机随时重跑。
```

**审核给出的修改意见（要点）**：核心主张（出度≠入度，判影响面必须两向都查）稳定成立，且已有自包含最小复现——保留在注入集。但证据节有两处超出证据的断言必须改：\n1) 把『只命中 ./PLAN.md:74』改为『（去 docs）命中 4 行 PLAN.md:74/315/505/922，全是计划/文档提及』——原句是 `| head` 截断产物的误读。\n2) 把『放进 docs 后也只有 ./docs/baseline-manifest.txt:25』改为『放进 docs 后另有 docs/specs/naming.md:42、docs/specs/architecture.md:15 等文档提及，均非代码消费者』。\n3) 证据口径改造：把绑在 algommw-plus HEAD 33a58c0 的举例（该 HEAD 现已作废——compiler.hpp 在 7d84c1c 被删、sensor.hpp 已加 include）标注为『示意』，并把 minimalRepro 里那条自包含复现补进证据节，替换对已消失仓状态的依赖。\n4) 建议在证据里给命令补上 `--glob '!docs/**'`/`| head` 之外的完整原文，避免日后再次把截断当全量。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- → 只命中 `./PLAN.md:74`（M18 的检查行）
- 放进 docs 后也只有 `./docs/baseline-manifest.txt:25:<hash>`

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
