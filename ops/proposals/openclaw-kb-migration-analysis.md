---
id: openclaw-kb-migration-analysis
name: OpenClaw 知识库迁移至 Evo-Kernel 分析报告
type: episode
status: proposal
scope: [migration, analysis]
domains: [openclaw, evo-kernel, knowledge-management]
triggers:
  - OpenClaw 知识库迁移
  - 知识库迁移方案
  - Evo-Kernel 导入
  - OpenClaw 经验固化
evidence:
  helpful: 0
  harmful: 0
verified_by: human
---

# OpenClaw 知识库迁移至 Evo-Kernel 分析（先分析，不行动）

## 1. 现状盘点

### 1.1 OpenClaw 知识库位置与结构

OpenClaw 知识库位于 `~/.openclaw/workspace/knowledge-base/`，其 `README.md` 说明该目录是 2026-07-02 从原 `~/Knowledge`（Neovim + kb_engine，PARA 结构）迁移而来，现由 OpenClaw 接管日常检索与更新。

目录结构：

```
~/.openclaw/workspace/knowledge-base/
├── README.md                    # 迁移记录与治理说明
├── docs/                        # 原始文档（2 个 .md）
│   ├── openclaw-harness-v3-unified.md
│   └── SETUP-CHECKLIST.md
├── digests/                     # 定期摘要（1 个 .md）
│   └── v3-summary.md
├── vault/                       # 主知识库（约 88 个 .md，1MB）
│   ├── INDEX.md                 # 自动生成导航
│   ├── 10-Projects-Active/      # 活跃项目（10 个 .md）
│   │   ├── Track/
│   │   └── UCM221/
│   ├── 20-Areas/                # 领域（1 个 .md）
│   ├── 30-Resources/            # 参考资料（45 个 .md + 648 个非文本附件，7.5M）
│   │   ├── Algorithms/
│   │   ├── Development-Environment/
│   │   ├── SDK-Reference/
│   │   ├── TI-AWR2x44P-SDK/
│   │   ├── mmwave-sdk-awr2x44p/
│   │   └── ti-radar-toolbox-4.00.00.05/
│   ├── Daily/                   # 日报（23 个 .md）
│   └── System-Knowledge-System/ # 系统知识（GBrain 工作流 SOP 等）
└── archive/                     # 归档（旧版 SDML、UCM221 rollup 等）
```

此外，OpenClaw 还有两个相关资产：

- `~/.openclaw/workspace/memory/`：记忆文件（preferences、contacts、learnings、projects 等 11 个 .md）。
- `~/.openclaw/workspace/skills/`：技能包（6 个 SKILL.md + 脚本/模板/资源）。

### 1.2 元数据现状

- **frontmatter 不统一**：部分 Daily 笔记带 Obsidian 风格 frontmatter（`id`、`aliases`、`tags`、`date`），大量 Resources/Projects 文件只有 `> provenance: [imported]` 引用行，无结构化 frontmatter。
- **遗留机器协议**：README 提到原系统有 `kb_type`、`task_id`、`progress_id`、`<!-- kb:...:start/end -->` marker，迁移后仅作为可读文本保留，OpenClaw 不维护其语义。
- **检索方式**：`agents.defaults.memorySearch.extraPaths` 指向本目录，复用 Ollama bge-m3 语义索引；`openclaw memory search "关键词"` 可查。

### 1.3 内容主题分布

| 类别 | 主要内容 | 规模估算 |
|---|---|---|
| 项目记录 | UCM221 点云/雷达、Track 跟踪系统 | ~10 篇 |
| 技术参考资料 | TI mmWave SDK、DFP、DPC、DDMA、Radar Toolbox | ~45 篇 + 648 附件 |
| 日报 | 2026-03 至 2026-07 工作日志 | ~23 篇 |
| 系统/流程 | GBrain 知识工作流 SOP、SDML 设计说明 | ~5 篇 |
| 记忆/偏好 | preferences、contacts、learnings、projects | ~11 篇 |
| 技能 | anti-drift-governance、evidence-ledger、read-image 等 | 6 个 SKILL.md |

## 2. 与 Evo-Kernel 的映射关系

### 2.1 目录映射

| OpenClaw 位置 | Evo-Kernel 目标 | 说明 |
|---|---|---|
| `memory/preferences.md` | `facts/` 或 `principles/` | 用户偏好、工作习惯属于语义记忆 |
| `memory/contacts.md` | `facts/` | 人员信息属于事实 |
| `memory/learnings.md` | `playbook/` / `episodes/` | 经验教训需按原子性拆分 |
| `memory/projects.md` | `facts/` | 项目清单/状态 |
| `vault/10-Projects-Active/` | `episodes/` / `playbook/` | 项目轨迹入 episodes，可复用步骤入 playbook |
| `vault/20-Areas/` | `principles/` / `facts/` | 领域知识按性质区分 |
| `vault/30-Resources/` | `facts/`（精选）+ `ops/archive/`（大部头） | 参考资料不能全量注入，否则稀释 recall |
| `vault/Daily/` | `episodes/`（精选）+ `ops/archive/`（原始） | 日报是情景记忆，需蒸馏 |
| `vault/System-Knowledge-System/` | `playbook/` / `principles/` | 流程与 SOP |
| `workspace/skills/*/` | `skills/`（直接复用） | SKILL.md 包格式兼容 agentskills.io 标准 |
| `vault/archive/` | `ops/archive/` | 归档内容不注入 |

