---
id: rebuild-pdf-verify-against-head-version
type: lesson
status: validated
scope: global
domain: documentation
tags: [pdf, rebuild, artifact-verification, git-show, pdftotext, pdfinfo, doc-drift]
triggers:
  - "准备 git add 一个刚重建的 PDF / 二进制产物，说不清它和上一版差在哪"
  - "重建文档产物后要确认没有夹带静默损坏（未解析引用、丢图、页数漂移）"
  - "产物里的图/正文与源文件矛盾，怀疑 PDF 与 .tex 已经脱节"
  - "二进制产物 git diff 看不到内容变化，需要一个可复核的对拍办法"
  - "提交前想证明『这次重建只改了该改的地方』"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2d9-e94b-7323-8254-c19b2aefb87d
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [docx-embedded-figure-stale-vs-source-rerender]
---

# 重建 PDF 前先把 HEAD 里的旧产物取出来对拍：页数 + 抽文本，再溯源每处差异

## 主张
重建派生文档产物（PDF 等二进制）准备提交时，先用 `git show HEAD:docs/<f>.pdf > /tmp/old.pdf` 把上一版取出来，与新产物对拍**页数**（`pdfinfo`）和**抽取文本**（`pdftotext` + diff/grep），并对每处差异溯源到源文件改动：`git log -1 --format=%H -- <pdf>` 拿到上一次产物被改写的提交，再 `git diff <那个 sha>..HEAD -- <源 .tex>`。二进制 diff 看不见内容变化，这一步是唯一能回答"这次重建到底改了什么、有没有夹带"的手段。

## 为什么
`git diff` / `git add` 对 PDF 只说"Binary files differ"，而"重建了所以重新提交"恰恰最容易夹带静默损坏（未解析引用、丢图、页数漂移）。把旧产物取出来抽文本对拍，成本一条命令，却能同时回答两个问题：**产物本身好不好**（本次就是靠它抓到 `??`），以及**产物是否已经与源脱节**（上次构建之后源文件有没有再被改过）。

## 证据（session 01a0b2d9，suc221-pointcloud-2.0）
- 取旧版对拍：`for f in pointcloud_filter_theory dbf_filter_spec dbf_algorithm_design; do git show HEAD:docs/$f.pdf > /tmp/…; done` 配合 `pdfinfo` → `pointcloud_filter_theory: HEAD 29 页 -> 现在 30 页`、`dbf_filter_spec: 21 页 -> 21 页`、`dbf_algorithm_design: 23 页 -> 23 页`。
- 抽文本抓到坏产物：新 PDF 文本 `grep -an '??' /tmp/theory.txt` → `1468:剪枝，而是第二个判别器，见 ??。`；旧 PDF 无 `??` —— 这条差异直接指出重建引入了一处未解析引用（见 `latex-cross-doc-label-renders-question-marks`）。
- 溯源到源文件：`for f in dbf_filter_spec dbf_algorithm_design pointcloud_filter_theory; do … git log -1 … -- docs/$f.pdf; git log -1 … -- docs/$f.tex`（输出形如 `--- dbf_filter_spec --- pdf 构建提交 900028a … / tex 最后改动 6fcf8bb …`）用来量"产物落后源文件多久"；再用 `git diff $(git log -1 --format=%H -- docs/pointcloud_filter_theory.pdf)..HEAD -- docs/pointcloud_filter_theory.tex` 判断页数变化是本次引入的还是产物早就与源脱节。
- 对拍之后才入库：`git add docs/dbf_algorithm_design.pdf docs/dbf_filter_spec.pdf …`。
- 没变的那两份也留了证：21→21、23→23 同样取旧版比过，不是只挑变化的看。

## 边界 / 反例
- **页数相同 ≠ 内容相同**：本次 21/23 页两份页数没变，仍要靠源 `.tex` 的 diff 判断有没有实质改动。
- **页数不同 ≠ 有错**：新增章节、改字号都会变页数——对拍目的是"每处差异都能溯源"，不是"必须一致"。
- 适用于任何"源文件 + 提交进仓库的二进制产物"（PDF / 图 / 数据表）；纯文本产物用 `git diff` 本身即可。
- `git log -1 -- <pdf>` 给的是最后一次**产物被改写**的提交，未必等于下次构建的基线（若 PDF 与源文件在同一提交里混着改）；此时以源文件 diff 为准。
- 抽文本只能看见文本层：纯图形差异（丢图、图被换）要靠页数、图计数或渲染比对补上。
- **产物根本不在 git 里时（周报/周期报表，每期一个新文件），没有 HEAD 版可取**：基线换成**上一期那份产物文件**，对拍手段也换成领域解析器 —— xlsx 用 openpyxl 逐项读回 sheet 名 / dims / 合并区 / 字体 / 表头 / 单元格文本 / 行高 / max_row，问的是跨期漂移而不是「相对 HEAD 改了什么」；此时生成器自己打印的 `✅ 已生成 / Sheet 1: N 项` 只证明它跑通，不是产物正确的证据。

## 失败信号（未来命中即该想起本条）
- 准备 `git add` 一个刚重建的 PDF/二进制产物，却说不清它和上一版的差别。
- 产物里出现 `??`、缺图、页数骤变，没人能说出是哪次改动引入的。
- 文档目录里 PDF 的上次构建提交明显早于 `.tex` 的最后改动提交（产物与源脱节）。
