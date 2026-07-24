---
id: migration-2026-07-25
type: note
status: inbox
scope: global
domain: ops
created: 2026-07-25
schema_version: 1
---

# 存量数据迁移报告 · 2026-07-25

**源**：`~/evo-kernel`（旧库，在线服务中，本迁移对其**只读**）
**目标**：`~/Dev/evo-kernel`（绿地重建内核 v1，build-spec-v1.md v1.1）
**方式**：逐文件 `cp`（旧库零写入）；session-refs.md → .jsonl 程序化转换。

## 1. 计数对照表

| 类别 | 旧库文件数 | 迁入新库 | 说明 |
|---|---|---|---|
| playbook/ | 7 | 7 | 逐文件 verbatim 复制 |
| facts/domains/agent-self-evolution/ | 1 | 1 | landscape.md（domains/ 嵌套结构保留） |
| episodes/ | 1 | 1 | 2026-07-23-agent-evo-research.md |
| principles/ | 1 | 1 | verify-external-references.md |
| lessons/ | 3 | 3 | heredoc-in-and-chain / recall-dedup / rerank-channel-design |
| inbox/capture-*.md | 4 | 4 | 4 条 capture 原样 |
| inbox/session-refs.md | 1（48 行） | → session-refs.jsonl（48 行） | 格式转换，见 §2 |
| skills/（4 包） | 4 | **0（未复制）** | 见 §4 偏差①——新库已有 v4 对齐版本 |
| ops/constraints/*.json | 1 | 1 | dangerous-rm-rf.json |
| ops/proposals/reflect-*.md | 1 | 1 | reflect-2026-07-23.md |
| ops/log/recall.jsonl | 54 行 | 54 行 | 覆盖新库 smoke 测试残留（7 行） |
| ops/log/guard-hits.jsonl | 25 行 | 25 行 | — |
| ops/log/manual-feedback.jsonl | 0 行 | 0 行 | 空文件保留 |

### manifest 计数对照

| | count | validated | candidate | inbox |
|---|---|---|---|---|
| 旧 manifest（迁移前实读） | 14 | 10 | 3 | **1** |
| 新 manifest（`evo index rebuild` 后） | **17** | 10 | 3 | **4** |

> **差异说明**：旧 manifest 的 inbox=1 是**陈旧值**（旧库 manifest 未在新增 3 条 capture 后重建）；新库 rebuild 后 inbox=4 正确反映实际 4 条 capture。validated(10) 与 candidate(3) 两边一致。**新 manifest 17 条 = 7 playbook + 1 fact + 1 episode + 1 principle + 3 lessons + 4 captures**，与迁移条目全集一致。

## 2. session-refs 迁移对照（.md → .jsonl）

| | 行数 | transcript=? 哨兵 |
|---|---|---|
| 旧 inbox/session-refs.md | 48 | 26 |
| 新 inbox/session-refs.jsonl | **48** | **26** |

- 解析规则：`- <ISO> session=<sid> transcript=<path|?>` → `{"ts":"<ISO>","session":"<sid>","transcript":"<path|?>","harness":"claude","distilled":false}`
- **行数与哨兵数完全一致**（48/26），无丢失、无哨兵丢弃。
- `transcript=?` 哨兵**显式保留为字符串 `"?"`**（不丢弃、不转 null）。
- 全部 48 行经 JSON.parse 往返校验通过。

## 3. 迁入条目 id 清单（13 知识条目 + 4 inbox）

**validated（10）**
- playbook：arxiv-api-rate-limit · arxiv-download-proxy-truncation · claude-hook-sessionstart-no-prompt · independent-design-review · parallel-research-delegation · seed-failure-lessons-as-templates · unverified-arxiv-ids
- facts：agent-self-evolution-landscape
- episodes：episode-agent-evo-research
- principles：verify-external-references

**candidate（3）**
- lessons：heredoc-in-and-chain · recall-dedup-only-after-injection · rerank-channel-design

**inbox（4）**
- capture-2026-07-23-06-10-48 · capture-2026-07-23-06-19-47 · capture-2026-07-23-06-30-36 · capture-2026-07-23-06-31-51-927-vjz2

> evidence（helpful/harmful）、verified_by、domain、triggers 全部原样保留（manifest 字段对照确认）。

## 4. 假设与偏差

**偏差①（有意，红线级）：skills/ 4 包未从旧库复制**
- 旧库 skills/SKILL.md 是 v3 风格：3 态对账（adopt/reject/irrelevant）、硬编码 `~/evo-kernel` 路径、无 reflect/audit/doctor 命令。
- 新库 skills/SKILL.md 是 step-1 产出的 **v4 对齐重写版**：4 态对账（adopted/relevant-unused/irrelevant/misleading，对齐 D11 单通道裁决）、`<EVO_ROOT>` 路径占位符（位置无关）、含 §8 准入四条件 / git push / reflect 判据对照表。
- **复制旧 skills 会同时**：(a) 回退 v4 设计（重新引入 D11 已消除的双计风险）；(b) 把即将归档的 `~/evo-kernel` 硬编码路径写进 SKILL 文件——归档后即失效。
- 故保留新库 v4 版本，旧 skills 不迁移。**待人审裁决**：若需保留旧 skills 文本作为历史，可单独归档（非迁移）。

**偏差②（有意，规格遵循）：schema_version 字段未写入条目文件**
- 任务规格明确：「frontmatter 原样保留（schema_version 缺省按 1 解析，不加字段不改文件）」。
- 故 playbook/facts/episodes/principles/lessons 均**未含 schema_version 字段**（覆盖了 step-1 seed 时写入的 `schema_version: 1`）。
- bin/evo parseFm（line 150-157）：无 frontmatter 或字段缺失/为 null → 缺省 1。功能完全等价，manifest 正常解析全部 17 条。

**假设①：session-refs harness 字段缺省 `'claude'`**
- 旧 .md 无 harness 字段。按任务指示全部置 `'claude'`（旧库由 Claude hooks 登记为主，少量 pi session 的 harness 标注为 claude 是已知近似——spec 未给跨 harness 探测规则，doctor/reflect 不强依赖此字段准确性，见 build-spec §M0.4）。

**假设②：facts/landscape.md 的 source 字段引号差异**
- 旧：`source: research:~/Dev/agent-evo`（未加引号）；新库 step-1 曾规范化为 `"research:~/Dev/agent-evo"`。
- 本次按「原样保留」复制旧版（未加引号）。js-yaml 对「冒号后非空白」按 plain scalar 解析，语义等价（均得字符串 `research:~/Dev/agent-evo`）。manifest 已正确解析。

**观察：manual-feedback.jsonl 为空（0 行）**
- 旧库该文件自创建起即空（无人工反馈记录）。D11 裁决：绿地不创建此文件、rebuild 不读；本次仍复制空文件以保持目录结构一致（gitignore，不入库）。reconcile.jsonl 为唯一计数通道。

## 5. 迁移后验收（迁移部分）

- [x] `evo index rebuild` → 17 条（validated:10 inbox:4 candidate:3）
- [x] manifest 条目数 = 迁入文件数（13 知识 + 4 inbox = 17）
- [x] session-refs.jsonl 48 行 / 26 哨兵，与 .md 一致
- [x] 所有条目 evidence/verified_by/domain 原样保留（manifest 字段对照）
- [x] ops/log/*.jsonl 计数延续（recall 54 / guard-hits 25 / manual-feedback 0）
- [x] 旧库零写入（仅 read/cp，git 工作树仅有 hooks 运行时追加的 session-refs.md/CONVERGENCE.md）