### 2.2 frontmatter 映射

OpenClaw/Obsidian frontmatter 需要转换为 Evo-Kernel schema：

| OpenClaw 字段 | Evo-Kernel 字段 | 转换说明 |
|---|---|---|
| `id` | `id` | 直接复用或规范化（去空格、特殊字符） |
| `tags` | `domains` / `scope` | 按主题映射到 domain，按场景映射到 scope |
| `date` | — | 可作为 `created` 或保留在正文中 |
| `aliases` | — | 可转成 `triggers` 候选词 |
| — | `type` | 必须新增：fact / playbook / episode / principle |
| — | `status` | 必须新增：candidate / validated / solidified / deprecated |
| — | `triggers` | 必须新增：从标题、tags、aliases、正文提取关键词 |
| — | `evidence` | 必须新增：`helpful: 0`, `harmful: 0` |
| — | `verified_by` | 必须新增：迁移资料统一标记为 `human` 或 `imported` |

## 3. 迁移方案设计

### 3.1 总体原则

采用手册中提出的 **两阶段模型**：

```
OpenClaw 资料 → 机器预处理（格式规范化/原子化/元数据映射）
              → ops/proposals/openclaw-import-<批次>/
              → 人工审查改写
              → evo curate --to <facts|playbook|episodes|principles>
```

**绝对禁止**：直接把 `vault/30-Resources/` 或 `vault/Daily/` 批量复制到 `facts/` / `playbook/`。这会违反不变量 I2/I3，污染注入集，破坏 helpful/harmful 计数。

### 3.2 分目录迁移策略

#### A. `workspace/skills/` → 直接复用

OpenClaw 的 skills 已经是 SKILL.md 包格式，且符合 agentskills.io 标准。最轻松的迁移路径：

1. 对每个 skill 目录评估是否仍有用；
2. 有用的直接复制/软链到 `~/Dev/evo-kernel/skills/`；
3. 运行 `evo link` 同步到 `~/.claude/skills/`；
4. 原 skill 在 OpenClaw 中保留或归档。

#### B. `memory/preferences.md` / `contacts.md` / `projects.md` → `facts/`

这些文件已经是语义记忆性质，但需要：

1. 拆分成原子条目（一人一条、一个偏好一条、一个项目一条）；
2. 每条生成 frontmatter；
3. 人审后 curate。

例如 `preferences.md` 中的「验证纪律」可拆成一条 principle：

```yaml
id: verify-before-claim
type: principle
status: validated
scope: [coding, review]
domains: [engineering]
triggers:
  - 验证
  - 运行验证
  - 证据
```

#### C. `vault/10-Projects-Active/` → `episodes/` + `playbook/`

项目记录是典型的情景记忆。建议：

- 项目整体概况、关键决策、失败教训入 `episodes/`；
- 从中提炼出的可复用步骤、检查清单入 `playbook/`；
- 临时草稿、过期进度入 `ops/archive/`。

#### D. `vault/30-Resources/` → 严格筛选

这是迁移中最敏感的部分。45 篇参考资料 + 648 个附件，如果全量导入会严重稀释 recall。

建议：

1. **不导入大部头原文**：如 `mmwave-sdk-user-guide.md`、`dfp-user-guide.md` 等 TI 官方文档，保留链接/路径引用即可；
2. **只导入自己写的摘要/笔记**：如 `gbrain-first-pass-analysis.md`、`gbrain-query-plan.md`、自定义 API 速查等；
3. **自己提炼的公式/参数/边界条件入 `facts/`**：如 SDML 的阵列几何、帧结构等；
4. **通用开发环境配置入 `facts/`**：如 `Claude_Code_DeepSeek_Usage.md`。

#### E. `vault/Daily/` → 蒸馏后精选入 `episodes/`

日报是原始工作日志，价值在于：

1. 作为 session transcript 的替代/补充；
2. 提炼失败教训、关键决策、突破性进展。

建议：

- 不直接导入日报原文；
- 用 `evo reflect` 的思路，从日报中识别值得固化的经验；
- 把这些经验改写成 episodes 或 playbook 后 curate。

#### F. `vault/System-Knowledge-System/` → `playbook/` / `principles/`

如 `GBrain_Knowledge_Workflow_SOP.md` 是流程文档，应：

1. 拆分成步骤清晰的 playbook；
2. 把跨流程的原则提炼成 principles。

## 4. 风险与挑战

### 4.1 高风险

