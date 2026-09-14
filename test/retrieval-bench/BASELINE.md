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
| 召回了错条目（更糟） | T-arxiv→arxiv-download-proxy-truncation, T-gitadd→episode-suc221-fpga-cache-mismatch, T-docdrift→nav-doc-pinned-head-goes-stale | 不只是漏，还挤占预算注入噪声 |

第二类比第一类严重：空命中至少不污染 context，而 `T-gitadd`（git 暂存问题）召回到
`episode-suc221-fpga-cache-mismatch`（雷达 FPGA 缓存）说明中文 bigram 通道会产生
跨领域的伪相关。这是选择改进方向时应优先攻击的部分。

**尚未测量**：净收益。本基准不回答"注入经验是否让任务做得更好"——那需要 LLM 实跑
配对照组 + 结果标注。当前状态仍是"召回层可证伪了"，不是"价值主张已证实"。

---

### 2026-07-28（同日，第二次）· 数据集勘误 + 评分变体实验（**未 cutover**）

**勘误**：`T-heredoc` 标注错误——目标 `heredoc-in-and-chain` 位于 `lessons/`，按 I2 永不进入
注入集，任何召回层都不可能命中它。已标为 `phase: invalid` 保留作反例。transfer 分母 8 → 7，
**首次基线的 25% 应读作 2/8；勘误后同一份实现是 2/7 = 29%**（实现未变，只是分母修正）。

**根因定位**：`cover = hits / |phrase|` 按短语自身长度归一，导致 **trigger 写得越具体越难召回**。
实例（T-gitadd）：目标条目命中 2 词得 `0.143` 被阈值 0.25 滤掉；噪声条目
`episode-suc221-fpga-cache-mismatch` 仅命中 1 词（"结果"，其 trigger "结果不一致" 只有 4 个
bigram）得 `0.250` 通过。**命中更多的输给命中更少的**，激励方向是反的。
同一缺陷当年已在 tag 通道用"取并集"修过，triggers 通道被漏下。

**变体**（`EVO_SCORING`，默认 `v0` = 历史行为）：`v1` 分母下限 `max(|phrase|, 8)`；
`v2` idf 加权；`v3` = v1+v2。

| 变体 | learning | transfer | change | noise |
|---|---|---|---|---|
| v0（默认） | 100% | 29% | 100% | 83% |
| v1 | 100% | 29% | 100% | 83% |
| v2 | 100% | 29% | 100% | 83% |
| v3 | 100%（top1 83%） | 29% | 100% | **100%** |

**结论一：卡住 transfer 的是绝对阈值，不是排序。** 四个变体的 transfer 全无变化——目标条目
得分 0.14–0.17，阈值 0.25，变体只改相对次序。降阈值确实能拉起 transfer（v3 + `EVO_RELEVANCE_MIN`）：

| MIN | learning | transfer | noise |
|---|---|---|---|
| 0.25 | 100% | 29% | 100% |
| 0.16 | 100% | 43% | 83% |
| 0.13 | 100% | **71%** | 67% |
| 0.10 | 100% | 71% | 67% |

但这是**在 7 个 transfer 用例上调参**，过拟合风险高，不作为默认。

**结论二：不 cutover v3——bench 与 §5.0 回放给出相反结论。** bench 上 v3 严格不劣
（`N-download` 从注入 2 条变空命中，`L-gitadd` 不再夹带无关条目，唯一退步是 `L-arxiv`
目标从 top1 掉到第 3 位但仍被注入）。但按 §5.0 回放 `recall.jsonl` 的 132 条去重历史查询：

```
注入集完全一致 11 ｜ 两侧均空 37 ｜ 丢失 189 ｜ 新增 1
丢失 Top: 35× episode-agent-evo-research / 25× seed-failure-lessons-as-templates
         24× ai-agent-book-as-self-evolution-reference / 20× episode-suc221-project-overview
         16× design-review-cross-check-implementation / 14× independent-design-review
按查询长度: 长查询(>200字) 丢失 83 / 保留 49；短查询 丢失 106 / 保留 62
```

v3 砍掉约 63% 的注入量。丢失榜首几条确实是已知噪声条目，但 `design-review-cross-check-implementation`
`independent-design-review` `claude-hook-sessionstart-no-prompt` 等看上去是正当命中。
§5.0 要求"丢失清单逐条人审、任何未审回归不 cutover"，189 条未审 → **保持 v0 默认**。

**结论三（本次最重要）：bench 在最要紧的维度上不具代表性。** 6 个 noise 用例**全是短查询**
（"提交""继续""plain text"），而生产噪声主要发生在**长 subagent prompt** 上——实盘一次注入
8–10 条的正是那类查询。所以 bench 判不了"砍掉 63% 注入量是改进还是回归"。
**下一步应先给 bench 补长查询用例（正例与噪声例都要），再让它仲裁评分变更**，
而不是继续调参数。

---

### 2026-09-14 · backend=scan · 库 224 条 · 长查询用例 + 逐条精度闸门

