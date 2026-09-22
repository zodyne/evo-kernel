---
id: claude-file-history-snapshot-diff
type: playbook
status: validated
scope: global
domain: claude-code
tags: [claude-code, file-history, forensics, diff, config-drift]
triggers:
  - "要查 ~/.claude 下某个文件（settings.json / 配置 / README）被哪个会话、什么时候改成了什么"
  - "文件 mtime 很新但没人承认改过，需要编辑前后的基线做 diff（失败信号：手上只有当前内容）"
  - "多个 Claude Code 会话并发写同一目录，想把某次改动归因到具体会话"
  - "要在没有 git 的目录（如 ~/.claude/claude-router/）里做文件级回滚对比"
  - "看到 ~/.claude/file-history/<uuid>/<hash>@v1 这类快照文件，不确定能不能当旧版本用"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0c1f4-ba46-7370-8301-baf14cc85c89
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [artifact-mtime-adjacency-not-call-attribution, forensic-grep-self-hit-current-session, claude-session-jsonl-drops-pasted-images]
---

# ~/.claude/file-history/<会话 uuid>/<hash>@v1 是文件旧版本快照，与当前文件 diff 即可还原某次编辑

**主张**：排查 `~/.claude` 下文件被谁改成什么样时，`~/.claude/file-history/` 里按会话 uuid 分目录保存着该会话写过的文件旧版本快照（形如 `<hash>@v1`）。
用 `diff <(cat ~/.claude/file-history/<会话uuid>/<hash>@v1) <当前文件>` 就能得到一次编辑的前后差异；
目录 mtime 反映该会话最近一次快照写入的时间，可用来把改动归因到会话与时间点。

**为什么**：`~/.claude/file-history/` 下的目录名与 `~/.claude/projects/<项目>/<会话 uuid>.jsonl` 的会话 uuid 同名，
说明快照按会话隔离保存；快照文件是编辑前内容，与当前文件 diff 即可看到这次编辑改了什么，不需要 git。

**证据**（本会话切片，命令 ↔ 结果）：
- `ls -lat ~/.claude/file-history/ | head -12` → `drwxr-xr-x@ 7 zodyne staff 224 Sep 21 11:16 2ab7b394-c85...`；
  同一 uuid `2ab7b394-c859-42dc-8a4d-28d7720c8d24` 也出现在 `~/.claude/projects/-Users-zodyne-Dev-ant-design-mimo-2t8r-antenna-spec/2ab7b394-....jsonl` 路径里。
- `cd ~/.claude/file-history/2ab7b394-.../ && for f in *; do sz=$(stat -f %z "$f"); echo "--- $f ($sz b...`
  → `--- 451c41cb9a0363c2@v1 (3040 bytes, 11:16:37) --- # claude-router 本机回环上的模型路由器（<localhost>:<port>），让*`。
- `diff <(cat 451c41cb9a0363c2@v1) ~/.claude/claude-router/README.md` → `16,17c16,17`，
  旧版两行是 `cd ~/Dev/claude-router && npm install` / `ln -sf ~/Dev/claude-router/com.zod...`，
  与搬迁后的新路径不同，证明快照确实是被编辑前的旧内容。

**边界 / 反例**：
- 本会话只对 1 个文件、1 个快照做了 diff 验证；`@v1` 是否覆盖全部写操作、删除/重命名文件是否留快照，均未验证。
- 快照文件名是哈希，不知道对应哪个文件时要靠内容判断；不要仅凭快照存在就断言它是最新一次编辑的前一份。
- 目录 mtime 与写入时间的对应关系在本会话只有一处观察（目录 11:16、快照 11:16:37），不要当精确时间源。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
cd ~/.claude/file-history/2ab7b394-c859-42dc-8a4d-28d7720c8d24
# 1) 快照=旧内容（稳定）：v1 里是搬迁前的 ~/Dev/claude-router
head -3 451c41cb9a0363c2@v1      # → "# claude-router" / "本机回环上的模型路由器（`127.0.0.1:41777`）..."
# 2) 相邻快照 diff 才隔离出「那一次编辑」（本机实测稳定）
diff 451c41cb9a0363c2@v1 451c41cb9a0363c2@v2
#   期望含： 16,17c16,17  < cd ~/Dev/claude-router && npm install  →  > cd ~/.claude/claude-router && npm install
# 3) 反例：与"当前文件"diff 得到的是累积差异，不是一次编辑
diff 451c41cb9a0363c2@v1 ~/.claude/claude-router/README.md | grep -c '^[<>]'   # → 33（原证据的 16,17c16,17 已漂成 16,19c16,17）
# 4) 目录 mtime = 该会话最近一次快照写入时间
stat -f '%Sm %N' -t '%Y-%m-%d %H:%M:%S' .   # → 2026-09-21 11:50:24 == 最大快照 96d8840298a9d059@v2 的 11:50:24
```

**审核给出的修改意见（要点）**：改三处后留在 playbook。①**收窄一般律**：把标题与主张从「与*当前文件* diff 即可还原某次编辑」改成「与*相邻快照* @vN vs @v(N+1) diff 才隔离出一次编辑；与当前文件 diff 得到的是『该快照→当前』的*累积*差异，只有当该快照恰是最后一次编辑前内容时才等于一次编辑」。②**换证据（必须）**：证据节第 3 条 `diff @v1 当前README` 的输出已从 `16,17c16,17` 漂到 `16,19c16,17`（累计 33 行），不再是确定性产物——换成 `diff 451c41cb9a0363c2@v1 451c41cb9a0363c2@v2`（本机实测仍稳定给出那次搬目录编辑 `~/Dev/claude-router`→`~/.claude/claude-router`）。③**订正引用**：证据节第 2 条把 `<localhost>:<port>` 还原为切片里的字面 `127.0.0.1:41777`；并给第 2、3 条标注「切片中命令尾部截断（`stat -f %z` 格式串 / `cat \"$f\"` / `~/.claude/cl...` 路径），不能照抄重跑」。附：目录 mtime 那条现已有第二个观测（目录 11:50:24 = 最大快照 mtime 11:50:24），可从「边界」上移进主张。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 标题/主张：`diff <(cat ~/.claude/file-history/<会话uuid>/<hash>@v1) <当前文件>` 就能得到**一次编辑**的前后差异 —— 本机复跑证伪：v1 vs 当前 README 现为 33 行累积差异（三段输出），只有与**相邻快照** @v1-vs-@v2 diff 才隔离出一次编辑。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
