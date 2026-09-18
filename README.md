# Evo-Kernel

个人「经验治理与固化层」内核：纯文件 + git 存储，Node CLI（`evo`），当前只由 **pi 一个 harness** 接入。

> **harness 接入现状（2026-09-18）**：
> - **pi**：已接（`~/.pi/agent/extensions/evo-kernel.ts`，三个事件）；**唯一**接入的 harness。
> - **Claude Code**：有意不接（hooks 已退役且无替代桥接）。
> - **Hermes**：**已与 evo 彻底脱钩**（用户口径），两处都断：
>   ① hooks 三件套从 `~/.hermes/config.yaml` 摘除（恢复办法写在被注释掉的段旁，三步）；
>   ② **蒸馏执行器从 hermes 换成 pi** —— 否则 evo 的后台飞轮仍跑在 hermes 运行时里。
>   随之删除 doctor 第 7/16 两项检查（编号留空不回收），`ops/integrations/hermes-evo-hooks/`
>   降级为纯存档（不再有任何检查读它）。`bin/evo` 里仅保留 slice 对 hermes 导出**格式**的支持
>   （历史数据需要解析，非运行时耦合）。
>
> 换执行器的实测量级差异：一条 88KB 会话 pi 用 **1m33s** / 产出 2 条提案；hermes 同量级
> 2–27 分钟。差别来自隔离旗标（`-ne -nc -ns -np`）把上下文剥到最瘦 —— hermes 的系统提示/
> `skill_view`/记忆无法关，而成本恰恰全在模型思考块（12–43KB 思考 / 126 字符输出 = 340 倍）。

> 设计权威：`~/Dev/agent-evo/design/blueprint-v4.md`（不变量 I1–I7、§4 数据存续、§7 测量定义）。
> 构建契约：`~/Dev/agent-evo/design/build-spec-v1.md`（v1.1，§2 命令契约卡（当时 21 个，现 25）、§3 数据/日志 schema、§5 评分系数、§8 smoke 断言）。

## 目录即状态机（§1.1）

| 目录 | 角色 | 注入 |
|---|---|---|
| `inbox/` | capture 暂存 + 会话登记（`session-refs.jsonl`）；零判断入口 | ❌ 永不注入 |
| `lessons/` | candidate 经验暂存（不允许 validated+） | ❌ 永不注入 |
| `facts/` | 语义记忆：事实/偏好/环境，按 `domains/` 分目录 | ✅ |
| `episodes/` | 情景记忆：一次任务一份 | ✅ |
| `playbook/` | 策略库：原子 bullet，带 helpful/harmful 计数 | ✅ |
| `principles/` | 原则：跨域普适 | ✅ |
| `skills/` | 程序记忆：SKILL.md 包（agentskills.io 标准） | 经 skill 注入 |
| `ops/constraints/` | 硬约束规则（JSON，guard 执行） | — |
| `ops/archive/` | deprecated/solidified 存档（recall 不检索） | ❌ |
| `ops/log/*.jsonl` | append-only 日志（**全部 gitignore**，含 prompt 明文 §4.4） | — |
| `ops/proposals/` | reflect/distill 提案（待人审批） | — |
| `index/manifest.yaml` | 生成物（`index rebuild`，I5 派生物） | — |

## ROOT 解析顺序（§1.2 实施层修正）

```
ROOT = process.env.EVO_ROOT || <bin/evo 脚本的父目录>
```

`EVO_ROOT` 环境变量优先；缺省时 CLI 自定位（本脚本父目录 = 仓库根）。**这使仓库位置无关**——可放在 `~/evo-kernel`、`~/Dev/evo-kernel` 或任意路径，无需改代码。smoke 的临时 ROOT 模式（`EVO_ROOT=<tmp>`）照常工作。

## 21 个命令

