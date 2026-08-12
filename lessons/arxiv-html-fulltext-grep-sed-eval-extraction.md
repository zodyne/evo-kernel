---
id: arxiv-html-fulltext-grep-sed-eval-extraction
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [arxiv, paper-research, curl, grep, sed, cli-pipeline]
triggers:
  - "要从 arXiv 论文里提取评测表格数字/对比指标做调研结论"
  - "调研某个模型/方法，需要论文一手数据而不是二手报道"
  - "不开浏览器、不解析 PDF 也要读 arXiv 论文全文"
  - "论文 HTML 转纯文本后不知道评测表格在哪一节"
  - "sed -n 按行段窗口读 grep 定位到的表格区"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fb0d4-b699-774f-a106-c2dc31be5dfc
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [arxiv-download-proxy-truncation, unverified-arxiv-ids]
---
# 提取 arXiv 论文评测数据：curl 抓 arxiv.org/html/<id> 全文 HTML → python 转纯文本 → grep 关键词定位行号 → sed 行段窗口读表格，纯 CLI 可行

## 主张
调研论文的评测结论时，arXiv 有 HTML 全文版（`https://arxiv.org/html/<id>`，可带版本号如 `v2`），用 `curl -sL` 直接抓取，python（re/html）转纯文本后，`grep -n -i -E "<评测关键词>"` 定位小节与表格行号，再 `sed -n 'a,bp'` 按行段窗口读出表格数字——全程不需要浏览器、不需要 PDF 解析，就能拿到带出处的一手对比指标支撑结论。

## 为什么
PDF 解析重且常缺工具，浏览器人工读长文慢；HTML 全文 + grep/sed 的定位-开窗组合把"读论文"变成可复现的命令序列：grep 给行号（证据可指认），sed 只取所需窗口（不占上下文）。关键词要面向评测语义选（human eval / compile / pass@ / reward / success rate / 对比模型名），而不是泛词。同会话还可配合直取 HuggingFace 模型卡原文（`https://huggingface.co/<org>/<model>/raw/main/README.md`）做交叉验证。

## 证据（本会话切片硬证据）
- `curl -sL "https://arxiv.org/html/2603.03072v2" -o /tmp/tikzilla.html && wc -c` → 1126633 字节；python re/html 转纯文本 → 131301 字符（命令↔结果对 #1）。
- `grep -n -i -E "human eval|compile|GPT-4o|GPT-5|reward|GRPO|pass@|success rate|3\.40|image-based|text-based" /tmp/tikzilla.txt` → 命中行 32/41/47/62/72（Rewards、Human Evaluation、Reward Model Training 等小节）（#3）。
- `sed -n '240,300p'` → 定位到 "Table 3: Results of all models on the evaluation subset of DaTikZ-V4"（#4）；`sed -n '300,360p'; sed -n '480,530p'` → 读出 Qwen2.5-3B、TikZilla-3B 等行的具体指标（52%、98% 等）（#5）。
- 末条 assistant 结论引用的数字与上述表格行一致——证据链闭合：命令 → 定位 → 读数 → 结论。
- 旁证：`curl -sL "https://huggingface.co/nllg/TikZilla-3B-RL/raw/main/README.md"` → 2505 字节，含 license/base_model/pipeline_tag frontmatter（#2）。

## 边界 / 反例
- 仅适用于有 HTML 版的 arXiv 论文（较新论文一般有）；只有 PDF 的老论文不适用，且大 PDF 经代理 curl 有截断坑（见 related arxiv-download-proxy-truncation）。
- 使用前验证 arXiv id 真实性，不凭记忆引文献（见 related unverified-arxiv-ids）。
- grep 命中的只是行号附近片段，表格跨页/跨行结构复杂时仍需开窗确认上下文，不能把单行命中当结论。
- 结论转写进报告时数字要回指表格原文，防止转录错误。

## 失败信号（未来命中即该想起本条）
- 为了几个评测数字去开浏览器翻十几页 PDF，或试图 pip 装 PDF 解析库。
- grep 用泛词（如 "result"、"table"）命中几百行，定位失败——换评测语义关键词。
- 结论里出现"据说/据传"的指标而给不出表格行号出处。
