---
id: rg-r-is-replace-not-recursive
type: lesson
status: validated
scope: global
domain: cli-search
tags: [ripgrep, rg, flags, silent-corruption, evidence-integrity]
triggers:
  - "按 grep -rn 的习惯写 rg -rn <pattern> <dir>，想要『递归 + 行号』"
  - "rg 命中行里根本不含要搜的词，或匹配处显示成单个字母/一小段固定文本（失败信号）"
  - "审查/取证时用 rg 摘字段名、枚举成员或引用原文，输出与源码对不上"
  - "从 grep 迁到 ripgrep，不确定 -r 在两个工具里是不是同一个含义"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5bdd-7353-8a3d-42cfac95e3a6
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: []
---

# `rg -rn` 不是「递归 + 行号」：`-r` 是 `--replace`，会静默改写命中行

## 主张
ripgrep 的 `-r` 是 `--replace <text>`，不是 grep 的 `-r/--recursive`。写 `rg -rn "A|B" <dir>` 时，`-r` 把紧跟的 `n` 当成替换文本：ripgrep 照常搜索、不报任何错，但**把命中的 `A|B` 换成字面量 `n` 再打印**。输出看着正常，实际是被篡改过的证据。

## 为什么危险
这不是报错，是**静默失真**。审查/取证时，"grep 出来是这样"本身就是下结论的依据——命中文本被替换后，读者会把 `w.xDopplerStep` 读成 `w.nStep`、把枚举成员读成 `n`，据此写出错误结论而不自知。

## 证据（本次审查中同一条命令的前后对照，两次都命中）
- ❌ `rg -rn "xDoppler|xSnr" python/radar_viz/ | head -20`
  → `python/radar_viz/boards.py:        f"ΔV {w.nStep:.4f} · {float(w.xFrameTime) * 1000:.0f}ms"`（源码里没有 `nStep` 字段）
- ✅ 去掉 `-r` 后同一条 `rg -n "xDoppler|xSnr" python/radar_viz/ | head -20`
  → `python/radar_viz/boards.py:59:        f"ΔV {w.xDopplerStep:.4f} · {float(w.xFrameTime) * 1000:.0f}ms"`
- ❌ `rg -rn "eWindowNone|eWindowHann" core/include/ | head`
  → `core/include/core/math/window.h:    n = 0, /* 矩形窗(不加窗) */`（枚举成员名整个被吃掉，这行不能当"该枚举叫什么"的证据）

## 做法 / 边界
- 只要行号：`rg -n <pattern> [path]`。ripgrep **默认递归**，给目录参数即可，不需要 `-r`。
- 只有真的要做替换时才用 `-r <text>`——那是在做替换预览，不是搜索。
- 失败信号：命令零报错，但打印出的命中行里找不到你要搜的词；或匹配位置整齐地变成同一个短字符串。
- 同族的"grep 语义迁移陷阱"还有：`-E` 在 rg 里是 `--encoding`（见 `rg-capital-e-is-encoding-not-extended-regex`）、字面量要用 `-F`。跨工具照搬 flag 前先确认语义。
