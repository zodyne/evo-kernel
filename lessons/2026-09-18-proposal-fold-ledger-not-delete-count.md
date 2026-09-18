---
id: proposal-fold-ledger-not-delete-count
type: lesson
status: candidate
scope: project:evo-kernel
domain: evo-kernel
tags: [proposal, dedup, fold, ledger, acceptance, distill]
triggers:
  - "把一批重复提案折进已有条目（fold/merge）后收尾，准备拿『已删 N 条』当完成证据"
  - "提案条数与被补强条目数对不上（本会话 16 条被删 vs 14 个条目文件被改），说不出哪条没落地（失败信号）"
  - "需要逐条交代每条提案的归宿：并进哪个条目 id、有没有带增量（a/b）"
  - "批量删除/合并任务只有删除计数，没有逐条台账"
  - "要给出可审计的完成判据（0 unexamined）而不是『都处理完了』自述"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0b305-5741-73b1-bdd8-c2df7eb6de3f
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [rejected-proposals-are-invisible-to-dedup-base, proposal-independent-review-before-curate, verify-numbered-list-full-coverage-by-regex-count]
---

**主张**：折叠重复提案这类「删 + 并」任务的完成凭证是**逐条台账**——每条提案 → 目标条目 id + 是否带增量（a=并进目标条目 / b=纯重复无增量）+ 补了什么——再以覆盖数 `0 unexamined` 收尾。**删除条数不等于折叠完成度**：本会话 16 条提案被删、只有 14 个条目文件被补强，两个数本来就可以不同（存在只删不并的 b 类）；只看"删了多少"区分不了「全部并进去了」与「全部直接丢了」。

**为什么**：删除不可逆，a（增量已并入目标条目）与 b（无增量纯重复）在删除后从工作区里同样消失；`catalog` 只覆盖还在的提案，删掉后不留痕（见 related `rejected-proposals-are-invisible-to-dedup-base`）。没有逐条台账，事后既无法复查某条主张到底进没进库，也无法判断这次折叠是否覆盖了全部提案——删除计数相同可能是 16 并 0，也可能是 0 并 16。

**证据（会话 01a0b305 切片）**：
- 末条 assistant 逐字：`All 14 supplemented files parse as valid YAML; 16 proposals deleted; 0 unexamined.`
- 同一条消息里的逐条台账表头：`| slug | a/b | 目标条目 id | 补了什么（若 a） |`，首行 `| bash-guard-blocks-nonrecursive-grep-cwd-home | a | 2026-09-…`（切片按 200 字符截断，表体其余行不可见）。
- 「写/改文件」段列出 14 个被改条目文件（如 `playbook/2026-09-16-bash-guard-blocks-pathless-recursive-scan.md`），与「16 条提案」数目不同，佐证删除数与补强数不相等。

**边界 / 反例**：
- **验证等级如实标 `human`**：台账是 agent 的收尾自述，切片里没有逐条复核归宿的命令+结果，表体多数行被截断，只有首行可见，`0 unexamined` 也无人独立计数。
- 若任务保证每条提案都带增量（全部 a），则删除数与补强数一致，计数可自证；b 类一旦存在（或两条提案命中同一目标文件），计数就失效——这正是要台账的原因。
- 台账本身也可能自我背书（把自报的目标 id 再抄一遍）；更硬的收尾是在台账之后对"被改文件"再跑一次机械检查（本会话那一步是对 14 个文件逐个做 YAML 解析）。

**失败信号（未来命中即该想起本条）**：折叠/合并批处理的收尾只写「已删除 N 条」，没有每条提案 → 目标条目 id 的对照，也没有覆盖数。
