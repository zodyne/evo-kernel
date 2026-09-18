---
id: claude-json-project-keys-are-paths
type: lesson
status: candidate
scope: global
domain: harness-config
tags: [claude-code, claude-json, migration, project-paths, dry-run]
triggers:
  - "把项目目录从 ~/Desktop 搬到 ~/Dev 或归档目录之后"
  - "~/.claude.json 的 projects 里出现指向已不存在路径的键（失败信号）"
  - "脚本改写 ~/.claude.json 的 projects：键和值都是绝对路径"
  - "搬迁后 Claude Code 在新路径下看不到项目历史"
  - "改 ~/.claude.json 前想先验证新路径存在"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a8c1-5e3e-710a-b61a-fd2478c30f87
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [claude-code-global-mcp-registry-claude-json, mcp-server-add-remove-align-three-registries]
---

**主张**：`~/.claude.json` 的 `projects` 是以**绝对路径为键**的 map；目录一旦搬迁，旧键立刻变成失效条目（本机从 `~/Desktop` 搬走后出现 `[★已失效] /Users/zodyne/Desktop/OpenRadar` 等），修复必须**键名和值同时改**——只改值不键改名，等于把数据留在旧 key 下。

**为什么**：多数配置是「键=逻辑名、值=路径」，改值就够；这里键本身就是路径，`json.dump` 写回时必须 delete 旧键 + 写新键。改前先跑 DRY 校验每个新路径真实存在（全绿再落盘），并确认 Claude Code 进程没在运行、`head -c` 看一眼原始缩进格式，避免把运行中的实例覆盖回去或把格式改脏。

**边界/反例**：归档目录（`~/Documents/桌面归档-2026-09-16/目录/pyside_radar`）这类路径也可以作为新键写入；映射规则要在 DRY 输出里逐条可见（`→ 新路径` / `键改名 旧 → 新`），否则实跑时无法复核。本机 `~/.claude.json` 同时也是 MCP 注册表（见 related），改这份文件的风险面是整份全量配置，务必先备份。

**证据**（session 01a0a8c1，evo slice 「命令 ↔ 结果」）：
- 现状盘点：`[存在] /Users/zodyne/Desktop`、`[★已失效] /Users/zodyne/Desktop/OpenRadar`、`[★已失效 …`。
- `DRY=1 python3 /tmp/fix-claude-json.py` → `新路径存在性校验`：`✓ /Users/zodyne/Dev/liborion`、`✓ /Users/zodyne/Dev/SR61_datapath`、`✓ /Users/zodyne/Dev/OpenRadar-de…`。
- `DRY=0` 实跑输出含 `→ /Users/zodyne/Documents/桌面归档-2026-09-16/目录/pyside_radar` 与 `键改名 /Users/zodyne/Desktop/workflow → /Users…`（键值同改）。
- 改前原始格式确认：`head -c 200 ~/.claude.json` → `{ "numStartups": 558, "installMethod": "global", …`；并已检查 Claude Code 是否在运行（`pgrep -fl "claude"`）。
