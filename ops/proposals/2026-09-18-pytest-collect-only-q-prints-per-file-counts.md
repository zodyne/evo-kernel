---
id: pytest-collect-only-q-prints-per-file-counts
type: lesson
status: candidate
scope: global
domain: python-testing
tags: [pytest, collect-only, test-count, nodeid, grep-exit-code]
triggers:
  - "用 pytest 统计仓库测试用例总数或按文件的用例分布"
  - "pytest --collect-only -q 输出里 grep '::' 命中 0 行、命令 exit 1（失败信号）"
  - "要写『共 N 个用例』但 N 来自对 --co 输出的 grep 计数"
  - "管道里 grep 无命中把整条 && 统计命令短路，误判成『测试没被收集』（失败信号）"
  - "--co 的输出只有 `tests/xxx.py: 13` 这类按文件汇总行，找不到逐条 nodeid"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a820-0f89-7719-ba82-3200eacbe826
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [unittest-discover-needs-importable-start-dir, verify-numbered-list-full-coverage-by-regex-count]
---

# `pytest -q --collect-only` 只输出「按文件汇总」的计数行，不是逐条 nodeid

## 主张

统计用例数时，`pytest -q --collect-only`（`--co`）打印的是每个测试文件**一行** `tests/python/test_x.py: 13`，没有 `path::test_name` 形式的 nodeid。沿用「grep '::' 数用例」的写法会 0 命中，而 grep 无命中返回 exit 1，串在 `&&` 链上还会把后续统计整段短路——表面现象是「收集到 0 个用例 / 测试没被发现」，与事实相反。按文件汇总行求和才是对的：

```
python3 -m pytest <dir> -q --collect-only 2>/dev/null \
  | grep -E '^tests/.*: [0-9]+$' | awk -F': ' '{s+=$2} END{print s}'
```

## 为什么

`-q` 把 collect 阶段压成「每文件计数」摘要：它优化的是人眼阅读，不是机器解析。于是「文件里明明有几百个用例」与「grep '::' 数出 0」同时成立；grep 的 exit 1 再与 `&&` 组合，会把「我 grep 错了」升级成「测试根本没被收集」这种方向完全错的结论。

## 证据（本会话命令 ↔ 结果）

- `python3 -m pytest tests/python -q --co 2>/dev/null | grep "::" | awk -F'::' '{print $1}' | sort | uniq -c | sort -rn && ...` → 打出 `=== 总数 === 0`，命令以 exit 1 结束（切片中标记为 ✗）：grep '::' 零命中。
- 同目录 `python3 -m pytest tests/python -q --co 2>/dev/null | tail -2` → 末行是 `tests/python/test_ui_widgets.py: 13`，即每文件一行的 `路径: 数量` 格式。
- 改为按文件行求和：`python3 -m pytest tests/python -q --co 2>/dev/null | grep -E "^tests/.*: [0-9]+$" | tee /tmp/collect.txt | awk -F': ' ...` → `TOTAL 273`。

## 反例 / 边界

- 格式取决于是否带 `-q`：需要逐条 nodeid 时不要加 `-q`，此时 `grep '::'` 才成立。拿不准就先 `| head -3` 看真实行格式再写统计，别按记忆写正则。
- `-q --co` 的行数是测试**文件**数，不是用例数；用 `wc -l` 代替求和同样会错。
- 统计脚本要容忍 grep 无命中：grep 找不到模式时 exit 1，不应让它决定整条命令的成败（本会话里就因此出现过一次 `✗`）。
