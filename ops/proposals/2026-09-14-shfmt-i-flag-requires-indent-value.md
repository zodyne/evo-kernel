---
id: shfmt-i-flag-requires-indent-value
type: lesson
status: candidate
scope: global
domain: cli-tools
tags: [shfmt, conform, nvim, formatter, silent-failure, flag-parsing]
triggers:
  - "配置 conform.nvim 的 shfmt formatter 参数（args / prepend_args）"
  - "shell 文件保存后格式化没生效、无任何报错（失败信号）"
  - "shfmt 报 invalid value for flag -i: parse error"
  - "给 CLI 传一个带值 flag（如 -i）后又紧跟另一个 flag"
  - "formatter 参数错但 conform 的 notify_on_error 也没弹"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a09f21-f8b1-74d6-aeb7-1ea7a469056d
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
---

# shfmt 的 -i 是带值 flag，裸 -i 后接别的 flag 会被吞作它的值导致 parse error

## 主张

shfmt 的 `-i`（indent）是带值 flag，必须写成 `-i 2` 或 `-i=2`。在 conform.nvim 的 formatter args 里写裸 `-i -ci -sr`（`-i` 后紧跟另一个 flag），shfmt 会把 `-ci` 当成 `-i` 的值，报 `invalid value "-ci" for flag -i: parse error`，于是 shell 文件保存时的格式化每次都失败。

## 实例

审计一份 nvim 配置时，`lua/configs/conform.lua:115` 的 shfmt formatter args 是 `-i -ci -sr`。实测：

```
$ printf 'if true; then echo x; fi\n' | /Users/zodyne/.local/share/nvim/mason/bin/shfmt -i -ci -sr; echo "exit=$?"
  ↳ invalid value "-ci" for flag -i: parse error
    usage: shfmt [flags] [path] ...
```

因为 `-i` 需要一个缩进宽度值，紧跟其后的 `-ci` 被吞作 `-i` 的值，解析直接失败。审计报告据此判为「shell 保存格式化每次静默失败」（`lua/configs/conform.lua:115`）。

## 为什么

CLI flag 解析里，带值 flag 的参数会无条件吃掉下一个 token，哪怕它以 `-` 开头（shfmt 这里直接报 parse error，而不是跳过）。formatter 配置是「写一次、以后每次保存都跑」，参数写错不会在配置加载时报错，而是在每次运行时才暴露，且被 conform 吞掉后往往没有明显提示 —— 属于「配置里埋雷、保存时静默失效」一类问题。

## 规则

①给带值 flag 配参数时显式赋值（`-i 2` / `-i=2`），不要裸写 flag 名后再接其它 flag；②怀疑 formatter 参数时，直接手工跑一遍该 formatter 的完整 args（`printf '...' | <formatter> <args>`）看是否 parse error，而不是只看 conform 有没有报错；③conform 的 `notify_on_error` 未必能兜住「formatter 自身参数解析失败」这种错误，别把它当唯一信号。
