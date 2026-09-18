---
id: archived-entry-inbound-related-sweep
type: lesson
status: candidate
scope: project:evo-kernel
domain: evo-kernel
tags: [related, archive, dangling-link, audit, frontmatter]
triggers:
  - "把条目从 lessons/playbook/facts 移进 ops/archive/（或改条目 id）"
  - "归档后 evo audit 报 related 指向不存在/已归档条目（MID/LOW）（失败信号）"
  - "批量搬运、清理、归档条目之后做收尾自查"
  - "顺着某条目的 related 跳转却跳到空，或跳到一个不该再读的旧条目"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a4d2-e53f-7341-b816-247fbf0b3018
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [frontmatter-edit-must-use-setfmfield]
---
**主张**：归档不是「把文件 mv 走」就结束——条目一旦离开入库区（或改了 id），其它条目 frontmatter 里指向它的 `related:` 就成了**悬挂引用**：比没有链接更误导（导航断链，且 audit 报 MID/LOW）。归档动作必须包含「全库扫入链」这一步：对每个待归档/待改名的 id 跑 `grep -rn '^related:.*<id>' lessons/ playbook/ facts/ episodes/ principles/`，命中处同步清理或改写。

**为什么**：`related` 是纯文本 id 引用，不随文件移动而更新。文件式知识库没有双向回写，指向方（其它条目）在归档时不会收到任何信号；而悬挂链接只在「有人顺着链接读」或「audit 跑」时才暴露，中间可以潜伏很久。

**证据**（session 01a0a4d2 的 slice「命令 ↔ 结果」）：
- 定位：`find ops/archive -name …` → 被引用的 `transcript-parser-normalize-tool-names` 已在 `ops/archive/candidates-unverified-2026-09-14/`（归档发生在 9/14，悬挂潜伏数日）。
- 命中：`grep -n '^related:' lessons/2026-08-25-claude-session-jsonl-drops-pasted-images.md lessons/2026-08-25-pil-row-scan-verifies-terminal-render.md` → 两条条目的 `related:` 都指向该已归档 id。
- 修复：改写两条 frontmatter 后 push `e47af22..0937797`，提交标题 `fix: 清两条悬挂 related 链接 —— 指向已归档条目（audit LOW 归零）`。

**边界/反例**：确实需要保留历史指向时，应把说明写进正文（「X 已归档到 ops/archive/…」）而不是留在 `related:` 字段——audit 只按 id 是否存在判定，`related` 里放无效 id 永远算悬挂。改 id 的场合同理，扫的就是旧 id；批量归档后应跑 `./bin/evo audit` + `npm test` 收尾，而不是只确认文件已移走。
- 同症状（audit MID）、不同成因：**写入时就把注定消失的 id 当成了条目**。`related:` 只写当时存在于 SCAN_DIRS（lessons/playbook/facts/episodes/principles）里的 id；`ops/proposals/` 既不在 SCAN_DIRS 也不在 `evo catalog` 覆盖内，折叠重复提案时若为了记「并入自哪条提案」把被折提案的 id 追加进目标条目，而提案就在同一动作里被 `rm`，断链当场成立 —— 这条只能在写 `related` 那一步拦住，事后扫是补不回来的。来历写进正文或 commit message。
- 检测口径：frontmatter/YAML 解析检查**抓不到**悬挂引用 —— 实测一次批量 fold 收尾只跑了 yaml 解析（`OK … | id= … | last_verified= …`），两条 MID 全部漏过；要抓只能跑 `./bin/evo audit`，或对 `^related:` 做全库 id 存在性对账。
