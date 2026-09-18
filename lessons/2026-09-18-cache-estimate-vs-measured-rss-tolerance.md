---
id: cache-estimate-vs-measured-rss-tolerance
type: lesson
status: candidate
scope: global
domain: testing
tags: [memory, cache, rss, pytest, tolerance, measurement]
triggers:
  - "内存缓存把 approx_mb 这类理论字节估算与实测 RSS 增量对账"
  - "写『理论估算 == 实测 RSS』的等值断言，同机重跑一次绿一次红（失败信号）"
  - "给缓存定 max_entries / 条目上限，要核算总内存预算"
  - "pytest -s 打印的实测内存值每次都不同，怀疑是噪声还是算错"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a810-92bd-7719-ba82-31fded52f86a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [lesson-2026-09-18-frame-scrub-bounded-cache-plus-live-edge, dual-impl-cross-check-tolerance-grid-anchored]
---

# 理论内存估算 vs 实测 RSS 增量：判据必须是容差带，不能等值

给内存缓存写"占用统计对不对"的回归时，`stats()["approx_mb"]`（按数组字节数算出的理论值）与"实测 RSS 增量"是**两个口径**：理论值在同一进程里恒定，实测值每次运行都在抖，且系统性低于理论值。因此对账判据只能用容差带（或只断上界），用等值断言会随机红。

## 为什么

`approx_mb` 是"我申请了多少字节"的确定性求和；RSS 是"操作系统此刻为我驻留了多少页"，受分配器复用、惰性缺页、页面回收、进程里既有空闲页的影响，既不等于申请量也不可复现。两个量口径不同，差值不是 bug，是测量属性。

## 证据（切片命令 ↔ 结果）

- 单条缓存的理论估算：`python3 -c "... FrameCache ..."` ↳ `stats {'hits': 0, 'misses': 1, 'entries': 1, 'approx_mb': 25.95}`。
- 条目上限：`grep -n "^class FrameCache\|..." spc865/cache.py` ↳ `spc865/cache.py:92:DEFAULT_MAX_ENTRIES: Final[int] = 8`；8 × 25.95 ≈ 207.6，与下文的 `approx_mb=207.62` 自洽。
- 该用例确实一度不成立：`python3 -m pytest tests/python/test_cache.py -q 2>&1 | tail -40` ↳ 输出里回显出 `def test_approx_mb_matches_measured_rss(darkbox_file: Path) -> None:` 与 docstring `"""``stats()["approx_mb"]`` 必须与实测 RSS 增量`；紧接着一条命令是对 `tests/python/test_cache.py` 做脚本化文本替换（↳ `ok`），此后该用例在所有运行中均通过。
- 同机同用例、同 `entries=8`、理论值恒为 `207.62`，实测 RSS 增量四次为 **187.7 / 187.9 / 197.6 / 187.9 MB**：
  - `pytest tests/python/test_cache.py -q -s` ↳ `[实测] entries=8 approx_mb=207.62 rss_delta_mb=187.7`
  - `pytest tests/python/test_cache.py tests/python/test_ui_params.py -q -s` ↳ `rss_delta_mb=187.9`，其后两次分别为 `rss_delta_mb=197.6`、`rss_delta_mb=187.9`；收尾 `26 passed in 1.42s`。

即：实测抖动幅度 187.7→197.6 MB（≈5%），理论值高出实测 ≈10%。等值断言必然脆弱。

## 怎么做

1. 断言写成容差带：`abs(approx_mb - rss_delta_mb) / approx_mb <= 阈值`（本会话未取证实际阈值，需按本机实测重新标定），或退一步只断"实测不超过理论值的某个上界"。
2. 用 `pytest -s` 把 `entries / approx_mb / rss_delta_mb` 打出来（本会话即如此），按多次运行取 min–max 来定容差，而不是看一次结果拍数。
3. 想要确定性的断言，就换成同口径的量（如 `len(cache)`、理论字节数本身），别拿 RSS 当确定性基准。

## 边界 / 反例

- 本条只针对**跨口径对账**（申请字节数 vs RSS）。同一口径内的确定性数值仍应精确断言，不要借本条放宽。
- RSS 抖动幅度随分配规模、机器负载、解释器版本变化；±% 阈值必须本机重测，不可照抄。
- 切片只证明"两者不等且实测会抖"，**未证明**落盘断言里最终用的是比例容差还是上界（断言体不在切片内）；不得据此断言具体阈值或实现细节。
- 也不证明"理论估算不准"：10% 的差可由惰性缺页/复用页解释，本条不主张任何一方算错。

## 失败信号（未来命中即该想起本条）

- 同一台机器、同一用例，`pytest` 重跑一次通过一次失败，而改动与内存无关。
- 日志里理论值恒定（如 `approx_mb=207.62`），实测列每次不同（187.7 / 187.9 / 197.6 …）。
- 有人准备用"实测 RSS 增量"给缓存占用做精确回归基准。
