---
id: hermes-config-get-one-key-per-call
type: lesson
status: validated
scope: global
domain: hermes
tags: [hermes, cli, config, argparse, batch-query]
triggers:
  - "想一次性核对多个 hermes 配置项（display.skin / display.sections.* 等）"
  - "hermes config get 打出 usage: hermes [-h] [--version] 而不是配置值（失败信号）"
  - "写脚本批量读取 hermes 配置做前后对照"
  - "改完一批 hermes config set 想逐项验证是否落盘"
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:1363c097-a1c9-4248-a903-814a33facb13
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [hermes-config-set-cannot-write-list-dict]
---
# `hermes config get` 一次只吃一个 key：多 key 会退化成顶层 usage 报错

## 主张
`hermes config get k1 k2 k3` **不是**批量查询——多余的位置参数会让 argparse 直接打印**顶层** `usage: hermes [-h] ...`
（不是 `hermes config` 的用法），看起来像 CLI 坏了或子命令不存在。
**要核对多项配置就 shell 循环逐个查**：`for k in a b c; do printf "%s = " "$k"; hermes config get "$k"; done`。

## 为什么
错误信息把作用域抬到了顶层解析器，完全不提"你多传了参数"，于是很容易改去查子命令名、版本、PATH，
而真正的原因只是"一次一个 key"。同一版本里 `hermes config set k v` 是接两个参数的，
两者参数元数不一致，进一步助长了"config get 也能接一串"的错觉。

## 证据（本会话命令对照）
- `hermes config get display.skin display.sections.thinking display.sections.tools display.show_commentary display.interface 2>&1 | head -20`
  → `usage: hermes [-h] [--version] [-z PROMPT] [--usage-file PATH] [-m MODEL] [--provider PROVIDER] [--reasoni...`
- 改为逐个查即成功：
  `for k in display.skin display.sections.thinking display.sections.tools display.show_commentary display.interface; do printf "%s = " "$k"; hermes config get "$k"; done`
  → `display.skin = claude-code` / `display.sections.thinking = collapsed` / `display.sections.tools = collapsed` / `display.show_comment...`
- 环境：`hermes --version` → `Hermes Agent v0.20.0 (2026.8.3)`，二进制 `/Users/zodyne/.local/bin/hermes`。

## 边界 / 反例
- 只在 v0.20.0 上验证；后续版本若支持多 key 需重新确认。
- `hermes config set` 的多值/list-dict 限制是另一条坑（见 related），不要混为一谈。
- 也可直接 `grep -A N "^display:" ~/.hermes/config.yaml` 读文件核对，但那读到的是磁盘值，
  不等于运行时解析后的生效值——需要"生效值"时仍应走 `config get`。

## 失败信号（未来命中即该想起本条）
- 任何 hermes 子命令打出的是**顶层** `usage: hermes [-h] [--version] ...`，先数自己传了几个位置参数。
- 2026-09-16 独立复验（交互模型，非原会话）：`hermes config get display.skin display.show_commentary` → 打印顶层 `usage: hermes [-h] ...`
