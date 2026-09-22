---
id: grep-lint-gate-calibrate-before-enforce
type: lesson
status: validated
scope: global
domain: tooling
tags: [grep-gate, lint, false-positive, calibration, naming-gate]
triggers:
  - "新写了一个 grep/rg 源码闸门（命名/风格/禁用写法），准备把它接到构建或卡验收上"
  - "闸门首跑命中数很大（本会话 N1=55 / NAMING=496），分不清哪些是真违规哪些是正则误报"
  - "闸门脚本自己的注释/正则文本出现在命中清单里（失败信号：自命中）"
  - "合法声明形态被闸门当违规：static_assert、契约字段 uint8_t bX; 带尾注释等（失败信号）"
  - "要把闸门清零并给出各检查项的基线，需要先知道误报面而不是直接改代码"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4a3-ae96-7475-af70-36ad39adaba4
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [gate-regex-matches-contiguous-glyphs-only]
---

**主张**：新写的 grep/rg 源码闸门在「清零」之前必须先拿现有树跑一遍并逐条看命中：至少三类误报要先处理——**闸门脚本自身文本**、**合法声明形态**（`static_assert`、契约字段 `uint8_t bX;`）、**宏/数组前缀等本仓约定形态**。先把误报收紧到 0、记录每项基线，再让它进验收。

**为什么**：基于行/字的正则无法区分「定义」与「使用」、「代码」与「注释」。若不校准就接闸门，要么把整棵树改一遍去迎合误报（危险且伤及零行为承诺），要么让闸门长期红着失去约束力。校准的顺序应是「先统计、再抽查命中样本、再收紧规则」，而不是反向。

**证据（本会话切片，命令 ↔ 结果）**：

- 首跑基线：`rc=1 [N1] TU 局部函数无 prv(static)  55  [N2] typedef / typedef struct  38 ...`；多轮后仍 `NAMING: 496`，说明首版规则把大量合法形态计入。
- N1 误报样本：`=== N1 55 抽样 === core/include/types/radar.hpp:112: static_assert( sizeof( static_cast<const Track_t *>( nullptr )->xState ...` —— `awk '/^static[^(]*\(/'` 把 `static_assert` 当成了 TU 局部函数定义。改为 Python 版带作用域判定后，N1 计数按 `55 → 9 → 31 → 11 → 0` 收敛（中间因作用域判定修正回升过）。
- 自命中：N9 扫描把 `tools/naming_gate.sh:146:  # 契约字段的合法形态: uint8_t bX;,可带对齐空格与尾注释(struct ... _t 的字段);` 当成违规；加 `gate 自排除` 后消失。N9 最后把带尾注释的契约字段声明加入白名单，`NAMING: 0`。
- 收紧后同一闸门在构建/测试零改动的树上跑出 `NAMING: 0`，随后才接入 `tools/naming_gate.sh` 作为 G11。

**边界 / 反例**：

- 规则内容本身来自该仓 `docs/naming.md` v2，不可直接搬到别的仓；可迁移的是校准流程与三类误报来源。
- 误报收紧可能引入漏报（例如为放行契约字段而放宽 `uint8_t b*`），需要负控/样本抽查兜底，不能只看计数到 0。

**失败信号（未来命中即该想起本条）**：新闸门首跑就大红且命中清单里出现脚本自身路径、`static_assert` 或结构体字段声明；或为让闸门变绿而大面积改合法代码。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含、可当场重跑（本机已跑，输出见下）：\nd=$(mktemp -d)\nprintf 'static_assert( sizeof(int)==4, \"x\" );\\nuint8_t bEnable;\\n' > \"$d/radar.hpp\"\nprintf '#!/usr/bin/env bash\\n# 契约字段合法形态: uint8_t bX;\\nroot=$(dirname \"$0\")\\necho \"--- N1 static-fn regex ---\"; grep -nE \"^static[^(]*\\\\\\\\(\" \"$root\"/radar.hpp \"$root\"/gate.sh\\necho \"--- N9 contract-field regex ---\"; grep -nE \"uint8_t[[:space:]]+b[A-Z]\" \"$root\"/radar.hpp \"$root\"/gate.sh\\n' > \"$d/gate.sh\"\nchmod +x \"$d/gate.sh\"; \"$d/gate.sh\"\n期望输出（三类误报一次全现）：\n--- N1 static-fn regex ---\n.../radar.hpp:1:static_assert( sizeof(int)==4, \"x\" );      ← 合法声明形态被函数定义正则命中\n--- N9 contract-field regex ---\n.../radar.hpp:2:uint8_t bEnable;                            ← 合法契约字段被命中\n.../gate.sh:2:# 契约字段合法形态: uint8_t bX;                 ← 闸门脚本自身文本（自命中）
```

**审核给出的修改意见（要点）**：核心主张（新 grep/rg 闸门先跑现状树、逐条看命中、先统计→抽样→收紧、再清零进验收）与切片吻合，且三类误报来源（脚本自命中 / 合法声明形态 static_assert·契约字段 / 本仓宏·数组前缀约定）在切片里都能逐条对上，主张真值是「行/字正则无法区分定义与使用、代码与注释」这一稳定属性，不绑 algommw-plus 的当时 HEAD——故不必降级，只需两处修：(1) bullet 4 时序改写：切片显示 G11 是在 P2d-a 就『立闸门 + 记录当前树基线』（commit 75b7e4b），NAMING:0 直到 P2d-d 才出现（切片 2124）；应把『随后才接入 tools/naming_gate.sh 作为 G11』改为『先以红态+基线记录立闸（P2d-a），收紧到 NAMING:0（P2d-d）后才转绿生效』，否则与实际流程不符。(2) 证据可复跑性：bullet 2 的 `awk`、bullet 3 的 N9 `rg` 在切片里均被截断（awk 只剩 `'/^static[^(]*\('/` 前缀、rg 尾正则被切），不可照抄重跑；建议用 minimalRepro 那条自包含最小复现作为补充/替换证据（它当场重现『static_assert 被函数正则命中 / 契约字段被命中 / 闸门自命中』三类）。可选收窄：把『至少三类误报』标注为本会话实测，避

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 随后才接入 tools/naming_gate.sh 作为 G11（时序断言，与切片矛盾：G11 在 P2d-a 立闸门并记录基线，NAMING:0 直到 P2d-d 才出现）

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
