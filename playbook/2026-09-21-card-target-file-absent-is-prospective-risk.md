---
id: card-target-file-absent-is-prospective-risk
type: lesson
status: validated
scope: global
domain: code-review
tags: [adversarial, severity, blocker, risk, construction-card, include-guard]
triggers:
  - "对抗式复核『施工卡将要新建的文件有缺陷』类发现，要在 confirm/refuted 与 blocker/risk 之间定级"
  - "机制在 /tmp 副本里手写复现成功，但目标仓库 HEAD 里这些文件尚不存在（失败信号：把前瞻缺陷当当前阻塞）"
  - "判『缺 include guard / 缺校验』类发现是否阻塞当前合并或验收"
  - "施工卡动作清单逐字要求写出某文件，复核要判『按卡执行时会不会真踩到』"
  - "复核报告要写 severity，手上只有 HEAD 副本的复现 rc=1，没有目标仓库里的实际文件"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-eca1-7475-af70-36bc7743f28f
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [synthetic-sandbox-mechanism-is-not-target-repo-risk, readonly-verify-tmp-variant-git-status-proof, inline-constexpr-header-still-needs-include-guard, blind-spot-claim-needs-instance-count]
---

# 施工卡将新建的文件在 HEAD 尚不存在时：事实成立，但定级为前瞻 risk 而非当前 blocker

## 主张

复核对象是**施工卡将要新建的文件**时，把「事实」与「严重度」分开判：（1）事实——在目标 HEAD 副本里按卡片动作清单**逐字**写出该文件，机制在编译下复现（rc=1）即 `isReal=true`；（2）严重度——目标 HEAD 里这些文件尚不存在（新建头只活在 /tmp 副本），这不是当前仓库的阻塞，而是执行该卡时会踩到的前瞻 risk。本会话最终裁决正是 `isReal = true（事实成立），但严重度应从 blocker 降为 risk`。

## 为什么

「机制存在」与「当前仓库已有该缺陷」是两个不同的断言；但也不能走向另一个极端——发现方复现所用的文件若是**卡片动作清单逐字要求写出的内容**，那它就是该卡执行路径上的真实输入，不是无关的自造沙箱，不能因此判 refuted。缺席证据（HEAD 没有文件）与路径证据（卡的动作就是写出它）合起来，指向「执行该卡时必然发生」这一档，而不是「现在就坏着」。

## 证据（切片命令 ↔ 结果）

- 目标 HEAD 无该文件：`ls -R core … ls core/include core/include/base` ↳ `core/include: base chain dpu math types  core/include/base: compiler.hpp types.hpp`（没有 `fp.hpp` / `libm.hpp`）；`git status --short` ↳ `?? docs/ledger/2026-09-18-P1.0b/  ?? inc_types.cpp`（无待落地的新头）。
- 按卡动作逐字写入 /tmp 副本：`cat > $R/core/include/base/libm.hpp <<'EOF' …`（副本 `…/repo`、`…/repo2`，仓库零改动）。
- 机制复现：`clang++ -std=c++17 -fsyntax-only -I core/include -I core/src …` ↳ `rc=1 … core/include/base/libm.hpp:9:15: e…`；补 guard 后 ↳ `rc=0 (after adding guard ONLY to fp.hpp) 0 error count = 0`。
- 末条 assistant：`结论：**isReal = true（事实成立），但严重度应从 blocker 降为 risk。**`；关键点 1 写「独立复现成功（全部在 /tmp/… 副本内，仓库零改动）：按动作 2/3 逐字写无 guard 的 fp.hpp/libm.hpp，按动作…」（切片在此截断）。

## 边界 / 反例

- 切片截断了末条 assistant 的完整定级理由；本条只主张可见的裁决与证据链，不复述未显示的理由。
- 对比 `synthetic-sandbox-mechanism-is-not-target-repo-risk` 的 isReal=false 情形：那条的证据载体与目标仓库无关（自造上下文）；本条的载体由**卡片动作文本**指定。若发现方只是随手手写、卡片并没有要求那种写法，则仍按 refuted 处理。
- 目标 HEAD 里该文件/形态已存在时，按当前 blocker 计，不适用本条。
- 文件缺席只说明「现在没有」，不降低卡片落地时的修复必要性：同会话已复现「只给 `fp.hpp` 加 guard 即 rc=0」的修复路径。
- 「按卡逐字写」要对着动作清单核到字面：卡动作若本身含守卫/校验，风险不成立。

## 失败信号（未来命中即该想起本条）

- 复核报告把「按卡片动作手写复现出的机制」直接升级成当前阻塞项，或反过来直接判 refuted，却不查目标 HEAD 有没有这些文件。
- 定级理由里出现「理论/前瞻」或「已是阻塞」的措辞，却拿不出文件存在性（ls / git status）证据。