见 `bin/evo` 头注释或 `~/Dev/agent-evo/design/build-spec-v1.md` §2。退出码规则（§0.3）：除 `doctor` 外所有命令所有路径 `exit 0`（fail-open，I1）；`doctor` 是诊断命令，FAIL 时 `exit 1`。

---

## 从零挂起 SETUP（M0.4 / v4 §M0.4，新机部署照此执行）

### 1. 克隆 + 安装依赖

```bash
git clone <私有 remote> ~/Dev/evo-kernel    # remote 必须私有（§4.3）
cd ~/Dev/evo-kernel
npm install                                   # 仅 js-yaml（纯 JS，无 native；lockfile 入库）
```

> 依赖纪律（v4 §M0.1）：`package-lock.json` 入库，依赖版本锁定；升级走独立 commit。

### 2. 初始化 git（若 clone 已带则跳过）

```bash
git init      # 已是仓库则跳过
evo index rebuild   # 生成 index/manifest.yaml（I5 派生物）
```

### 3. 配置 Claude Code hooks（决策③：复用逻辑，只切路径）

编辑 `~/.claude/settings.json`，三件套的 `command` 指向**本仓库**的 `bin/evo`：

```jsonc
{
  "hooks": {
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "<ROOT>/bin/evo hook-recall", "timeout": 8 }] }],
    "SessionEnd":       [{ "hooks": [{ "type": "command", "command": "<ROOT>/bin/evo hook-session-end", "timeout": 5 }] }],
    "PreToolUse":       [{ "matcher": "Bash|Write|Edit", "hooks": [{ "type": "command", "command": "<ROOT>/bin/evo hook-guard", "timeout": 5 }] }]
  }
}
```

> ⚠ `UserPromptSubmit`（每次输入触发，去重）≠ `SessionStart`（拿不到 prompt，见 `playbook/claude-hook-sessionstart-no-prompt`）。

### 4. Pi extension 落位

`~/.pi/agent/extensions/evo-kernel.ts` 的 `EVO` 常量改为 `"<ROOT>/bin/evo"`（事件接线 4 个：`before_agent_start`→`hook-recall`、`session_shutdown`→`hook-session-end`、`tool_call`→`guard`，逻辑不变）。

### 5. skills link

```bash
evo link      # 同步 <ROOT>/skills/* → ~/.claude/skills/（幂等）
```

### 6. transcript 保留期核实（v4 §M0.4 时效约束②）

**蒸馏批处理周期必须短于 harness 的 transcript 保留期**，否则登记与蒸馏之间存在「腐烂窗口」（transcript 被清理 → `session-refs.jsonl` 里 `transcript:'?'` 哨兵行累积）。

- **Claude Code**：核实 `cleanupPeriodDays`（或等价配置）。默认值请以官方文档为准（**部署时必须核实当前值**，不得凭记忆）。若默认 30 天，则蒸馏周期建议 ≤7 天。
- `evo session-end` 登记时探测 transcript 存在性，不存在即写哨兵 `'?'`（约束①）。
- `evo doctor` 检查项 15 + `evo reflect` 判据对照表「蒸馏节律」行盘点哨兵占比（约束③）。

### 7. 部署自检（部署门③）

```bash
evo doctor        # 须全 PASS/WARN（无 FAIL）→ exit 0
evo doctor --full # 附带跑 smoke 全量
```

`doctor` FAIL → `exit 1`（唯一非零退出命令）。常见 FAIL：无 remote（门①）、缺目录、敏感日志未 gitignore、SCHEMA 缺失。

### 部署四门（v4 总纲 + build-spec §10）

| 门 | 内容 | 判定 |
|---|---|---|
| ① 存续基线 | 私有 remote + curate/solidify 自动 push（fail-open） | `doctor` 检查 4 PASS |
| ② M0 交付物齐验 | 解析器/通道/日志/doctor/smoke 全就位 | 逐项核对（build-spec §10.3） |
| ③ doctor 全绿 | `evo doctor; echo $?` → 0 | `doctor` exit 0 |
| ④ 恢复演练通过 | 临时目录 `git clone` → `doctor --full` → smoke 绿 | 演练记录入复盘报告 |

