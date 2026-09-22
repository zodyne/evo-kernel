---
id: retire-doc-scan-residual-refs
type: lesson
status: candidate
scope: global
domain: documentation
tags: [doc-retirement, dead-reference, git-rm, ripgrep, git-show]
triggers:
  - "退役/删除被 git 跟踪的旧版文档（PLAN.v1、旧方案、旧规格）"
  - "git rm 旧文档后，不知道全仓还有哪些引用指向它"
  - "残留引用指向已删除路径（失败信号：引用处 test -e 不存在）"
  - "收尾报告想写『已无活引用』，需要一份能机械复查的 grep 记录"
  - "旧文档删除后仍希望以后能取回原文"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b3d9-1442-7475-af70-367c26fa603f
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [docs-code-path-refs-existence-scan]
---

# 退役旧文档的收尾判据是「残留引用全部有下文」，不是「文件删掉」

**主张**：删除被 git 跟踪的旧文档（本会话是 `PLAN.v1.md`）前后各做一次全仓引用扫描；删除后 `rg -n "<文件名>" --hidden -g '!.git'` 的每条残留引用都要分诊——活引用改写，历史性提及统一写成 `git show <sha>:<path>` 形式并实测能取回，不能把「文件已删、grep 只剩几条」直接当作清理完毕。

**证据（本会话命令 ↔ 结果）**：

- `git rm -q PLAN.v1.md && rg -n "PLAN\.v1" --hidden -g '!.git'` → 删除后剩余 `./PLAN.md:4:> v1 原稿已退役：`git show 1a0ae80:PLAN.v1.md`（v1 独有内容的承接清单见 ./docs/audit/2026-0…`：残留的不是死路径，而是带 sha 的取回指针。
- 一致性复核 `rg -c 'PLAN\.v1' --hidden -g '!.git' .` → 仍有 3 个文件命中：`./PLAN.md:1`、`./docs/audit/2026-09-18-plan-v2-conformance.md:3`、`./docs/adr/0001-freeze-layout-not-api.md`——计数非零，证明「删文件」不等于「无引用」，必须逐条分诊是否为可长期留存的历史说明。
- 取回验证：退役后 `git show 1a0ae80:PLAN.v1.md` 仍能取出全文（输出 408 行），说明指针不是断链。

**为什么**：文件被删除后，「谁还在引用它」不会在 `git status` 里出现。残留引用分两种命运——活文档里指向该路径的引用会变成断链，历史性提及（审计报告、ADR、版本注记）应保留但要给出取回办法。`git show <sha>:<path>` 是 sha 锚定的不可变对象引用，比写「见 xxx.md」的路径指针更耐搬动。

**边界/反例**：`git show` 指针成立的前提是旧文档曾经被提交进 git 且有可用的 sha；本会话删除前已确认 v1 独有内容另有承接（见 related 条目的扫描思路）。引用扫描只覆盖非 .git 工作树，`-g '!.git'` 不能省；本会话的 4718594 等独有数字承接另见同会话产出的 `retire-doc-remeasure-hardcoded-metrics`。
