---
id: paper-undefined-metrics-verify-in-official-code
type: lesson
status: candidate
scope: global
domain: research
tags: [paper-reading, metrics, official-code, experiment-coverage, rg]
triggers:
  - "论文用了正文没给定义的自定义指标，想知道它到底算什么"
  - "要核实论文声称的实验覆盖（验证集划分/真实数据/基准对比）是否真的做了"
  - "论文声称与配套开源代码对不上，要裁决以哪个为准"
  - "调研论文时正文只字未提某指标定义，搜不到出处（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0afd6-6cb7-764c-a77e-518272d0f753
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [arxiv-html-fulltext-grep-sed-eval-extraction]
---

读有配套开源代码的论文时，正文未定义的指标/流程以官方代码为裁决源；两步确定性核验：`rg -n "<指标名>" --type py` 定位实现读出定义；`rg -n -i "validation|val_split|holdout|real.?world|benchmark"` 清点实验覆盖是否真做。

为什么：论文正文常不写自定义指标定义（本篇 APEC/EEC 正文全篇未出现定义），代码是唯一可复核的事实源；正文对实验覆盖的描述可能稀疏到仅引言一句，rg 关键词清点能确定性地回答「做了没有」。

反例/边界：代码与正文冲突时记录差异，不默认代码正确；闭源/未发布代码此路径不可用。PDF 文本层先行 grep 关键词（validation/simulat/real-world 等）是低成本第一步，命中为空或仅引言命中即提示需转到代码核实。指标定义即使找到也可能只在注释里（本例在 `multi_subarrays_model.py:96` 的注释提及 ANEES/APEC/EEC），要继续追实际计算处。

证据：`rg -n "APEC|EEC|def .*apec|def .*eec" --type py -i .` → 仅 `src/multi_subarrays_model.py:96` 注释；`rg -n -i "validation|val_split|holdout"` → `src/training.py:278`、`trainer.py:151`（`val_len = int(len(full_ds) * args.val_split)`）；正文 pdftotext 后 grep validation/real-world/benchmark 命中稀疏。
