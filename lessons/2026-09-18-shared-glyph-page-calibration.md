---
id: shared-glyph-page-calibration
type: playbook
status: candidate
scope: global
domain: document-processing
tags: [scanned-book, image-compare, calibration, page-brightness, normalization, formula-audit]
triggers:
  - "跨页比较字形粗细/墨水质量，两页扫描浓淡不一"
  - "同一字母两页笔画宽度不同，分不清是字体差异还是扫描深浅"
  - "图像统计指标跨页直接比，数值差与印刷差异混在一起（失败信号）"
  - "要给跨页字形对比找页内基准或共享字形做归一化"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad64-2a2e-7710-933f-0b6734543245
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [bold-vs-italic-stroke-width-metric, image-ascii-raster-visual-inspection-without-vision]
---

跨页比较字形特征（笔画宽度、墨水质量）前，先量两页共有的非数学字形（括号、标点等，其印刷粗细与被判字母无关）做页间校准：共享字形质量接近（±10% 量级）⇒ 两页印刷/扫描条件同源，被判字母间远超此波动的大幅笔画差是真实字体差异；共享字形本身差异大 ⇒ 先做页间归一化再比较，否则不下结论。

**为什么**：扫描件墨水浓度逐页漂移，不校准就会把「整页浓淡差」误读成「字体粗细差」，或反向把真实差异洗白成扫描伪影。本会话 p053（黑体版式页）与 p090（普通版式页）对比 U 字粗细时，先跑共享字形对照确认页间可比，才下「p053 U 为粗体、p090 U 为细体」的结论。

**证据**（命令↔结果）：
- `shared glyph mass, p090 / p053: '(' p053= 149.0 p090= 161.1 ratio=1.081 ')' p053= 141.5 p090= 159.6`——共享括号质量页间差仅 ~8%；
- 同批输出 U 对照：p053 U mass=399.1 mass/h^2=0.366 vs p090 U1 295.6/0.271、U2 292.9——U 差距 ~35%，远超共享字形波动；
- stem 口径同向印证：p053 U 8.38–8.40px vs p090 U1 5.88px。

**边界**：共享字形要与被判字形同区块、同字号（上下标小字形墨水系统性偏细，不能当大字号判别的基准）；页内基准优先用同页已知形态的同类字形（本会话用同页同字号的斜体 k/p 做页内细体基准）。
