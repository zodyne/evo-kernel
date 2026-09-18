---
id: test-doc-name-hit-not-doc-read
type: lesson
status: candidate
scope: global
domain: documentation
tags: [grep, tests, doc-coupling, false-positive, ripgrep]
triggers:
  - "改 README/契约文档前，用 rg 找有没有测试引用该文档，命中了好几个测试文件"
  - "担心文档里的章节号/文件名被测试断言，不敢改"
  - "测试文件里出现的 .md 名字到底是『读文件』还是『路径字符串』分不清"
  - "grep 命中文件数被当成了耦合程度（失败信号：只看命中了几个文件）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a964-e50e-77c1-a593-51a129dcb579
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [doc-drift-fix-grep-by-concept, subagent-transcript-exec-vs-mention]
---

**主张**：`rg -ln "<文档名>" tests/` 命中若干测试文件，**不能**据此推断「改这篇文档会打断测试」——命中常常只是 `tmp_path / "report.md"` 这类默认输出文件名的字符串/路径断言。判断有无真耦合要看**命中的那一行长什么样**（是否真的对文档路径做 `read_text()` / `open()` / 解析章节），并据此决定改文档要不要同步改测试，而不是数命中了几个文件。

**为什么**：仓库里最常见的 `*.md` 字面量是测试自己的临时产物名（`report.md`、`out.md`），它在源文件里的出现与「测试读取被改的那篇文档」毫无关系；反过来也有真耦合（测试解析契约文档的章节号）。两种情况在「文件名命中」这一层完全同形，只有逐行看命中内容才能区分。本会话在改 README 与 `docs/SPC865_PYTHON_ARCHITECTURE.md` 前先做了这次区分，确认命中的是临时产物名断言后，直接改了文档（commit `fa674fe`，5 文件 +26/−23），没有为不存在的内容耦合做额外保守处理。

**边界**：这一步只回答「测试读没读该文档」；文档里被其它机制断言的内容（快照、章节号被脚本抽取）仍需各自核对。做过一次这条判断后，仓库若新增解析文档的测试，结论会过期——改文档前重跑同一对 grep 即可，成本是两条命令。

**证据**（session 01a0a964，evo slice「命令 ↔ 结果」）：
- 第一级（找提到文档的测试）：`rg -ln "SPC865_PYTHON_ARCHITECTURE|契约 §|docs/" tests/` → 命中 4+ 个测试文件（`tests/test_cli.py`、`tests/test_config.py`、`tests/test_dsp_baseline.py`、`tests/test_io_contract.py`…），表面上像"文档被测试引用"。
- 第二级（看是否真打开文档）：`rg -n "docs/|\.md\"|\.md'" tests/ | rg -v "^\S+:\s*#" | head -10` → 命中的行形如 `tests/test_cli.py:180: assert primary == tmp_path / "report.md"`，是临时输出路径断言，不是读文档。
- 结论落地：随后提交 `fa674fe` 直接改了 `README.md` 与 `docs/SPC865_PYTHON_ARCHITECTURE.md`（该 commit 5 files changed, 26 insertions(+), 23 deletions(-)）。