> **remote 是备份，不是多机同步协议**（v4 §4.1）：第二台机器只允许只读消费（recall/get）；多机并写未设计（ID 碰撞/计数合并），视为误用。

---

## 继续后续工作（交接给下一次会话）

> 写在 README 而不是留在对话里 —— 下次会话没有今天的记忆，会重新踩一遍已排除的路。
> 最后更新：**2026-09-18**。

**现状一句话**：9/15–16 修的两个仪器故障（自污染反馈环、驱动器锁）+ 对账去重已验；
9/18 又修了**驱动器的三个真缺陷并开了并发**（看门狗杀错进程、只按 rc 判成功、队列串行 →
现在 4–6 worker 并发跑，实测 4 路同时起）。同时把 26 条待审提案清空入库（库 325→352）。
**账目干净、产能已提上来了，仍然纯等数据**：L3b agentic 通道精度 50%（n=2），离门槛（≥10 任务）还早。

### 第一步：跑这三条

```bash
evo reflect     # 看 L3b agentic 通道 使用/精度 两行 + M1 召回精度
evo doctor      # 应 0 FAIL（WARN 允许：transcript 时效那条是已知的 C1 漂移）
npm test        # 应 FAIL=0（**不写死 PASS 数**：见本库 doc-selfreported-counts-drift）
```

### 判据表：看到什么 → 做什么

| 观察对象 | 当前值 | 判据 / 动作 |
|---|---|---|
| `L3b agentic 通道使用` | 1 get · 1 candidates（2 个任务） | < 10 个不同任务 → **等，别改代码**；长期为 0 → 查 primer 两处装载（doctor #17） |
| `L3b agentic 通道精度` | 50%（1/2） | ≥10 任务后再读：高于召回精度 >10pp ⇒ 迁默认路径到「只给短名单」；相当 ⇒ 查 agent 挑得保守；更低 ⇒ 查 agentic.jsonl 的 session 归属 |
| 新入库的 8 条 playbook 条目 | 入库当天即被 4 个会话注入 | 攒够对账后看 `(adopted+relevant-unused)/n` vs 全库 34% 基线：低于基线 ⇒ 收紧 triggers；否则保留 |
| 队列长度 | ~117 条（日登记 ~70） | 持续增长 ⇒ 产能不够；不增长 ⇒ 收支平衡。**9/18 起产能不再由「一天一次 `--max 8`」决定**：已开并发（见下），所以此行的读法变了 —— 先看 `EVO_DISTILL_JOBS` 实际分档与每轮时长，再判产能 |
| 蒸馏并发 | 4 worker（`--max 48` 档） | 看日志里同秒 start 的条数 ≈ worker 数。若并发上不去（只剩单条 start）⇒ 查 `--slot` 进程是否还在、锁路径是否被非目录占住（该情形已能自愈，但会记一行「锁路径被非目录占用」） |
| provider 并发承受度 | **首测：4 并发 · 16 条 · 0 失败**（2026-09-18 01:05Z 起 43 min，`--max 48` 轮，n 小待攒） | 4–6 并发跑几轮后统计 `fail` 里的 `can't reach the model provider` / `Broken pipe` 占比：与单并发时相当 ⇒ 可继续升档；显著升高 ⇒ 把 `EVO_DISTILL_JOBS` 写死回 2–3 |
| 对账重复 | 已自动去重（留最后一次） | 若再现「原始行数 vs 报告分母」偏差，先怀疑去重读法被绕过 |

### 仪表（各自解决什么，别重造）

