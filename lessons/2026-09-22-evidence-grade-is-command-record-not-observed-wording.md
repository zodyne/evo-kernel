---
id: evidence-grade-is-command-record-not-observed-wording
type: lesson
status: candidate
scope: global
domain: verification
tags: [verified-by, evidence-grade, command-evidence, prose-summary, injection-weight, schema]
triggers:
  - "给条目标 verified_by，拿不准该标 command 还是 human"
  - "一手来源里写了「实测」「验证过」，但通篇没有命令与输出"
  - "同一批入库的条目，有的证据节引命令、有的只复述结论，却标了同一个证据等级"
  - "发现某条目的注入权重与它的证据强度不匹配"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:2a5c9cfe-7ff2-46f2-800e-c160ffe842a5
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [label-evidence-source-type-per-recommendation, source-term-mismatch-downgrades-citation-support, report-schema-claims-need-live-ground-truth, retry-rewrite-log-dedup-by-key, rewriting-firsthand-source-two-fixed-failure-modes]
---

# 证据等级的判据是「有没有可复执行的命令记录」，不是来源里有没有写「实测」

**主张**：`verified_by` 直接影响注入权重（`VERIFIED_W` = test 1.0 / command 0.8 / human 0.6 / none 0.4，
乘进注入分数），所以它必须按**证据的可复执行性**标，不能按来源的**措辞**标。
来源是 prose 摘要（哪怕里面写着「实测」「验证过」「2026-09-20 实测」），
只要**没有命令与输出的转录**，就不够 `command`——标错的代价是给未验证的说法多发 33% 的权重。

## 证据（2026-09-22，命令 ↔ 结果）

- **两组数要用两条命令量，口径不同（本会话最初把两条并成一条，被独立评审逮到）**：
  ① `awk 'f&&/^## /{exit} /^## 证据/{f=1} f' <entry> | grep -cE '→|rc=|exit=|http=|bytes'`
  → 由会话 capture 改写的 8 条得 `1 1 0 0 0 0 0 0`；reflector 写的
  `bsd-grep-empty-subexpression-hard-error` 得 **2**。
  ② 换口径数「含行内代码跨度的行」（`grep -cE '`[^`]*`'`）时，同一条对照得 **7**。
  → 引数必须带口径；且正确的 range 是 `f&&/^## /{exit}`（最初的 `awk '/^## 证据/,/^## /'`
  会塌成表头单行、对所有条目一律返回 0）。
- 12 条 capture：**9 条无任何命令样式标记，3 条含内联命令片段或箭头**
  （`capture-2026-09-19-05-52-06-809-ku93` / `-09-50-30-335-wegs` / `-02-50-31-391-qy1t`）——
  但 12 条**都不含「命令 ↔ 输出」的转录块**。（「全部纯 prose、无一条带命令」是被自己那次
  grep 输出否证的写法，不要用。）
- 整改后 8 条标 `human` 并写明降级依据；**8 条没有写升级路径**（那句在第一轮整改时被删掉了，
  见 commit 1019166）——写有升级路径的是另外 **3 条文档证据条目**（commit 6d366bb）。
- `govWeight()` 核验的 **0.24 → 0.18**（= 0.6/0.8 的 25% 削减）是对**那 3 条**跑的，
  不是对 8 条——引用时别记到 8 条头上。

## 边界 / 反例

- **不是「prose 一律不许标 command」**：本库既有条目里，引用确定性产物内容的（如
  `distill-log-done-line-is-the-completion-ledger` 引 `distill.log` 的固定行）标了 `command`，
  那是对的——判据是**能不能指出一条确定性的、别人可以重跑或重读的命令/产物**，不是来源的文体。
  真正不够的是「只有结论复述、指不出任何产物的那一句」。
- 反方向同样要防：`human` 不等于弱证据。核心主张依赖**语义判断**（如「这个机制在来源里到底有没有」）
  时标 `human` 是准确的，不是打折。
- **本条自己标 `human`**：命令只支撑「数出来是多少」，不支撑「该按可复执行性定级」这条规则本身
  —— 规则是语义判据。（同一会话里用同一组 0/N 证据的姊妹条目也标 `human`；
  若本条标 `command` 会比它多发 33% 权重，恰好是本条所反对的。）
- 范围：8 条 / 12 条是**本会话一批（n=1）**的核对实例，不要读成「prose 来源普遍如此」。
- 升级路径要写在条目里（「跑一次 X 即可证伪，通过后升回 command」）——但注意
  **不要写成「跑一次 X 即可复现」**：那是断言现象会重现，属于新的无据断言
  （见 `rewriting-firsthand-source-two-fixed-failure-modes`）。
