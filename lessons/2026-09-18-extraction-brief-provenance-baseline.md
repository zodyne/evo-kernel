---
id: extraction-brief-provenance-baseline
type: lesson
status: candidate
scope: global
domain: document-processing
tags: [pdf, provenance, sha256, extraction, reproducibility]
triggers:
  - "从 PDF/文档抽取规格、结论，产出给别人或下游任务用的简报/摘录（extraction brief）"
  - "同一份文档在仓库两个目录各存一份，抽取前要定哪一份是抽取基线"
  - "下游复核简报时问『这条结论基于哪一版文档』，却只有文件名、没有 hash（失败信号）"
  - "简报写了「如何复现（how to reproduce）」却只列文件名，没写 SHA-256 与提取命令"
  - "要引用文档内容做权威规格，但拿不准手上这份副本有没有漂移"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7de-9a4d-7719-ba82-31f03c7dd2a5
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pdftotext-md5-roundtrip-verify-corpus-integrity, dual-repo-copy-drift-fails-golden-first-diff, spc865-top-level-shadow-copies]
---

# 抽取类产出物要带可复现 provenance：源文件 SHA-256 + 提取命令

## 主张

从文档抽取规格/结论时，先把「抽取基线」用 SHA-256 钉住（同一文档的多处副本要逐字节一致），再把基线与提取命令写进产出物的第 0 节（provenance / how to reproduce）。只写文件名不足以让下游判断这条结论基于哪一版字节。

## 为什么

抽取类产出物（规格简报、摘录、对账表）的价值全在「下游敢不敢照它写代码」。同一份文档常常在仓库里有多处副本（顶层 `docs/` 与 `MatlabSpc865/docs/`、或「报告目录 + 模板目录」），副本一旦漂移，从文件名上看不出来；PDF 文件名带的是生成时间戳，也不等于内容版本。`shasum -a 256` 把「我读的是哪份字节」变成可复核的一行字，成本一次命令；反之，下游后来发现结论与手上文档对不上时，没有任何手段回溯是读错了版本还是文档本身写了这个。

## 证据（切片命令 ↔ 结果）

- `cd /Users/zodyne/Dev/SPC865 && echo "=== ROOT docs ===" && shasum -a 256 docs/*.pdf && echo "=== MatlabSpc865/docs ===" && ls -la MatlabSpc865/docs/ ...`
  → `=== ROOT docs === f1ec8408a91e778a1ecf0bb3c74e40415a5aa53b3c4d0f0e9d64421b729185e0  docs/20240725113326-spc865_matlab.pd…`
  （对两处文档树同时取证：ROOT 侧出 hash，子目录侧列目录，用于判定副本关系）
- 末条 assistant 产出的简报第 0 节逐字为：`## 0. Extraction provenance (how to reproduce)`，其下第一行：`**Copies verified byte-identical** (SHA-256, both pairs):`
  ——产出物把「副本逐字节一致」和 SHA-256 写进抬头，供下游复现。
- 该会话「写/改文件」段为空：以上均为只读命令，provenance 是产出物自身的一部分，不是对仓库的改动。

## 边界 / 反例

- hash 只钉住「我读的是这份字节」，**不**证明这份文档是最新版或内容正确；「哪一版是权威」要靠引用关系/文档指向另判（参见 `dual-repo-copy-drift-fails-golden-first-diff`、`spc865-top-level-shadow-copies`）。
- 副本 hash 不一致时不能随手挑一份继续抽：先定权威副本再抽，否则结论挂在已漂移的那份上。
- 提取命令要写到能复跑（工具 + 参数），写「用 PyMuPDF 抽的」等于没写；只给文件名更是把版本判断推给下游。
- 对内容本身有疑问时，hash 帮不上忙——那是 `pdftotext-md5-roundtrip-verify-corpus-integrity`（重抽取比对确认语料完整）的领域。
