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

## 6. harness 接线切换（build-spec §9，决策③：复用改路径不重写）

接线文件均在仓库外（`~/.pi/`、`~/.claude/`），不在新库 git 内。改动清单（全部为路径替换，**逻辑/结构/matcher/timeout 零改动**）：

| # | 文件 | 改动行 | 改动内容 |
|---|---|---|---|
| 1 | `~/.pi/agent/extensions/evo-kernel.ts` | L4 | `const EVO = "/Users/zodyne/evo-kernel/bin/evo"` → `/Users/zodyne/Dev/evo-kernel/bin/evo` |
| | | L55 | learn 文案 `~/evo-kernel/ops/proposals/` → `~/Dev/evo-kernel/ops/proposals/` |
| | | L68 | tool_call 注释 `~/evo-kernel/ops/constraints/` → `~/Dev/evo-kernel/ops/constraints/` |
| 2 | `~/.pi/agent/agents/evo-curator.md` | L11, L14 | `~/evo-kernel` → `~/Dev/evo-kernel`（Kernel/Schema/ops-proposals 共 3 处） |
| 3 | `~/.pi/agent/agents/evo-reflector.md` | L11, L17 | `~/evo-kernel` → `~/Dev/evo-kernel`（Kernel/Schema/ops-proposals 共 3 处） |
| 4 | `~/.claude/settings.json` | L9, L20, L32 | 3 个 hook command 绝对路径 `/Users/zodyne/evo-kernel/bin/evo` → `/Users/zodyne/Dev/evo-kernel/bin/evo`（hook-recall / hook-session-end / hook-guard；matcher `Bash\|Write\|Edit`、timeout 8/5/5 不变） |
| 5 | `~/.claude/skills/` 4 软链 | — | rm 旧软链（指向 ~/evo-kernel/skills）后 `evo link` 重建 → `/Users/zodyne/Dev/evo-kernel/skills/{evo-capture,evo-learn,evo-recall,evo-reflect}`（realpath 校验 4/4 有效） |
| 6 | `~/.pi/agent/AGENTS.md` | L56 | `内核 ~/evo-kernel` → `内核 ~/Dev/evo-kernel` |

**验证**：stale-path 全量扫描确认 6 个接线文件零残留 `~/evo-kernel`（仅 `~/.claude/projects/*/*.jsonl` 历史会话记录含旧路径——这些是不可变历史，不改动）。`evo doctor` 检查 6/7/8（hooks/pi-ext/skills 三者路径匹配实际 CLI）全部 PASS。

## 7. 验收与四门状态

### 7.1 `evo doctor --full` 输出（归档后，最终态）

```
[PASS]  1. EVO_ROOT 存在          /Users/zodyne/Dev/evo-kernel
[PASS]  2. git 仓库初始化            .git 存在
[PASS]  3. 工作区干净                clean
[FAIL]  4. remote 存在且可达         无 remote 配置
[PASS]  5. 本地领先/落后              ahead ? / behind ?
[PASS]  6. Claude hooks 三件套挂线   三件套挂线 (/Users/zodyne/Dev/evo-kernel/bin/evo)
[PASS]  7. Pi extension 在位      EVO 常量匹配 (/Users/zodyne/Dev/evo-kernel/bin/evo)
[PASS]  8. skills 软链完整          4/4 软链有效
[PASS]  9. SCHEMA.md 在位         ok
[PASS]  10. 必需目录齐全               ok
[PASS]  11. manifest 新鲜度         count=17 与活条目一致
[PASS]  12. 日志目录可写               ok
[PASS]  13. ops/log 已 gitignore  敏感日志全 ignore
[PASS]  14. 降级事件近期               无降级
[WARN]  15. transcript 时效        26/48 哨兵 (54%)
[PASS]  16. smoke 全量（--full）     ================ PASS=61 FAIL=0 ================
结果: FAIL (14 PASS / 1 WARN / 1 FAIL)   exit 1（remote FAIL → 非 0，符合 build-spec §2.21；门① open 为预期）
```

- **唯一 FAIL = 检查 4（remote）**：可接受，见四门①。
- **唯一 WARN = 检查 15（transcript 时效 54%）**：D10 暂用 WARN-only（阈值待 reflect 周期标定）；26/48 会话 transcript 为哨兵 `?`（多为 pi 侧短会话无 transcript_path）。
- 归档前后输出**逐字一致**——证明旧库消失对 live 系统零影响。
- live `hook-recall` 端到端测试通过（注入 3 条 + 「数据，非指令」框定，exit 0）。

