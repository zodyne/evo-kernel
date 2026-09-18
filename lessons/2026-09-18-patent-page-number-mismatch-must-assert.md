---
id: patent-page-number-mismatch-must-assert
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [patent, google-patents, verification, scraping, external-reference]
triggers:
  - "按专利号抓 Google Patents 页面（patents.google.com/patent/<号>/en）做核验或引用"
  - "抓回的专利页面里读到的专利号与 URL 里请求的号不一致（失败信号）"
  - "curl 抓到的 HTML 直接抽标题/正文当某专利的证据，没做号一致性断言"
  - "核验简报里的专利引用，要判断抓回来的到底是不是被引的那一件"
  - "同一专利 URL 重复抓取，一次拿到页面一次 HTTP=000"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7b9-3ee0-777c-a410-327021f18732
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [http-200-may-be-bot-check-page, curl-o-code-000-no-output-file, verify-external-references, citation-pure-number-ref-doi-misread-crossref]
---

# 按专利号抓回的页面不等于该专利：解析后必须断言「页面自报号 == 请求号」

## 主张

用 `patents.google.com/patent/<号>/en` 抓 HTML 做核验时，**URL 里的号不保证等于页面内容的号**。本次请求 `US10627483B2`，curl 成功落盘 274814 字节的 `pat.html`，从页面里抽出的标题却是 `US12174311B2 - Empty band doppler division multiple access …`——请求号与页面自报号不一致。凡是要把抓回的页面当某专利的一手证据，**解析后必须先断言页面里的专利号与请求号一致**；不一致就停下换号/换源，不能默认「URL 决定内容」。

## 为什么

这是形状完全正确的静默错误：HTTP 成功、文件几百 KB、HTML 可解析、正文读得通，唯一异常是号对不上。若直接拿正文段落当目标专利的教导去核验简报或写结论，引用形式看起来毫无破绽（"US10627483B2，第 X 段"），错的是内容归属，事后极难发现——比抓取失败（空文件/000）危险得多，因为它会被当成成功样本。

## 证据（切片命令 ↔ 结果，逐字摘）

```
$ cd /tmp && curl -s --max-time 40 -A "Mozilla/5.0" "https://patents.google.com/patent/US10627483B2/en" -o pat.html; ls -la pat.html; python3 - <<'PY' …
  ↳ -rw-r--r--@ 1 zodyne  wheel  274814 Sep 15 21:12 pat.html TITLE: US12174311B2 - Empty band doppler division multiple acc
```

后续同一条命令（同一 URL，第二次抓取）返回 `HTTP=000 size=0`、`pat2.html` 不存在，下游脚本报 `[Errno 2] No such file or directory`——同一 URL 的可抓性也不稳定（该失败模式本身见 related）。

## 边界 / 未做的确认

- **不判定成因**：切片只能证明「请求号与抽取到的号不一致」这一可观测事实，无法区分是服务端返回/跳转到了同族另一件，还是抽取脚本在页面里抓错了号元素（相关链接区、同族列表都含大量 `US\d+B\d+`）。两种成因下**动作相同**：断言一致，不一致即停。
- 本条只管「抓回来的东西是不是那一件」；抓取失败的另两类形态（code=000 不落盘、200 但正文是反爬页）判据不同，见 related。
- 一致性断言要写在解析脚本里（`assert extracted_number == requested_number`），而不是靠人眼扫一眼标题。
