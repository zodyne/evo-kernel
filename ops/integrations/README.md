# 集成件副本（存续用）

这里放的是**装在仓库外、但系统运行必需**的集成文件副本。仓库自身可由 git 恢复，
这些不能——丢了就要凭记忆重写，而 §4.2 声称的是可恢复。

| 副本 | 实际安装位置 | 装法 |
|---|---|---|
| `pi-evo-kernel.ts` | `~/.pi/agent/extensions/evo-kernel.ts` | `cp ops/integrations/pi-evo-kernel.ts ~/.pi/agent/extensions/evo-kernel.ts` |

Claude 侧的 hook 接线在 `~/.claude/settings.json`（三条：UserPromptSubmit→hook-recall、
SessionEnd→hook-session-end + evo-distill-trigger.sh、PreToolUse→hook-guard），
不在此处留副本——doctor 第 6 项直接检查挂线，缺了会报出来。

**副本会过期**：doctor 第 16 项比对实装文件与本副本，不一致即 WARN。改了实装记得同步回来。
