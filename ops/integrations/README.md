# 集成件副本（存续用）

这里放的是**装在仓库外、但系统运行必需**的集成文件副本。仓库自身可由 git 恢复，
这些不能——丢了就要凭记忆重写，而 §4.2 声称的是可恢复。

| 副本 | 实际安装位置 | 装法 |
|---|---|---|
| `pi-evo-kernel.ts` | ~~`~/.pi/agent/extensions/evo-kernel.ts`~~ | **已退役**（pi harness 2026-08 移除，文件仅存溯源） |
| `hermes-evo-hooks/*.sh` | `~/.hermes/agent-hooks/`（3 个 adapter） | `cp ops/integrations/hermes-evo-hooks/evo-*.sh ~/.hermes/agent-hooks/` |

Claude 侧的 hook 接线在 `~/.claude/settings.json`（三条：UserPromptSubmit→hook-recall、
SessionEnd→hook-session-end + evo-distill-trigger.sh、PreToolUse→hook-guard），
不在此处留副本——doctor 第 6 项直接检查挂线，缺了会报出来。

**Hermes 侧的 hook 接线在 `~/.hermes/config.yaml`**（hooks 段三条：pre_llm_call→evo-recall.sh、
on_session_end→evo-session-end.sh、pre_tool_call→evo-guard.sh），
doctor 第 7 项直接检查挂线，第 16 项比对副本漂移。

**adapter 职责**（Hermes payload → evo Claude 契约，详见 design-v2-hermes-cc.md §6.3）：
- `evo-recall.sh`：`extra.user_message` → `prompt`；输出 `{"context": ...}` 注入（pre_llm_call）
- `evo-session-end.sh`：`session_id` 透传；transcript 传 `'?'` 哨兵（Hermes 会话在 SQLite 无文件路径）
- `evo-guard.sh`：`tool_name/tool_input` 透传；evo deny → `{"decision":"block"}`，warn/allow → `{}`
- 全部 I1 fail-open：失败输出 `{}` 不阻断

**副本会过期**：doctor 第 16 项比对实装文件与本副本，不一致即 WARN。改了实装记得同步回来。
