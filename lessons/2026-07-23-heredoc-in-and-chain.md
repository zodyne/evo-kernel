---
id: heredoc-in-and-chain
type: lesson
status: candidate
scope: global
domain: shell-scripting
tags: [bash, heredoc, and-chain, debugging]
triggers:
  - "bash 命令里用 heredoc 写文件"
  - "&& 长链组合多个命令"
  - "下游报 ENOENT 但文件'明明创建过'"
  - "复合命令一半执行一半没执行"
created: 2026-07-23
evidence: {helpful: 1, harmful: 0}
verified_by: test
source: session:evo-kernel-bootstrap
last_verified: 2026-07-23
superseded_by: null
---
`&&` 长链中混入 heredoc（`cmd1 && cat > f << 'EOF' ... EOF`）时，若前序命令失败，heredoc 的 cat 不执行、文件不创建——但**换行分隔的后续命令照常执行**，下游报 ENOENT 时容易误判成"文件创建步骤出了问题"而非"上游失败了"。
**做法**：heredoc 写文件与 && 执行链拆成独立步骤；每步后验证产物存在（`ls`）再进下一步。
**证据**：evo-kernel 实施中 jiti 测试命令失败 → prop-dedup.md 未创建 → 下游 `evo curate` 报 ENOENT，实际是上游断链。
