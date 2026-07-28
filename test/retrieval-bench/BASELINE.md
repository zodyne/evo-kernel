# 检索层基准 · 基线记录

每次改召回层（M1 FTS5 / M2 向量 / 换 embedding / 调权重阈值）都在此追加一行，**不要重写历史行**。
基线是用来对照的，改写它就等于把回归抹掉（同 `doc-selfreported-counts-drift`）。

跑：`npm run bench`（或 `node test/retrieval-bench/bench.js [--json] [--phase X]`）

## 记录

### 2026-07-28 · backend=scan · 库 60 条 · 首次基线

| 阶段 | 用例 | 通过率 | top1 命中 | 噪声条数 |
|---|---|---|---|---|
| learning | 6 | 100% | 100% | 4 |
| transfer | 8 | **25%** | 25% | 4 |
| change | 2 | 100% | 100% | 0 |
| noise | 6 | 83% | 83% | 2 |

**读法**

- `learning` 100% 是**下限达标**，不是成绩。它衡量的是"措辞贴近 triggers 时能不能召回"——
  做不到说明召回层坏了；做到了什么也不说明。
- `transfer` **25% 是本基准的头条数字**。blueprint §11 开放问题 1「词汇失配天花板未破」
  至此从断言变成测量值：改用不同措辞描述同一问题时，四次里只有一次能召回到正确条目。
- `change` 100% 是第一次在召回层证实 I2 的取代排除：旧条目带 `superseded_by` 后确实
  被排除、新条目被召回，且未误伤同库的未取代条目。
- `noise` 唯一失败例 `N-download` 是真实历史查询（本会话首条 prompt），实盘注入 2 条、
  对账判 relevant-unused + irrelevant——与 §7.1 的对账数据互相印证。

**transfer 的 6 个失败分两类，诊断价值不同**

| 类型 | 用例 | 含义 |
|---|---|---|
| 空命中（够不着） | T-timeout, T-heredoc, T-cfar | relevance 全部低于阈值，召回层没能力 |
| 召回了错条目（更糟） | T-arxiv→arxiv-download-proxy-truncation, T-gitadd→episode-ucm221-fpga-cache-mismatch, T-docdrift→nav-doc-pinned-head-goes-stale | 不只是漏，还挤占预算注入噪声 |

第二类比第一类严重：空命中至少不污染 context，而 `T-gitadd`（git 暂存问题）召回到
`episode-ucm221-fpga-cache-mismatch`（雷达 FPGA 缓存）说明中文 bigram 通道会产生
跨领域的伪相关。这是选择改进方向时应优先攻击的部分。

**尚未测量**：净收益。本基准不回答"注入经验是否让任务做得更好"——那需要 LLM 实跑
配对照组 + 结果标注。当前状态仍是"召回层可证伪了"，不是"价值主张已证实"。