| 风险 | 影响 | 缓解措施 |
|---|---|---|
| 全量导入污染注入集 | recall 精度下降，harmful/helpful 失真 | 严格筛选，只导入自己提炼的内容 |
| 敏感信息泄露 | 凭据、内网地址、客户信息入 git | curate 前逐条审查；对含敏感信息的文件不入库或脱敏 |
| 祈使式指令固化 | 持久化提示注入 | 把命令式文本改写为陈述式经验 |
| 破坏 OpenClaw 现有工作流 | 迁移期间两套系统并行，可能混乱 | 采用「只读迁移 + 增量同步」，OpenClaw 继续运行直到 Evo-Kernel 覆盖 |

### 4.2 中低风险

- **frontmatter 转换工作量**：约 80 篇文件需要不同程度的手动补全；
- **附件/二进制文件**：Evo-Kernel 是纯文本系统，PDF/图片等无法入库，只能保留链接；
- **domain/scope 设计**：需要为 OpenClaw 项目定义一套 domain 体系（如 `ucm221`、`track`、`mmwave-sdk`、`openclaw` 等）。

## 5. 推荐执行计划（分阶段，不立即执行）

### 阶段 0：试点（1-2 周，建议先做）

目标：验证迁移模型，不触动主库。

1. 选择 3-5 篇最有价值的 OpenClaw 资料（如 `Claude_Code_DeepSeek_Usage.md`、SDML 阵列几何、`GBrain_Knowledge_Workflow_SOP.md`）；
2. 手动改写为 Evo-Kernel 提案文件；
3. 跑 `evo curate` 入库；
4. 观察 1-2 周：recall 是否命中、内容是否被采用、是否有 harmful。

### 阶段 1：skills 迁移（1 周）

1. 评估 `~/.openclaw/workspace/skills/` 中 6 个 skill 的当前价值；
2. 把仍在用的 skill 复制到 `~/Dev/evo-kernel/skills/`；
3. 运行 `evo link` 并验证 Claude Code 能加载；
4. 对过时的 skill 在 OpenClaw 侧标记 deprecated。

### 阶段 2：memory 原子化（1-2 周）

1. 把 `memory/preferences.md`、`contacts.md`、`learnings.md`、`projects.md` 拆成原子条目；
2. 生成提案到 `ops/proposals/openclaw-memory-import/`；
3. 分批 curate 到 `facts/` / `principles/` / `episodes/`。

### 阶段 3：vault 精选蒸馏（4-6 周，最大头）

1. 从 `vault/10-Projects-Active/` 提炼 episodes 和 playbook；
2. 从 `vault/30-Resources/` 只导入自己写的摘要/笔记（预计 10-15 篇），官方文档保留链接；
3. 从 `vault/Daily/` 蒸馏关键经验；
4. 把 `System-Knowledge-System/` 流程文档 playbook 化。

### 阶段 4：归档与退役（1 周）

1. OpenClaw 侧确认 Evo-Kernel 已覆盖日常需求；
2. 把 OpenClaw 中重复/过时的内容移到 archive；
3. 保留 `~/.openclaw` 作为历史备份，但不继续维护。

## 6. 当前「不行动」的诚实理由

基于 Evo-Kernel 的判据驱动原则，**现在不适合立即启动全量迁移**，原因如下：

1. **数据尚未清洗**：OpenClaw KB 刚从 `~/Knowledge` 迁移而来，自身还在净化中（README 提到 preferences 14 条待确认、contacts 刚拆分、learnings 首次巩固）；
2. **Evo-Kernel 刚部署**：注入精度、helpful/harmful 计数、recall 判据都还没有积累；贸然导入 80+ 条资料会扭曲后续判据；
3. **M1/M2 判据未命中**：当前阶段应该是「跑飞轮攒数据」，而不是做大规模迁移；
4. **domain 体系未定**：需要先定义一套 domain/scope 命名规范，否则导入后检索失配；
5. **OpenClaw 仍在运行**：在 Evo-Kernel 能独立承担日常知识管理之前，不应中断现有工作流。

## 7. 立即可做的三件小事（仍属分析/准备，不迁移）

1. **起草 domain 命名规范**：定义 `openclaw`、`ucm221`、`track`、`mmwave-sdk`、`ti-radar`、`claude-code` 等 domain；
2. **做一份试点清单**：选出 3-5 篇最有迁移价值的资料，作为阶段 0 试点；
3. **写一个预处理脚本骨架**：用于把 OpenClaw/Obsidian frontmatter 转换为 Evo-Kernel 提案 frontmatter，先跑在只读模式。

## 8. 结论

OpenClaw 知识库迁移到 Evo-Kernel **可行且有价值**，但应被视为一个 6-10 周的渐进项目，而非一次性操作。正确的顺序是：

```
试点验证 → skills 复用 → memory 原子化 → vault 精选蒸馏 → OpenClaw 退役
```

现在最理性的动作是：继续让 Evo-Kernel 跑飞轮，同时做阶段 0 的试点准备。不行动（全量迁移）本身就是正确的行动。
