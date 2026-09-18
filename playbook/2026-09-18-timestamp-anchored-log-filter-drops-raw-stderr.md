---
id: timestamp-anchored-log-filter-drops-raw-stderr
type: lesson
status: validated
scope: global
domain: log-forensics
tags: [log-parse, stderr, grep, time-window, false-negative]
triggers:
  - "按时间窗统计日志里的错误/异常条数，结果算出 0 条"
  - "日志里既有自带时间戳的行，也有子进程直接落盘的裸 stderr（失败信号：报错行的行首不是时间戳）"
  - "写看门狗/对账脚本过滤 distill.log 这类多写者 append 日志"
  - "用行首正则 `^\\S+Z` / `^\\d{4}-` 或 `awk '$0 >= \"日期\"'` 把日志按时间切片"
  - "报『窗口内无异常』之前，先确认过滤器没有按格式假设整批丢行"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b211-aaee-73b1-bdd8-c2cfeae4ad73
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [evo-distill-transient-connection-error-retry]
---

# 按行首时间戳过滤混合日志 = 静默丢光裸 stderr 行：窗口内"0 条异常"是假的

## 主张

当日志文件里混着两类行——**应用自己写的带时间戳行**与**子进程 stderr 直接 append 的裸行**（shell 不会给它加时间戳）——用"行首时间戳正则 + 时间窗"做过滤，会把裸行**整批丢掉**且不报错：统计结果是 0 条异常，而文件里确有错误。正确顺序是**先按内容 grep**，再用"最近一条带时间戳的行"给裸行定归属；直接用格式假设（`^(\S+Z) `、`^(\d{4}-\d{2}-\d{2}T)`、`awk '$0 >= \"2026-…\"'`）当过滤器就是假阴性的来源。

## 证据（本会话，同一文件、同一时间窗，脚本改前/改后对照）

被过滤的窗口是 `ops/log/distill.log` 里 `>= 2026-09-18T01:05:29Z` 的部分。

1. **改前**（锚定行首时间戳）：统计脚本里写 `if p in ln and re.match(r'^(\S+Z) ', ln) and ts(...) >= ERA1`，输出
   `=== 8. anomalies inside window (>=01:05:29Z) ===` → `command not found: 0`、`syntax error: 0`、`锁路径被非目录占用: 0` …（全是 0）。
2. **改后**（按内容找 + 用上一条带时间戳的行做归属）：

```
721 | .../evo-distill.sh: line 276: rintf: command not found | [after 720:2026-09-18T01:42:39Z done 01a0afd6-6cb7-]
722 | .../evo-distill.sh: line 279: syntax error near unexpected token `else' | [after 720:...]
729 | .../evo-distill.sh: line 276: rintf: command not found | [after 728:2026-09-18T01:49:20Z done 01a0affb-58dd-]
730 | .../evo-distill.sh: line 279: syntax error near unexpected token `else' | [after 728:...]
763-779 | .../evo-distill.sh: line 242: 2026-09-18-foo-bar.md / id: / lesson-YYYY-MM-DD-001: command not found | [after 762:03:25:31Z start 01a0a7ad-67d6]
```

   同一窗口内实际 8 行，全部是**行首不带时间戳的裸 stderr**（由 `evo-distill.sh` 的 `bash` 子进程直接写进日志），所以 1 里的过滤器把它们丢了个干净。
3. 该错误当场被自查抓到（"my regex requiring a timestamp failed"），最终交付报告里的数字取自改后的统计：`command not found = 8`，不是 0。

## 边界 / 反例

- 若日志所有行都带时间戳（或裸行确实与本窗口无关），锚定过滤没问题——**先确认格式假设是否覆盖所有写者**再信计数。
- `awk '$0 >= "2026-09-18T01:05:00Z"'` 这类字符串比较会把裸行全部排在**最前面**（它们不以数字/时间戳开头），既漏真错误又可能把早期裸行算进窗口。
- 用"上一条带时间戳的行"给裸行定归属是**按文件顺序近似时间顺序**的启发式：并发多 worker 写同一日志时，归属只到"该时间点附近"，不能当毫秒级证据。

## 失败信号（未来命中即该想起本条）

- 一句话结论是"窗口内 0 条异常/0 条 fail"，但肉眼 `rg` 该文件明明能看到报错行。
- 过滤脚本里出现 `^(\S+Z) `、`re.match(r'^...')`、`awk '$0 >= "…"'` 这类按键首格式切的写法。
- 报错行的行首是 `line 276:`、脚本路径、或别的不像时间戳的东西。