| 工具 | 回答什么 |
|---|---|
| `test/retrieval-bench/labeling/run-eval.js` | 任何检索改动之后：precision 与 recall **一起**报 |
| `test/retrieval-bench/labeling/FINDINGS.md` | 四轮测量的结论与局限（含 disputed 口径） |
| `test/retrieval-bench/replay.js` | 评分/后端变更的 §5.0 相对仲裁（559 条历史查询） |
| `ops/log/agentic.jsonl` | 语义通道的真实使用痕迹（带 session，可与 query 关联） |
| `ops/log/reconcile.jsonl` | 四态对账（**经 readReconcileDedup 去重读**，勿再直算行数） |
| `ops/bin/evo-distill.sh` 的沙箱旋钮 | `EVO_HERMES_PY`/`EVO_HERMES_BIN`（换执行器）、`EVO_DISTILL_EVO`（换 evo CLI）、`EVO_DISTILL_POLL`（轮询间隔，可小数）——不碰网络就能回归切片/锁/哨兵判定（smoke 组 L 就是这么测的） |

### ⚠️ 已排除的方向（别再花时间，每条都有数）

| 方向 | 为什么排除 |
|---|---|
| 继续调 `relevance` 阈值 | 已近最优：移动只买 **+7pp** recall |
| 换评分公式（v1 分母下限 / v2 idf / v3 叠加 / v4 最少命中数） | v1/v3 误伤短 trigger；v2 只是缓解；v4 机制上无效 |
| 用「零模型显著性」替代固定比例 | 就是 DFR，与 idf 家族等价（换皮） |
| 治「长 prompt 过度注入」 | 实现产物（字段长度归一 + 跨查询绝对阈值），代价只是 token，真损失在召回侧 |
| 收紧 tags/triggers 提精度 | 2026-09-16 实测：短任务合法命中 7/8、噪声 0/4；真实跨域注入只发生在长 briefing（上一条）。收紧只砍召回，而**漏/误 = 3.44** |

### 2026-09-18 本轮修了什么（防止重复发现）

**驱动器三个真缺陷**（都有对照数据）——这三个曾让单条会话白烧一整轮额度：

1. **看门狗杀错进程**：`( ... ) &` 的 `$!` 是**包装子 shell**，`kill -9` 只杀壳，hermes 变孤儿继续跑
   且失去超时保护。实测 `01a099a8`：13:44:03Z 判超时杀掉，**孤儿 16 min 后写完 6 条提案 +
   `DISTILL_OK 6`**（`01a0a521` 同类，34 min）。修法：子 shell 内 `exec env` 让 `$!` 即 hermes 本体，
   超时走 `kill_tree` 整树回收（hermes 自己还会派生 `mcp_` 子进程），并复现了「杀壳留孤儿」的机制对照。
2. **只按 rc 判成功**：哨兵已写出、进程被超时杀掉 → rc=137 → 判失败 → 已完成的蒸馏被丢回队列重跑。
   改以 `.out` 里的 `^DISTILL_OK <n>` 哨兵为准，rc 只进日志。沙箱对照：写完哨兵后挂住不退出
   → 旧实现 `fail`+重试，新实现 `done`。
3. **超时预算固定**：正常完成中的长会话被切。两个实测点拟合（219518B→2040s、1048613B→2820s）
   → 基数 1800s + 100s/100KB（封顶 5400s）。**单位别用 MB 整除**：队列主体是 200–800KB，
   整除后恒为 0，等于没加预算（初版就踩了，被队列体量分布打掉）。

**并发**（`EVO_DISTILL_JOBS`，默认 1；`auto` 按**本轮窗口 `--max`** 分档 <8→2 / 8–39→3 / 40–99→4 / ≥100→6）：
runner 拿全局锁后播 N 个自身副本当 worker。三个必须记住的点：

- **切片用同余类不是连续块** —— 队列按体量排序，连续块会让一个 worker 全拿巨型会话、整轮时长被最慢那条决定。
- **runner 分支必须放在「取队列+主循环」之前** —— 放后面会让 runner 先用全量队列跑一遍、再播 worker 双跑。
- **worker 不抢锁**（锁由 runner 持有）；若照搬「实例自己抢锁」，worker 只会把自己拒之门外。

