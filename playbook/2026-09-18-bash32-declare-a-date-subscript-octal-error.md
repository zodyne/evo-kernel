---
id: bash32-declare-a-date-subscript-octal-error
type: lesson
status: validated
scope: global
domain: shell
tags: [bash, bash32, macOS, associative-array, octal, value-too-great-for-base]
triggers:
  - "在 macOS 自带 /bin/bash 上用 `declare -A` 建关联数组，键是日期或带前导 0 的字符串"
  - "报 `value too great for base (error token is \"09\")` 或 invalid arithmetic operator（失败信号）"
  - "脚本里用 `[2026-09-17-xxx]=值` 批量填映射表，Linux 正常、macOS 报错"
  - "要按文件名/日期把一批产物映射到目标目录（lessons/playbook）"
  - "用 `declare -A` 后再用 `数组[$键]` 取值，取值全是空（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae1e-1763-764c-a77e-51771fbd8c10
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [macos-bsd-awk-no-asort-asorti]
---

# macOS /bin/bash 3.2 无关联数组：日期串做下标会被当八进制算术求值

**主张**：macOS 自带的 `/bin/bash` 是 **3.2**（无 bash 4+ 的关联数组）。`declare -A Z=( ["2026-09-17-foo"]=lessons )` 在 3.2 下 `declare -A` 不生效，赋值退化成**索引数组**，下标 `2026-09-17-foo` 被当**算术表达式**求值：`2026-09` 被解析成前导 0 的八进制数 → `/bin/bash: 2026-09: value too great for base (error token is "09")`，整条命令失败。凡是"日期/带前导 0 的字符串"当数组下标的写法都要避开。

**证据（2026-09-17 本机）**：
- 切片里按提案名映射 zone 的 `declare -A Z=( ["2026-09-17-fmcw-absolute-phase-float64-precision"]=lessons … )` 直接失败：`✗ /bin/bash: 2026-09: value too great for base (error token is "09")　Command exited with code 1`。
- 同一批映射改用 `case "$b" in *fmcw-absolute-phase*|*fmcw-sim-near-range*) … esac` 后写出成功：`✓ lessons: 2026-09-17-fmcw-absolute-phase-float64-precision`、`✓ lessons: 2026-09-17-fmcw-sim-near-range-beat-amplitude…`。
- 本机复现：`/bin/bash --version` → `GNU bash, version 3.2.57(1)-release`；`/bin/bash -c 'declare -A Z=( ["2026-09-17-foo"]=lessons )'` → 同一条 `value too great for base (error token is "09")`。
- 旁证：该会话在查重关键词里已把 `bash 3.2`（`mapfile|readarray`）列为本机约束。

**做法**：3.2 下不要用关联数组。用 `case "$key" in *pat*) zone=… ;; esac`、两个平行数组 + `for`、或 `printf -v "Z_$(printf '%s' "$k" | tr -c 'A-Za-z0-9' _)" '%s' "$v"`。确实需要关联数组时显式调用 brew 的 bash 5（`/opt/homebrew/bin/bash`），不要依赖 `/bin/bash`。

**边界**：只影响 `/bin/bash`(3.2) 这条路径；zsh（macOS 默认登录 shell）、brew bash 5 正常。`sh`/`dash` 也无关联数组，但报错形态可能不同。
