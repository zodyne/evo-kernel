---
id: spc865-full-suite-red-data-fixture-missing
type: lesson
status: candidate
scope: global
domain: testing
tags: [spc865, pytest, fixture, data-files, baseline-red, multi-lane]
triggers:
  - "跑全量 pytest 报 `assert <N> >= <N+1>` 这类数据盘点断言（失败信号）"
  - "测试用 `REPO_ROOT / 'TEST_*.bin'` 打开数据文件报 FileNotFoundError / No such file"
  - "多车道并行开发，全量套件红但本车道测试全绿，要判断是不是自己的回归"
  - "接手 SPC865 或类似带大体积 .bin 采集数据的仓库，收尾跑全量验收"
  - "数据文件全在采集子目录、仓库根一个都没有（`ls *.bin` 无输出，`find` 能数出几十个）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a810-9275-7719-ba82-31fb903a37e1
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [hardcoded-data-dir-rot-fails-late, vitest-full-suite-fail-isolate-rerun, spc865-data-root-env-test-outcome]
---
# 全量 pytest 红在数据文件盘点/路径断言 ≠ 本车道回归

## 主张
收尾跑全量套件，若红的是"数据文件清单/路径"类断言，先 `find`/`ls` 核对数据实际分布再归因，别先怀疑自己的改动。
本会话（SPC865 UI 面板车道，只新建了 `spc865/ui/views.py` 与 `tests/python/test_ui_views.py` 两个未追踪文件）
收尾 `pytest tests/python/` 红在 `tests/python/test_io_reald.py:64`：盘出的 `.bin` 是 62 个，断言要求 ≥63；
另一条 `tests/python/test_cache.py::test_file_key_is_absolute_path_string` 直接打开
`REPO_ROOT / "TEST_2021-12-07-04-17-38_2.bin"`，而仓库根目录一个 `.bin` 都没有——62 个全在采集子目录里。

## 为什么
这类失败与业务代码无关，是"数据存放位置/清单"与"测试期望"不一致造成的**既有红**。若不先核对数据实际分布，
容易把它当成自己改挂的回归，进而去改无关代码或伪造 fixture。多车道并行时更危险：每个车道都会看到同一片红，
各自误判的代价被放大。

## 证据（本会话命令 ↔ 结果）
- `QT_QPA_PLATFORM=offscreen python3 -m pytest tests/python/ -q 2>&1 | tail -8` →
  `E assert 62 >= 63` / `+ where 62 = len((BinFile('865_0801_2025-10-09-11-40-04_0.bin', size=209716000, frames...`
- `pytest tests/python/test_cache.py::test_file_key_is_absolute_path_string -q` →
  `> with BinFile.open_path(REPO_ROOT / "TEST_2021-12-07-04-17-38_2.bin") as bf:`
- `find . -path ./.git -prune -o -name '*.bin' -print | wc -l` → `62`；`ls data/*/` → `data/吸波材料/` 等子目录
- `ls -la *.bin` → `ls: *.bin: No such file or directory`；
  `find ... | head -5` → `./20251009_865单板暗箱角反AD数据采集/865_0801_2025-10-09-11-40-04_0.bin`
- 本会话写/改文件清单只有 `spc865/ui/views.py`、`tests/python/test_ui_views.py`（末条汇报均标记为新建 `??`）
- 车道内测试全绿：`pytest tests/python/test_ui_views.py -q` → `.................... [100%]`（20 pass）；
  跨车道 `test_ui_views.py + test_ui_widgets.py + ...` → 49 pass

## 边界 / 反例
- 本切片只证明"数据不在期望路径时该套件恒红"，**不证明**数据"应该"在根目录：可能是采集数据被归档/移动，
  也可能测试清单过时。不要据此删测试或造 fixture，先向仓库所有者确认数据布局。
- 若失败断言与本次 diff 相关（例如新测试引入了数据依赖），仍要按真回归处理，本条不豁免。
- 建议的收尾口径：车道测试全绿 + 全量红写明"既有失败 + 证据路径"，不要笼统写"全部通过"或"改坏了"。
- 另一条同症状的根因是环境变量：`SPC865_DATA_ROOT` 决定数据探测类用例看到哪个根——设成 `/Users/zodyne/Dev/SPC865` 时套件红（`test_default_dataset_probe_prefers_darkbox` / `test_expected_scale_of_the_repository`；换根后实测 42 采集件·840 帧 ≠ 基线 63 文件·1810 帧），`env -u SPC865_DATA_ROOT` 跑同一套件即绿（汇总以 `22` 开头、无 FAILED 行）；红/绿报告要连该变量一起写，验证「默认探测」行为前先 unset。

## 失败信号（未来命中即该想起本条）
- `assert 62 >= 63` 这种"差 1 个文件"的数据盘点断言，`ls` 显示期望位置根本没有文件。
- 全量红落在 `test_io_reald.py` / `test_cache.py` 这类数据/路径测试，而本车道只动了 UI 文件。