**跨进程写锁**（`bin/evo` 的 `withFileLock`）：`session-refs.jsonl` 是读-改-写，rename 原子
**挡不住丢更新**。无锁对照实测：16 进程同时 `mark-distilled` → **0/16 存活**（全丢），加锁后 16/16。
顺带把共用的 `<file>.tmp` 换成带 pid 的唯一名（两个写者会互相穿插写同一份临时文件）。

**两个「坏的那侧不吭声」的坑**：
- 锁路径若被**非目录**占住（还活着的实例心跳用 `touch` 把锁目录变成了同名空文件），
  则 `mkdir` 永远 EEXIST 而 `[ -d ]` 不成立 → **每轮都只报「已有实例在跑」且永不恢复**。现已自愈。
- `queue` 取列表失败曾静默成「队列为空」（沙箱里 evo 因缺 `node_modules` 崩掉正是这个形状），
  与「distill.log 停在 8-25 而 20 天无人发现」同类。现已把 rc 与 stderr 记进日志。

**提案清仓**：26 条审完入库（11→playbook / 1→facts / 13→lessons / 1 并入既有条目），库 325→352。
审核里抓出 2 条伪经验（详见 `playbook/pi-transcript-tool-args-encoding-is-per-tool` 的由来与
`noncoherent-sum-statistic-dof-2nk` 的订正注）：**提案里引的数同样要交叉核对**——一条讲「口径不一致数值就不可比」
的条目，自己引的 `chi2.isf` 值就带着没标明的 /2 归一化。

**落地依据**：本次落位口径是「能否当场复验」——能在本机跑出数字的 11 条进 playbook（进注入集），
证据在别的仓库/环境已变的 13 条进 lessons（候选、不注入）。

### 2026-09-15/16 本轮修了什么（防止重复发现）

1. **自污染反馈环**（hermes 侧，`f95da31`）：驱动器每次跑都把自己登记进队列（1.5 个月攒 13 条）+ 把自己的 `evo get` 记成 agentic 使用量（2/3 是机器账）。修法：`EVO_DRIVER=1` 短路 + adapter 提示词哨兵兜底（防 env 传不到）。
2. **驱动器锁**（`3dedd88`）：休眠把 5.5h 的活实例判成残留锁 → 双实例并跑；先退出者无条件删他人锁。修法：看门狗 `touch` 心跳 + 锁内 pid 归属（只删自己那把）。
3. **对账去重**（`1302130`）：重试重写同一 `(session,id,channel)`（全库重复 69/364，不去重时精度被压到 27%）→ 三位消费者统一走 `readReconcileDedup()`，smoke 加断言。
4. **调度**（`475f20a`）：launchd `03:30 → 14:30`、`--max 3 → 8`（凌晨笔记本休眠会错过/撞锁）。
5. **提案清仓**：26 条审完入库（8→playbook[现场复验过] / 18→lessons），库 232→258 条。

## 开发

```bash
npm test          # = bash test/smoke.sh（A–K 组：契约不变量守护）
```

### 不变量（v4 §2.2，每条有 smoke 守护，组 H）

- **I1** fail-open 主链路：除 guard 成功匹配的 block 外，任何故障不阻塞 harness。
- **I2** 注入资格守恒：只读 `playbook/facts/episodes/principles`，排除 `superseded_by`；inbox/lessons 永不注入。
- **I3** 人审前置：curate 是唯一入库口（含脱敏 + 指令样内容审查）；solidify→hook 须过 §8 准入四条件。
- **I4** 计数单点写：helpful/harmful 只由离线对账回填（`reconcile.jsonl`），禁止实时回路。
- **I5** 派生物可重建：manifest/索引是 gitignore 派生物，`index rebuild` 幂等。
- **I6** 命令面只增不减。
- **I7** git 写序列化：写命令遇 `index.lock` 重试（单写者约定），重试耗尽则不留半成品。
