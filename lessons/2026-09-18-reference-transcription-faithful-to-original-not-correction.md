---
id: reference-transcription-faithful-to-original-not-correction
type: principle
status: candidate
scope: global
domain: transcription
tags: [transcription, fidelity, reference, scanned-book, manual-review]
triggers:
  - "转写参考文献 / 原文时发现疑似错别字、多余标点或异形字符"
  - "不确定原书的排版 / 笔误该照录还是该改正"
  - "转写稿里把原书自身的笔误顺手『修正』掉了（失败信号）"
  - "交付转写稿时不确定哪些地方该标『照原书』留人审"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0ad8f-3d86-7710-933f-0b7531a957ce
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: []
---

# 主张

转写参考文献 / 原文时，把「OCR 读错」与「原书排版如此」区分开——原书自身的笔误、多余标点、异形字符照录不改，只显式标出留人审，而不是擅自「修正」。

# 为什么

转写容易把原书的排版特征当成 OCR 错误顺手改正，反而偏离原文。照录 + 标注，才能在「忠于原文」与「供人复核」之间取平衡：宁可标 34 处不确定，也不静默留错或静默改错。

# 证据（人工判断级）

会话末条交付表对 `Moore. J B.` 多余句点、`Optimal Filtering .` 空格标「照原书」（原书排版如此，照录）；对标题「点迹—航迹」的长横标「原书可能排作 一」（真正拿不准，标注留人审）——即把不确定处分成两类，而不是一刀切改正。

# 边界 / 反例

- 判据是原图像素：裁图看到「错误」也出现在像素里，就是原书如此（照录）；像素与 OCR 不同，才是 OCR 读错（改正）。这依赖像素比对，见 scanned-book-reference-transcription-text-layer-plus-pixel-verify。
- 只对「转写/忠实原文」类任务适用；编辑润色、纠错校对类任务不套用「照录不改」。
