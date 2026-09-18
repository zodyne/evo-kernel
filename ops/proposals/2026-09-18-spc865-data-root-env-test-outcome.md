---
id: spc865-data-root-env-test-outcome
type: lesson
status: candidate
scope: project:spc865
domain: testing
tags: [spc865, pytest, env-var, data-root, baseline]
triggers:
  - "跑 spc865-adc 的 pytest，tests/test_io_reald.py 的数据盘点/规模断言红，先怀疑是不是自己改挂了"
  - "shell 里设了 SPC865_DATA_ROOT 再跑测试，或要验证默认数据集探测（暗箱优先）行为"
  - "同一套测试时红时绿，环境里残留着上一次实验用的 SPC865_DATA_ROOT（失败信号）"
  - "测试红在 test_default_dataset_probe_prefers_darkbox 或 test_expected_scale_of_the_repository"
  - "无显示器环境要验收 SPC865 数据探测链路，不确定该不该导出 SPC865_DATA_ROOT"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a977-6e7b-77c1-a593-51a2cfa0a8bf
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [spc865-full-suite-red-data-fixture-missing]
---
# SPC865_DATA_ROOT 指向哪个根，直接决定 spc865-adc 测试红还是绿

**主张**：`SPC865_DATA_ROOT` 不是无副作用的配置——它决定数据探测类用例看到哪个数据集。实测把 `SPC865_DATA_ROOT=/Users/zodyne/Dev/SPC865` 时 `python3 -m pytest tests` 红（`FAILED tests/test_io_reald...`，失败上下文里出现 `test_default_dataset_probe_prefers_darkbox`），`env -u SPC865_DATA_ROOT` 跑同一套件末行汇总以 `22` 开头（`--tb=line` 下无 FAILED 行，即通过）。因此这套测试的红/绿必须连环境变量一起报；验证「默认探测行为」时必须 unset，看到红先核对这个变量再怀疑代码回归。

**为什么**：该套件里有断言「默认数据集探测优先暗箱」的用例，以及写死规模的基线用例（`test_expected_scale_of_the_repository` 文档字符串：`实测规模基线：63 文件 / 1810 帧 / 3.7959 GB`）。一旦用环境变量指定了别的根，这些「默认值 / 固定规模」前提就不成立：同一个根下 `./spc865_ui.py --check` 实测只有 `42 个采集件 · 840 帧`，与 63/1810 对不上。红是数据根选择的结果，不是被测代码变了。

**证据（本会话命令 ↔ 结果）**
- `SPC865_DATA_ROOT=/Users/zodyne/Dev/SPC865 QT_QPA_PLATFORM=offscreen python3 -m pytest tests -q` → `exit=1`，`short test summary info ... FAILED tests/test_io_reald...`；失败上下文含 `data_root = PosixPath('/Users/zodyne/Dev/SPC865')` 与 `def test_default_dataset_probe_prefers_darkbox(data_root):`。
- `rg -n -A 30 'def test_expected_scale_of_the_repository' tests/test_io_reald.py` → 文档字符串 `实测规模基线：63 文件 / 1810 帧 / 3.7959 GB`。
- 同一根盘点：`./spc865_ui.py --check` → `[check] 数据集 /Users/zodyne/Dev/SPC865/MatlabSpc865/20260610 · 42 个采集件 · 840 帧`。
- 反面对照：`env -u SPC865_DATA_ROOT QT_QPA_PLATFORM=offscreen python3 -m pytest tests --tb=line 2>&1 | tail -4` → 末行汇总以 `22` 开头，无 FAILED 行。

**边界 / 反例**
- 本切片只证明「换根 → 结果不同」，没有逐条看到失败断言全文（tail 被截断），也没有证明 `/Users/zodyne/Dev/SPC865` 不是合法数据根——它可能只是不满足这组基线。
- 另一次 `SPC865_DATA_ROOT=/Users/zodyne/Dev/radar-data/spc865` 的运行切片里只剩一段 `RuntimeWarning`，结果未知，不能据此说它通过或失败。
- 数据源确实缺失/被移动时按 `spc865-full-suite-red-data-fixture-missing` 处理；真由本次 diff 引入的数据依赖仍按真回归处理。
