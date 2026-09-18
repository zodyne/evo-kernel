---
id: pytest-qq-suppresses-passed-summary
type: lesson
status: validated
scope: global
domain: python-testing
tags: [pytest, quiet, addopts, exit-code, output-parsing]
triggers:
  - '仓库里 pyproject.toml / pytest.ini 已设 addopts = "-q"，命令行又手写 pytest -q'
  - "pytest -q | grep -E 'passed|failed' 或 | tail 拿不到 N passed 汇总行（失败信号）"
  - "用输出里有没有 passed 字眼来判断测试过没过"
  - "pytest -q > log 2>&1 后日志只剩进度点、没有结论行，怀疑测试没跑完"
  - "后台/批处理脚本里收集 pytest 结果做验收门禁"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a80b-0eeb-7719-ba82-31f86fbaeaa7
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [selftest-pass-count-not-a-gate-exit-code-decides]
---

# `-q` 叠加成 `-qq` 后 pytest 不再打印 "N passed" 汇总行：判定成败只能用退出码

**主张**：当仓库配置（`pyproject.toml` 的 `[tool.pytest.ini_options] addopts = "-q"`，或 `pytest.ini` 的 `[pytest] addopts = -q`）里已经带了 `-q`，命令行再写一次 `pytest -q`，两次叠加成 verbosity `-2`（`-qq`）——pytest **不再输出 `N passed in Xs` 汇总行**，输出只剩进度点和 `[100%]`。此时 `| grep -E "passed|failed"`、`| tail -N` 都会拿到空结果或无关行，容易被误判成"测试没跑""测试没通过"。**判定成败要用退出码（rc=0 才是通过），不要 grep 汇总行。**

**为什么**：`-q` 是递增开关，重复一次就再降一级 verbosity；抑制汇总行是 `-qq` 的既定行为，不报错也不警告。而 `grep passed` 这类判定在 verbosity ≥ -1 时工作良好，于是这个坑只在"配置里已有 -q + 命令里再写 -q"的组合下出现——恰恰是最像"没问题"的组合，排查时会先去怀疑测试没跑完、输出被缓冲等错误方向。

**证据（会话 01a0a80b 命令 ↔ 结果；该仓库 pyproject.toml 里 `addopts = "-q"`）**：
- 同一收尾命令、仅差命令行 `-q`：
  `python3 -m pytest tests/python -q 2>&1 | grep -E "passed|failed" | tail -2` → **无任何输出**；
  紧随其后的 `python3 -m pytest tests/python/test_cli.py 2>&1 | grep -E "passed|failed" | tail -2`（不写 `-q`）→ `10 passed in 0.74s`。
- 重定向留档同样丢汇总行：
  `python3 -m pytest tests/python -q > /tmp/full.txt 2>&1; echo "rc=$?"; tail -4 /tmp/full.txt` → `rc=0` + 4 行进度点；
  `wc -l /tmp/full.txt` → `4`，文件里没有 "220 passed"。
- 去掉命令行的 `-q` 才看到结论行：`python3 -m pytest tests/python 2>&1 | tail -3` → `220 passed in 2.68s`（`rc=0`）。
- 本机复验（pytest 9.0.2，2026-09-18，临时项目 `[pytest] addopts = -q`，2 个测试）：
  只留 addopts → `..  [100%]` + `2 passed in 0.00s`；
  addopts + 命令行 `-q` → 只有 `..  [100%]`（无汇总行）；
  两种情况退出码均为 0；`-o addopts= -q` 可中和配置里的 `-q`，汇总行立刻回来。

**边界 / 反例**：
- `-qq` 只吞汇总行，**不吞退出码**：rc 仍正确反映成败，所以门禁脚本用 rc 判定不受影响，受影响的只有"读日志找 passed"的写法。
- 其它会改输出形态的开关（`--tb=no`、`-rN`、插件静默）同样能让基于文本的判定失效；文本判定天然脆，退出码 / `--junitxml` 才是稳定接口。
- 确实需要人读汇总行时：不要再传 `-q`，或显式 `pytest -o addopts= -q`。
- 同族变形：`pytest -q --collect-only` 输出的是**每文件汇总行**（`tests/x.py: 13`）而非逐条 nodeid，沿用 `grep '::'` 数用例会 0 命中；grep 无命中返回 exit 1，串在 `&&` 链上还会把后续统计整段短路，表象是「收集到 0 个用例」——按 `^tests/.*: [0-9]+$` 求和才对（本例 `TOTAL 273`）。

**失败信号（未来命中即该想起本条）**：pytest 明明通过，`grep passed` 却是空、日志末尾只有 `[100%]`；或"同一个测试目录，命令里多写了个 `-q` 就看不到 'N passed'"。
