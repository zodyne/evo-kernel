---
id: regenerated-pdf-normalized-streams-metadata-only-diff
type: lesson
status: validated
scope: global
domain: reproducible-build
tags: [pdf, metadata, reproducible-build, git-diff, artifact-verification, matplotlib]
triggers:
  - "重跑绘图/构建脚本后，已提交的 PDF 产物在 git diff 里显示变化"
  - "git diff --stat 报 Bin X -> X bytes（大小一模一样），判断不了内容改没改"
  - "准备 git add 一批重新生成的 PDF/图，想先分清内容变更与元数据噪声"
  - "每次重生成都留下一批二进制产物 diff，提交范围被噪声污染"
  - "纯图形 PDF 没有文本层，pdftotext 对拍用不上"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bcf1-4733-7265-ada1-fb36116f6be1
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [rebuild-pdf-verify-against-head-version, commit-reproducible-artifacts-verify-determinism]
---

# 重生成的 PDF 只有元数据差异：解压流归一化对拍后直接 git checkout 丢弃

## 主张

重跑绘图/构建脚本后，已提交的 PDF 产物在 `git diff --stat` 里显示 `Bin N -> N bytes`（大小一模一样）时，先做"解压内容流归一化对拍"：本例 4 张 `spec_*.pdf` 全部 `norm-equal=True`，说明差异只是元数据（时间戳/ID）——直接 `git checkout -- docs/design_bf/fig/` 丢弃这批重建，不提交。

## 为什么

PDF 内嵌 CreationDate/ModDate、文件 ID 等元数据，每次重生成字节都不同；`git diff` 对 PDF 只报 `Bin` 变化，看起来像内容改了。这批图是纯图形（无文本层），`pdftotext` 级别的对拍用不上，只能把 PDF 解压、归一化后逐流比。判定为元数据差异后把产物留在工作区只会让提交范围里多出无意义的二进制变更。

## 证据（session 01a0bcf1，suc221-pointcloud-2.0）

- 重生成：`time python3 docs/design_bf/make_spec_assets.py` → 重新写出 `docs/design_bf/fig/spec_*.pdf`。
- diff 噪声：`git diff --stat -- docs/design_bf/fig/` → `docs/design_bf/fig/spec_array.pdf | Bin 35633 -> 35633 bytes`、`spec_budget.pdf | Bin 29935 -> 29935 bytes` …（每张大小相同）。
- 归一化对拍：一段 python（解压 PDF 内容流后比较）→ `spec_array sizes 35633/35633 norm-equal=True`、`spec_budget sizes 29935/29935 norm-equal=True`、`spec_decision …`（被测文件全部 norm-equal）。
- 处置：`git checkout -- docs/design_bf/fig/ && git status --short` → 工作区不再有 fig/ 变更（只剩真正改动的 `.py` 与新增 `gt_masks.py`）。

## 边界 / 反例

- `norm-equal=True` 只覆盖本次比过的 4 张图；"元数据差异"要逐文件判，别外推到没比过的产物。
- 归一化方式要匹配 PDF 结构（对象流/压缩流解压）；图形对象编号、流顺序变化可能让朴素比较失败，此时不能直接判"内容变了"。
- 若规范化后仍不等，说明有真实内容差异，转 `rebuild-pdf-verify-against-head-version` 的页数 + 抽文本溯源流程。
- 丢弃前确认没有下游依赖这次重建（本例产物只在仓库内消费）。

## 失败信号（未来命中即该想起本条）

- git diff 看到 `Bin X -> X bytes`（大小不变），人直接判"没变"或"变了"而不做内容对拍。
- 每轮重跑生成器都产生同一批二进制产物的 diff，提交历史被元数据波动刷屏。

## 2026-09-22 独立复核增补

下列是复核时在本机跑过的**自包含最小复现**：

```
python3 - <<'PY'
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt, os, time, zlib, re
def make(p):
    fig, ax = plt.subplots(); ax.plot([1,2,3],[2,1,3]); fig.savefig(p); plt.close(fig)
def streams(p):
    raw = open(p,"rb").read(); out=[]
    for m in re.finditer(rb"stream\r?\n", raw):
        try: out.append(zlib.decompress(raw[m.end():raw.find(b"endstream", m.end())].rstrip(b"\r\n")))
        except Exception: pass
    return out
make("/tmp/a.pdf"); time.sleep(1.1); make("/tmp/b.pdf")
raw=lambda p: open(p,"rb").read()
print("size", os.path.getsize("/tmp/a.pdf"), os.path.getsize("/tmp/b.pdf"),
      "| nstreams", len(streams("/tmp/a.pdf")),
      "| streams-equal", streams("/tmp/a.pdf")==streams("/tmp/b.pdf"),
      "| bytes-differ", raw("/tmp/a.pdf")!=raw("/tmp/b.pdf"))
PY
# 实跑输出（本机 mpl 3.10.7 / py 3.14.7）：
# size 5630 5630 | nstreams 8 | streams-equal True | bytes-differ True
# 差异落点已定位到唯一一处 /CreationDate (D:2026...)，即元数据。
# 配套：git add /tmp/a.pdf && commit 后重生成，git diff --stat -- a.pdf 打印
#   a.pdf | Bin 5630 -> 5630 bytes
# 与条目 31633/29935 那批的 `Bin N -> N bytes` 形态完全同型。
```


**审核给出的修改意见（要点）**：「为什么」节里两句与产物不符，须改后再考虑升注入集：(1) 删掉或改写「这批图是纯图形（无文本层），`pdftotext` 级别的对拍用不上」——本机该仓 docs/design_bf/ 下 7 个 spec_*.pdf 实测都有可抽取文本层（pdftotext 各抽出 175–898 字符），且生成器 make_spec_assets.py 大量用 ax.text/set_title/set_xlabel（含中文），此断言为假。(2) 随之把「只能把 PDF 解压、归一化后逐流比」改成「更严格的作法是解压归一化逐流比（pdftotext 可作廉价旁证但不保证覆盖）」。核心主张（重生成的 PDF 大小不变、字节不同、内容流归一化后相等 ⇒ 判元数据噪声 ⇒ git checkout 丢弃）经独立最小复现证实，可保留；另建议在证据节注明归一化脚本是 heredoc、切片未留全，无法照抄重跑。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 这批图是纯图形（无文本层），`pdftotext` 级别的对拍用不上
- 只能把 PDF 解压、归一化后逐流比

**判定**：keep-with-fix · 拟 promote-playbook · 原证据快照风险=low · 复核时本机可复跑=true
