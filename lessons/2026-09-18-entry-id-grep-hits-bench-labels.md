---
id: entry-id-grep-hits-bench-labels
type: lesson
status: candidate
scope: project:evo-kernel
domain: tooling
tags: [evo-kernel, grep, audit, retrieval-bench, labeling, false-positive, references]
triggers:
  - "在 evo-kernel 里用 `rg -l <条目 id>` / grep 判『这条经验被谁引用了 / 有没有被用上』"
  - "候选条目明明很少，命中清单里却出现 test/retrieval-bench/labeling/ 下的文件（失败信号）"
  - "审计条目使用率、清理 related 或判 superseded 前，要区分真引用和评测标注文件"
  - "claims.txt / labels.json 出现在 grep 结果里，被当成该条目被消费/被引用的证据"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-53a8-73b1-bdd8-c2dbfa58d618
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [forensic-grep-self-hit-current-session, evo-get-not-found-verify-via-catalog-before-existence-claim]
---

# 用条目 id 查引用会命中评测标注文件：claims.txt / labels.json 不是引用证据

## 一句话主张

evo-kernel 的 `test/retrieval-bench/labeling/` 下，`claims.txt`（切片首行写着
`# 现役条目 76 条（id | zone | 主张首行）`）按设计**列出全部现役条目**，同目录的 `labels.json`
是同一套评测标注产物；因此拿任何条目 id 去 `rg -l` / grep，都**必然**命中它们。
这类命中只能证明"该 id 在现役条目清单里"，不能当"这条经验被谁引用 / 被用上"的证据——
查引用前要显式排除该目录（如 `rg -l <id> . -g '!test/retrieval-bench/**'`）。

## 为什么

这与"搜索者自命中（当前会话文件进结果集）"是**另一类**假阳性：
自命中来自观察者副作用，标注文件命中来自"文件本身就是全量 id 清单"。
在审计条目使用率、判断某条是否只被自己引用、清理 `related` 或决定 `superseded_by` 时，
若把标注文件命中算成消费者，会得出"这条被多处引用"的错误结论，且错误方向是把**死条目判成活的**。

## 边界

- `labels.json` 的内容本会话**没有展开读**（只看到它被同一条 `rg -l` 命中）；它与 `claims.txt`
  同属 `labeling/` 评测目录，但"同样是全量清单"这一点只由 `claims.txt` 的内容佐证，引用时注意口径。
- 同一次搜索里的其它命中（如 `./playbook/2026-07-27-warn-rule-…`）不受本条影响，仍要逐条看是不是真引用。
- 本条只针对 `test/retrieval-bench/labeling/`；别的评测/标注目录是否存在同类文件未验证。
- 与「引用方命中」是方向相反的第三类假阳性：`related:` 是纯文本 id 引用，引用方文件里原样存着被引 id，
  所以 `rg -l <id>` 的命中集合天然是「1 个定义 + N 个引用/提及」；命中非空只证明该 id 在库里出现过，
  证明不了任何单个命中文件是本体（折叠/查重时误读，会把引用方内容当成被查 id 的条目内容）。
- 要按 id 定位**定义**（而非统计引用），搜 `rg -l "^id: <id>$" playbook/ lessons/ facts/`；
  命中文件名与搜索串相同只是启发式（日期前缀不必等于 id），别用文件名反推。只做存在性判断时任意命中都够用，
  区分角色只在把命中读成「定义位置/条目本体」时才必要。

## 证据（session 01a0b2ce 命令 ↔ 结果）

- `rg -N --no-heading -l "substring-matcher-cannot-tell-exec-from-mention" . -g '!ops/proposals/*'` →
  命中 `./test/retrieval-bench/labeling/claims.txt`、`./test/retrieval-bench/labeling/labels.json`、
  `./playbook/2026-07-27-warn-rule-m…`（排除规则只挡了 `ops/proposals/`，没挡评测目录）。
- `head -60 test/retrieval-bench/labeling/claims.txt` → 首行 `# 现役条目 76 条（id | zone | 主张首行）`，
  其后逐条是 `id [zone] 主张首行` 形态的清单，证明它是全量条目表、不是引用方。
- `sed -n '60,220p' test/retrieval-bench/labeling/claims.txt` → 延续同一清单（如
  `[playbook] \`git add -- <a> <b> <c>\` 是**全有全无**的…`），没有"谁引用了谁"的语义。
