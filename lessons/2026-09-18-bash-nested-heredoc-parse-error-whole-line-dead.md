---
id: bash-nested-heredoc-parse-error-whole-line-dead
type: lesson
status: candidate
scope: global
domain: shell-scripting
tags: [bash, heredoc, syntax-error, compound-command]
triggers:
  - "bash 命令里嵌套两层 heredoc（内层写在外层 body 里）"
  - "复合命令报 syntax error: unexpected end of file，拆开每段单看都对"
  - "想给含 heredoc 的失败命令挂 || 兜底重试"
  - "一条带 heredoc 的长命令解析就失败、什么都没执行"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad78-0edd-7710-933f-0b684c017e93
last_verified: 2026-09-18
superseded_by: null
related: [heredoc-in-and-chain]
---
`python3 - <<'EOF' … || (mkdir -p … && python3 - <<'EOF2' …)` 这种把内层 heredoc 写进外层 body 的嵌套写法在 bash 里解析期直接失败（`syntax error: unexpected end of file`，exit 2），且**整行命令一条都没执行**——heredoc 之前的部分和 `||` 右侧的兜底分支全都轮空；`||` 是执行期短路，救不了解析期错误。
**做法**：嵌套 heredoc 不塞一行，拆成两条独立命令顺序执行；写含 heredoc 的复合命令先做只解析不执行的语法检查再上真命令。
**边界**：`&&` 链 + heredoc 的另一坑是运行期断链（上游失败 → cat 不执行 → 下游 ENOENT），见 related；本条是解析期整行死，两者症状不同（syntax error vs ENOENT）。
**证据**：切片命令 `python3 - <<'EOF' > /tmp/texcheck/gap.tex … || (mkdir -p /tmp/texcheck && python3 - <<'EOF2' …)` → `✗ /bin/bash: -c: line 21: syntax error: unexpected end of file, Command exited with code 2`；下一轮拆成单段 heredoc 后成功编译 53 条公式（0 错误）。