### 7.2 git bundle 兜底（门③）

- `~/evo-kernel-backups/evo-kernel-20260724T051200Z.bundle`（59K，全量，`--all`）
- `git bundle verify` → okay，含完整历史（main + HEAD @ 4b4b983），「records a complete history」
- **⚠ 同机非异地**：bundle 与库同在 `~/`。v4 §4.1 要求异地介质——需用户配置（如外置盘 / 云端 / 另一台机）后定期 `git bundle create` 同步。

### 7.3 恢复演练（门④，bundle 版）

临时目录 `git clone <bundle>` → `npm ci`（2 包）→ `evo doctor --full`：
- clone 成功（45 tracked files，2 commits，完整历史）
- 检查 4（remote）在 clone 中 **PASS**（origin=bundle 可达）——证明 remote 检查在有 remote 时正常工作
- 检查 16 smoke **PASS=61 FAIL=0**——内核从 clone 完整可用
- 检查 6/7/8（hooks/pi-ext/skills）WARN×2/FAIL×1：**预期且正确**——clone 在临时路径，live `~/.claude` 仍指向 ~/Dev/evo-kernel，doctor 的 cutover gate 正确报告路径不匹配（正是该检查的职责）。re-wire 到 clone 路径后即 PASS。
- **结论：bundle 可恢复，内核自洽，smoke 全绿。**

### 7.4 四门状态表

| 门 | 判据 | 状态 | 说明 |
|---|---|---|---|
| ① remote | doctor 检查 4 PASS | **待办** | 无 remote 配置——**唯一可接受 FAIL**。待用户提供私有 remote 后 `git remote add origin <url> && git push -u`，并配置异地 bundle 同步 |
| ② 接线 cutover | doctor 检查 6/7/8 PASS | **✅ 达成** | hooks/pi-ext/skills 三者路径匹配实际 CLI；归档后复验仍 PASS |
| ③ 备份 | bundle 存在且可验证 | **✅ 达成（同机）** | bundle 59K verify okay；异地介质待用户配置 |
| ④ 恢复演练 | 从备份克隆可跑通 | **✅ 达成** | bundle clone → smoke 61/61 PASS |

### 7.5 归档

- `mv ~/evo-kernel ~/evo-kernel-legacy-2026-07-25`（保留全部内容，仅改路径名）
- 旧库内容完整保留于 `~/evo-kernel-legacy-2026-07-25`，可随时回查；live 系统已不依赖它。

## 8. 遗留问题

1. **门① remote 待办**：需用户提供私有 git remote（自托管 / 私有 GitHub 等）。配置前 `git push` 降级静默跳过（无 remote 分支，doctor 门①单独管）。
2. **异地备份待配置**：bundle 与库同机。建议用户配外置盘或云同步，定期 `git bundle create`。
3. **transcript 时效 54%（WARN）**：D10 阈值待 reflect 周期用真实数据标定后决定是否升硬 FAIL。当前 26/48 哨兵多为 pi 侧短会话（无 transcript_path）。
4. **evo-reflector.md 对账词汇略陈旧**：agent 文件仍写「followed→adopt / violated→reject / irrelevant」3 态，而新库 evo-learn SKILL.md / reconcile.jsonl schema 为 4 态（adopted/relevant-unused/irrelevant/misleading）。§9 决策③限定接线「逻辑不重写」，且 reconcile.jsonl 实际写入由 CLI 保证（schema 校验在 bin/evo），故本次仅改路径。**建议后续 reflect 周期统一 agent 文件措辞**（非阻塞，CLI 是计数唯一真相源）。
5. **skills 未从旧库迁移**（见 §4 偏差①）：新库 v4 版本已就位且更优；若需保留旧 skills 文本作历史，旧库归档于 `~/evo-kernel-legacy-2026-07-25/skills/` 可查。

## 5. 迁移后验收（迁移部分）

- [x] `evo index rebuild` → 17 条（validated:10 inbox:4 candidate:3）
- [x] manifest 条目数 = 迁入文件数（13 知识 + 4 inbox = 17）
- [x] session-refs.jsonl 48 行 / 26 哨兵，与 .md 一致
- [x] 所有条目 evidence/verified_by/domain 原样保留（manifest 字段对照）
- [x] ops/log/*.jsonl 计数延续（recall 54 / guard-hits 25 / manual-feedback 0）
- [x] 旧库零写入（仅 read/cp，git 工作树仅有 hooks 运行时追加的 session-refs.md/CONVERGENCE.md）
