---
id: pdf-text-lacks-urn-verify-identity-via-landing-page
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [pdf, provenance, urn, repository, verification, thesis]
triggers:
  - "从机构库/大学库（qucosa 等）下载学位论文 PDF 后要确认拿到的是不是目标那一篇"
  - "在下载 PDF 的抽取文本里 grep URN / nbn / 机构库 id，命中 0（失败信号）"
  - "把『正文里 grep 不到标识』当成下错了、或当成论文里没写"
  - "核验别人给的论文链接/附件 URL，要证明下载物的身份"
  - "报告要写文献来源 URL 与持久标识，需要一条可复现的核对路径"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7b9-3ee0-777c-a410-327021f18732
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [verify-external-references, pdftotext-md5-roundtrip-verify-corpus-integrity, unverified-arxiv-ids]
---

# 机构库 PDF 的正文里可能没有 URN：下载物身份核验不能靠 grep 正文，要回 landing page + 首页题名

## 主张

从机构库（本次为 TU Dresden qucosa）按附件 URL 下载的学位论文 PDF，`pdftotext` 抽出的**正文文本里可能一个 `nbn:de:bsz:14-qucosa2-…` URN 都没有**（`grep -c "qucosa" gonzalez_thesis.txt` → `0`）。因此「我下载的到底是不是目标那一篇」**不能靠 grep 正文自证**，要落到两条外部路径：机构库 landing page（本次请求 → `HTTP=200`）+ PDF 首页题名页（`pdftotext -f 1 -l 3`，本次得 `Technische Universität Dresden / A Low-Power Multiprocessor Systems-on-Chip Architecture for Smart Dense Radars`）。

## 为什么

按 URL 下载的产物身份，默认被「URL 正确」背书；但 URL 只证明你请求了什么。想在文本层找持久标识来自证时，会得到一个**假阴性**（grep 0 命中），容易被误读成「下错了」，或者反过来，在没有标识的情况下默认「既然从那个 URL 下来的，就是那篇」。正确姿势是把身份核验绑在**下载入口元数据**（landing page / 首页题名）上，而不是正文内容——正文里有没有 URN 是文档排版的偶然属性。

## 证据（切片命令 ↔ 结果，逐字摘）

```
$ cd /tmp && pdftotext -f 1 -l 3 gonzalez_thesis.pdf - 2>/dev/null | head -40; echo "=== nbn/urn ==="; grep -o "nbn:de:bsz:14-qucosa2-[0-9]*" gonzalez_t…
  ↳ Technische Universität Dresden  A Low-Power Multiprocessor Systems-on-Chip Architecture for Smart Dense Radars  M. Sc. H…
$ cd /tmp && echo "Diaz:"; grep -c "Diaz" gonzalez_thesis.txt; echo "urn/nbn in txt:"; grep -c "qucosa" gonzalez_thesis.txt; echo "=== qucosa landing pa…
  ↳ Diaz: 1 urn/nbn in txt: 0 === qucosa landing page (94103 vs 941034) === HTTP=200 url=https://tud.qucosa.de/landing-page/
```

（`grep -c` 返回 0 而非报错，说明 `.txt` 存在、确实无匹配；下载本体另见同会话的 86300446 字节 PDF 。）

## 边界

- 「正文里没有 URN」是这份 PDF 的实测事实，**不等于**所有机构库 PDF 都不印 URN（页脚/封面是否进文本层取决于排版）。稳妥动作是**先查 landing page，再抽首页题名比对**，不要用正文 grep 的 0 命中下任何身份结论。
- 本条与 related 的分工：那几条管「文本语料是否损坏/截断」「外部 id 是否真实存在」；本条只管「下载物身份怎么核」。
- 首页题名比对要读到题名+机构+学位信息那一屏（`-f 1 -l 3` 够用）；只 grep 文件名不可靠（文件名是下载方命名的，不是文档属性）。
