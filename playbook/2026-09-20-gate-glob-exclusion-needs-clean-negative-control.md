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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
最小复现（本机实跑，独立于已消失的 /tmp 沙箱与 algommw-plus HEAD）：\nD=$(mktemp -d); mkdir -p \"$D/core/include/base\" \"$D/core/src/zzforms\"\nprintf 'void shim(){ std::sin(1.0); }\\n' > \"$D/core/include/base/libm.hpp\"   # 真实 shim 头，自身写满被禁形态\ncd \"$D\"\nrg -n '(std::|::)(sin|cos|tan)\\(' core -g '!*libm*'; echo \"rc=$?\"        # 期望 rc=1、空输出（负对照通过）\nprintf 'void f(){ double x=0; std::sin( x ); }\\n' > core/src/zzforms/f2.cpp\nrg -n '(std::|::)(sin|cos|tan)\\(' core -g '!*libm*'; echo \"rc=$?\"        # 期望 rc=0、命中 zzforms/f2.cpp\nrg -n '(std::|::)(sin|cos|tan)\\(' core; echo \"rc=$?\"                     # 去掉排除 glob → shim 自身成为假命中，证明负对照必要性\n实测输出：\nrc=1 (1=empty=OK)\ncore/src/zzforms/f2_global_contig.cpp:1:void f(){ double x=0; std::sin( x ); }\nrc=0\ncore/include/base/libm.hpp:1:void shim(){ std::sin(1.0); }\nrc=0
```

**审核给出的修改意见（要点）**：保留在注入集，换证据。核心主张（glob 排除豁免对象时必须配零植入负对照，否则无法区分『CAUGHT 来自植入』与『CAUGHT 来自闸门把豁免对象算违规』）真值稳定——它是 rg glob + 扫描集语义的一般属性，本机自包含实跑已两侧复现（见 minimalRepro）：负对照 rc=1 空、植入后 CAUGHT、去掉排除 glob 则 shim 自身即假命中。\n因此原证据节的两条『切片命令』应替换为 minimalRepro 这类自包含片段，并在证据节标注：原两命令在切片中尾部被截断（第 70/75 行 echo 断在 'chec'/'no plan'，rg 命令体与 glob 模式整体缺失），且 /tmp/review-refute-c-gate-regex-bypass-forms 沙箱已消失 —— 故证据记录不可照抄重跑（这是记录可复跑性问题，不是主张真值问题，不构成降级理由）。\n『为什么』一节给了切片里没有的机制解释（两类命中在 stdout 里长得一样），该机制经 minimalRepro 第 3 步独立证实（去掉 glob 后 shim 头自身出现在命中里），成立。\n一般律成立：本条把一次卡 P1.0b libm 闸门观测升格为一般律，但该律在换一套自造目录/模式后仍成立，故无需收窄主张本身。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
