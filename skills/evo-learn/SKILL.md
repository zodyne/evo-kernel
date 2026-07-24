---
name: evo-learn
description: 收工蒸馏（进化引擎入口）：任务完成后把本次的成败经验提炼入 Evo-Kernel。每个非平凡任务收工后应运行；用户说"记下来"、"这个教训要存"、"learn"时必须使用。
---

# Evo Learn — 收工蒸馏（Reflector→Curator）

## 流程（四步，提案须人审后入库）

1. **抽硬证据切片**（不要凭记忆写经验）：
   ```bash
   evo slice --session <会话文件> [--ids <session_id>]
   ```
   Pi 会话文件由 session 管理器给出；`--ids` 会列出本次注入过的条目 id 供对账。
2. **对账**（若本次有注入）：对照切片判断每条注入四态——`adopted`（被遵循）/`relevant-unused`（相关未用）/`irrelevant`（无关）/`misleading`（误导返工）。由 Reflector 写入 `ops/log/reconcile.jsonl`（计数单点写，I4）。
3. **写提案**到 `<EVO_ROOT>/ops/proposals/<date>-<slug>.md`：
   - 严格按 `<EVO_ROOT>/SCHEMA.md` frontmatter；**triggers 必填**（3-5 个"什么情境下该想起我"，含任务形态+失败信号）；
   - **失败经验与成功经验同等蒸馏**（ReasoningBank）；只写有硬证据支撑的（verified_by 如实标 command/test/human/none）；
   - 增量 delta：一条提案一个原子主张，禁止把多条揉成一个文件。
4. **入库（人审后）**：
   ```bash
   evo curate --file <提案> --to <lessons|playbook|facts|episodes>
   ```
   默认进 lessons/（candidate）；有直接硬证据且当场可复验的可进 playbook/。

## 原则
- 不确定入哪 → lessons/（candidate 暂存队列）。
- 提案未获用户确认前不要 curate。
