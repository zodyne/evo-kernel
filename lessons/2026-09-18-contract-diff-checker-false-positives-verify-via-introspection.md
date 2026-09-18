---
id: contract-diff-checker-false-positives-verify-via-introspection
type: lesson
status: candidate
scope: global
domain: verification
tags: [契约核对, checker, false-positive, introspection, dataclasses, api]
triggers:
  - "写脚本把契约/设计文档里的 API、字段、签名与代码实现逐条比对"
  - "核对脚本报出 N 处『契约有、代码没有 / 签名不符』，准备直接写进验收报告"
  - "只改了核对脚本本身、没动被测代码，差异数就变了（失败信号：checker 自己制造差异）"
  - "要用运行时自省（dataclasses.fields / inspect.signature / 直接调用）复核差异清单"
  - "契约是散文或 markdown 表格，只能靠正则抽取字段名再比对"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a820-0f89-7719-ba82-3200eacbe826
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [checker-positive-control-or-negative-void, verify-external-references]
---

# 「契约文档 vs 代码」比对脚本的首版差异清单要先复核 checker 自身，再拿去报告

## 主张

自造核对脚本（从契约文档抽 API/字段/签名，再与代码逐条比）首次跑出的差异数**不是**被测代码的缺陷数：清单里混着 checker 自身的抽取/比对假阳性。下结论前先用运行时自省直接问对象（`dataclasses.fields(...)`、`inspect.signature(...)`、直接调用），并接受「只修 checker、差异数就会变」这一事实——差异数稳定之后，清单才值得逐条定性。

## 为什么

契约文档是给人读的散文/表格，checker 必须靠正则或文本规则把它变成结构再比对；这套抽取规则本身没有任何校验，抽错、切错边界照样输出「契约里有、代码里没有」。这类假阳性披着「我发现差异」的外衣，与真差异同形，最容易整批写进验收报告——它比假阴性更不容易被缺证据感拦住。

## 证据（本会话命令 ↔ 结果）

- `QT_QPA_PLATFORM=offscreen PYTHONPATH=/Users/zodyne/Dev/SPC865 python3 /tmp/spc865_api_check.py` → `=== 契约里有、代码里没有或缺签名不符 (13) ===`，首条为 `[缺失] spc865.config.BeamConfig 字段 ['flag']`。
- 只给 checker 自己打补丁（`p = pathlib.Path('/tmp/spc865_api_check.py'); s = s.replace(...)`，未动被审仓库代码），重跑同一脚本 → `=== ... (8) ===`。即首版 13 条里至少 5 条随 checker 修正而消失，是被 checker 制造出来的差异。
- 随后改用运行时自省取真值：`python3 -c "import dataclasses, spc865.config as c; B=c.BeamConfig; print([f.name for f in dataclasses.fields(B)])"` → 直接打印真实字段列表，不再依赖文本抽取。

## 反例 / 边界

- 与 `checker-positive-control-or-negative-void` 同族但方向相反：那条讲假阴性（可删/不存在结论）要先做阳性对照；本条讲差异核对里的假阳性，规则是「先让 checker 稳定，再报数」。
- 「只改 checker 差异数就变」是自查信号，不是结论本身：差异数稳定后仍要逐条定性（自省或实际调用），真差异也会稳定存在。
- 修 checker 不能以「差异清零」为目标：把抽取规则收窄到只剩自己已确认的条目，等于用假阴性换假阳性，要保留契约条目的覆盖对照。
