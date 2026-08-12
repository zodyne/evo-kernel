---
id: track-gap-attribution-viewport-gate-vs-filter
type: lesson
status: candidate
scope: project:ucm221
domain: tracking
tags: [ucm221, tracking, attribution, viewport-gate, faf, ab-test]
triggers:
  - "faf/过滤器输出的航迹覆盖率不满、中间或尾部断裂"
  - "航迹断裂第一反应怪过滤器误杀或跟踪器丢失"
  - "faf_offline 离线程序的俯仰/方位视场门限筛点"
  - "A/B 两组航迹覆盖缺口要逐段归因"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fbb55-aff3-7aa0-937b-51eaddbeab92
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [ucm221-marginal-points-support-track-continuity]
---
# 航迹覆盖缺口归因：逐帧回溯"原始点还在不在"，先分清视场门限筛除 vs 过滤误杀

## 主张

faf_offline 输出航迹出现覆盖缺口时，**不要直接怪过滤器或跟踪器**：对缺口窗逐帧查"原始点云里最近点是否还存在、超没超程序自己的视场门限"。两类缺口归因不同、修法不同——原始点还在但标 MARGINAL → 过滤器门槛问题（放行 MARGINAL 可修）；原始点被离线程序的俯仰门限（±30°，`offANGLE_DOWNSIDE/UPSIDE`）筛掉 → 与过滤器无关，是程序视场限制。

## 证据（000034，GT=legacy 长命航迹 705 帧）

- 覆盖率对比：faf（只放 KEEP）636/705 = 90.2%，缺 f1085..1139(55帧) 与 f1442..1455(14帧)；faf-mar（KEEP+MARGINAL）694/705 = 98.4%。
- 中段缺口 f1085..1139：断裂窗内逐帧回溯，原始最近点**仍在**（f1078 处 3.09m、标签 MARGINAL）→ 过滤器门槛问题，faf-mar 确实补上了这段。
- 尾部缺口 f1442..1455：逐帧俯仰角 `el 31.8° / 32.0° / 32.1° / 32.2° ... ↑ 超出 ±30° 俯仰门限` → faf-mar 也救不回，因为点根本没进处理链（main.c 视场门限 `#define offANGLE_DOWNSIDE (-30.0f) / offANGLE_UPSIDE (30.0f)`）。

## 边界

- 归因方法依赖落盘的原始点（points_in.npy）还在；若离线程序不落盘过滤前点云，此法无从用。
- ±30° 是 faf_offline 示例程序的取值，不是 faf 模块本身的限制；别的程序门限取别的值。
