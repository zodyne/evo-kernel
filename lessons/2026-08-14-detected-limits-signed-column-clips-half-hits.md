---
id: detected-limits-signed-column-clips-half-hits
type: lesson
status: candidate
scope: global
domain: radar-signal
tags: [detected, cfar, limits, signed-column, doppler, bridge]
triggers:
  - "detected 库 Limits.min/max_signed_column 与 signed_column 语义"
  - "桥接层 cfg.limits 填 {0,rows-1,0,cols-1} 后命中数少一半"
  - "CFAR 命中被静默滤掉一半且无任何错误码（失败信号）"
  - "多普勒负速度侧的点全部丢点"
  - "合成矩阵左右对称放峰，看哪边消失来定位坐标域裁剪"
created: 2026-08-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-14-04-40-13-458-asej
last_verified: 2026-08-14
superseded_by: null
schema_version: 1
related: [cfar-cross-lib-equivalence-baseline-first]
---

# 主张

detected 库的 `Limits.min/max_signed_column` 是「**有符号列**」——`signed_column` 把后半列映射为负数（多普勒负速度侧）。桥接层写成 `cfg.limits={0,rows-1,0,cols-1}` 会静默滤掉一半命中，且无任何错误码。

# 定位手法

合成矩阵在左右对称位置放同样的峰，看哪边消失——**命中丢失只与列号相关、与数据无关**即可判定为坐标域裁剪 bug。

# 证据

SUC221 实测：默认配置 486→1105 命中，藏掉 56%。