**动因**：实盘精度跌破阈值（`M1 召回精度 40%（90/225）` <50% 连续2周期 → 命中）。

**先做的测量**（此前无此项）

- 逐条精度：泄漏高度集中 —— 5 条条目占约 25% 注入量、精度全 ≤30%（`arxiv-api-rate-limit`
  182 次/0% · `seed-failure-lessons-as-templates` 158 次/0% · `episode-suc221-fpga-cache-mismatch`
  103 次/30% …）。
- **但现役 vs 已移出两组的精度几乎一致**（95 例/42% vs 130 例/38%）→ 是**机制级**过度注入，
  不是个别坏条目。这条测量否掉了「清几条坏条目就好」的方向。

**v3 丢失清单：本次用对账数据替 §5.0 的人审做了仲裁**（上次只能「未审 → 不 cutover」）

| v3 丢失 Top | 丢失次数 | 对账精度 | 判定 |
|---|---|---|---|
| episode-agent-evo-research | 35 | 69% | ❌ 丢=回归 |
| seed-failure-lessons-as-templates | 25 | 0% | ✅ 丢=改进 |
| ai-agent-book-as-self-evolution-reference | 24 | **100%** | ❌ 丢=回归 |
| episode-suc221-project-overview | 20 | 71% | ❌ 丢=回归 |
| design-review-cross-check-implementation | 16 | 67% | ❌ 丢=回归 |
| independent-design-review | 14 | 84% | ❌ 丢=回归 |

**5/7 是高精度条目 → 否决 v3**（与上次「保持 v0」同结论，但这次有数据）。

**改的是另一条路：逐条精度闸门**（`lowPrecisionIds()`）

- 判据：对账样本 ≥ `EVO_PRECISION_MIN_N`（**5**，与内核 DEAD_MIN 同口径）且精度
  < `EVO_PRECISION_MIN`（0.5）→ **不进自动注入**；直调 `recall` 与 `get --ids` 照常可取。
- 效果：现役集内 2 条入闸（`pi-mcp-adapter-global-config-path` 36 次/40%、
  `macos-no-timeout-command` 20 次/20%）。
- 只读 reconcile 日志（不读人工维护、会漂移的 `evidence` 字段 —— 见同日 reflect 三判据修复）。
- **已知缺口**：`seed-failure-lessons-as-templates`（158 次注入、0% 精度）只有 4 条对账记录，
  擦着样本量门槛溜过。这是 transcript 丢失的下游后果，非本机制可解。

**本轮 bench 变化：补 long 阶段（基线「结论三」点名的缺口）**

新增 4 条**长查询**用例（此前 12 条全是短查询）：
- 正例 `L-jsyaml`（长 prompt 描述 YAML 日期字段变 object，期望 `js-yaml-silently-parses-iso-date-to-object`）
- 正例 `L-slice-harness`（长 prompt 描述跨 harness 切片对不齐）
- 噪声 `L-noise-schedule`（长日程整理 prompt，expect 空 = 必须零注入）
- 噪声 `L-noise-rename`（长批量重命名 prompt）

| 阶段 | 用例 | 通过率 | top1 | 噪声 |
|---|---|---|---|---|
| learning | 4 | 100% | 100% | 2 |
| transfer | 5 | 20% | 20% | 2 |
| change | 2 | 100% | 100% | 0 |
| noise | 6 | 83% | 83% | 1 |
| **long** | **4** | **75%** | 50% | **5** |

**long 的唯一失败即「结论三」预测的现象**：`L-noise-schedule`（长日程 prompt）召回了
毫不相关的 `bash-loop-child-steals-stdin`。**长查询组噪声 5 条来自 4 个用例** —— 而短查询组
（learning+transfer+noise）噪声合计仅 5 条来自 15 个用例。**结论三从断言变成测量值。**

**勘误（本轮）**：`L-arxiv` / `T-arxiv` / `L-hook` / `T-hook` 标 `phase: invalid` ——
其目标条目（`arxiv-api-rate-limit` 12 例全无关、`claude-hook-sessionstart-no-prompt` 22 例
精度 9%）已于同日按低精度退役/归档，**任何召回层都不可能命中**（同 `T-heredoc` 的处理）。
标掉后 learning 回到 100%、transfer 1/5；**这不是回归** —— 基线里 T-hook 原是唯一额外通过项，
它变成不可达是设计性结果。

**bench 本轮还纠正了一次判据错误**：`playbook-suc221-cfar-point-cloud-filtering` 于同日
4-A 被「空转退役」判据退役（adopted=0），而它在 bench 里是 `L-cfar`/`T-cfar` 的期望目标、
对账精度 **85%**（11 相关 / 2 无关）。根因是 `dead = irrelevant + relevant-unused` 把
「无关」与「相关但没被用上」混为一谈。判据已改为精度基（`adopted===0 && precision<50% && n>=5`），
该条目已撤回 `playbook/`。

**尚未测量**：闸门上线后的实盘精度变化 —— 需等新数据（pi/hermes 自动回流 2026-09-14 才打通）。
