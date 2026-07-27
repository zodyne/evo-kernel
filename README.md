# Evo-Kernel

个人「经验治理与固化层」内核：纯文件 + git 存储，Node CLI（`evo`），被 Pi 扩展 + Claude Code hooks 两个 harness 共用。

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
