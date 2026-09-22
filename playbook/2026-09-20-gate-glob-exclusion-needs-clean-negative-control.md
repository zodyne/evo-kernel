---
id: gate-glob-exclusion-needs-clean-negative-control
type: lesson
status: validated
scope: global
domain: verification
tags: [gate, grep, glob, negative-control, shim, adversarial]
triggers:
  - "grep 闸门用 glob 排除某个头/目录（如 `-g '!*libm*'`），要证明排除规则真的生效"
  - "闸门在植入违规形态的副本上 CAUGHT，但不确定命中来自植入文件还是被排除的 shim 自身（失败信号）"
  - "验证闸门的排除面——纯净副本 + 真实 shim 头 + 零人工植入，期望 rc=1/零输出"
  - "shim 头本身写满被闸门禁的函数名，闸门可能把自己的豁免对象当违规（失败信号）"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b753-e147-7475-af70-36ce8acff051
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [checker-positive-control-or-negative-void, single-segment-miss-is-not-a-gate-hole]
---

# 闸门的 glob 排除规则要配一个零植入负对照

## 主张

grep 闸门靠 glob 把「豁免对象」排除出扫描集时（典型：libm 遮蔽 shim 头自身必然写满被禁的函数名），必须补一个**干净负对照**：纯净副本 + 真实 shim 头 + 零人工植入形态，跑闸门原样命令，期望零命中（`rc=1`/空输出）。否则无法区分「CAUGHT 来自植入的违规」与「CAUGHT 来自闸门把自己的豁免对象算成违规」。

## 为什么

排除规则与植入形态在同一棵树上跑时，两类命中在 stdout 里长得一样。只有把植入形态清零，才能单独测出闸门对豁免对象是否手下留情；也只有保留植入形态再跑一次，才能证明排除规则没有把真违规一起排掉。

## 证据（切片命令 ↔ 结果）

在沙箱（`/tmp/review-refute-c-gate-regex-bypass-forms/core`）里做两侧对照：

1. 放回真实 D10 `libm.hpp`（`cp probes/libm.hpp core/include/base/libm.hpp`）并保留植入形态，跑卡片原样命令：
   `== card command with libm.hpp present (checks glob exclusion) == core/src/zzforms/f2_global_contig.cpp:1:void f(){ doubl…`
   —— 命中落在植入目录 `core/src/zzforms/`，没有出现 shim 头自身的行。
2. `rm -rf core/src/zzforms` 后只留真实 shim 头再跑同一命令：
   `== card command on sandbox core + AUTHENTIC D10 libm.hpp (no planted forms) == rc=1 (1=empty=OK)`
   —— 零命中/空输出，排除规则对 shim 自身生效，且不是靠「整个目录都被跳过」掩盖（第 1 步已证明植入形态仍会被抓）。

## 边界 / 反例

- 负对照通过只证明「当前这一版闸门命令 + 当前 glob 模式」的排除生效；命令或 glob 一改就要重跑。
- 只有负对照、没有植入形态的正对照，证明不了闸门还抓得到真违规——两侧都要跑（本条两步即是一对）。
- 排除范围过宽（例如把整个 `core/include/base/` 都排除）时负对照照样通过，但闸门对真实代码的覆盖已被削掉；负对照检测不到这种情况，需要另查排除模式的作用域。
