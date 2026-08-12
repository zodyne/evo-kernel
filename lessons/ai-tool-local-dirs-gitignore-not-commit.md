---
id: ai-tool-local-dirs-gitignore-not-commit
type: lesson
status: candidate
scope: global
domain: git-hygiene
tags: [gitignore, ai-tooling, claude, workspace-drafts, repo-hygiene]
triggers:
  - "git status 出现 .claude/ .grok/ _workspace/ 等 AI 工具配置或设计会话产物目录"
  - "决定工具本地配置/过程稿目录该提交、删除还是加 .gitignore"
  - "AI 辅助开发的本地配置被误提交进仓库（失败信号）"
  - "给仓库补 .gitignore，枚举哪些非源码产物该忽略"
created: 2026-08-10
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019febb9-0322-7070-b2cc-57b137bdeda1
last_verified: 2026-08-10
superseded_by: null
schema_version: 1
---
# AI 工具本地配置与设计过程稿目录入 .gitignore，前提是结论已沉淀

## 主张

仓库里出现 AI 工具产物目录时分两类处置：① 工具本地配置（`.claude/` 等）——直接加 `.gitignore`，与已忽略的同类（`.grok/`）同等待遇；② 设计会话过程稿（`_workspace/` 等）——**先确认其决策结论已沉淀到正式位置**（docs/adr/、CLAUDE.md），才可加 `.gitignore`。过程稿本身不入库，但它的结论必须先有正式落点，否则忽略等于丢决策依据。

## 证据

algommw 仓库清理会话（本 session）：

```
$ git add .gitignore && git commit -m "chore: gitignore 收录 .claude/ 与 _workspace/(AI 工具配置与设计会话过程稿,不入库)" && git status
↳ [refactor/single-pipeline 33dec33] chore: ... 1 file changed, 5 insertions(...)
```

提交成功，工作区干净。处置依据（会话末条总结）：`.claude/` 与已忽略的 `.grok/` 同等待遇；`_workspace/` 是 ADR 0007 设计会话过程稿，决策结论已沉淀在 `docs/adr/0007` 和 CLAUDE.md，故过程稿本身无需入库。

## 反例/边界

- 若过程稿里的结论**没有**沉淀到 ADR/正式文档，直接 gitignore 会造成决策依据丢失——先把结论搬进正式文档再忽略。
- 团队共享的工具配置（如项目级 `.mcp.json`、共享 prompt 模板）不属于本条，该提交的要提交。
