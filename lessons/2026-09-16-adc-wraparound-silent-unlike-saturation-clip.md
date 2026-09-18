---
id: adc-wraparound-silent-unlike-saturation-clip
type: lesson
status: candidate
scope: global
domain: embedded
tags: [adc, quantization, wraparound, saturation, embedded, dsp, silent-failure]
triggers:
  - "定点/ADC 溢出检测：回绕（wraparound）与钳位（saturation）行为不同"
  - "回绕模式下溢出计数静默失声（失败信号）"
  - "实现/审查 ADC 量化溢出计数与饱和告警"
  - "int16 溢出回绕后码值仍落在合法范围，看不出异常"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a4ee-6d56-777c-a410-3236022192ef
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: []
---

# ADC 回绕 vs 钳位：回绕后码值仍合法，不单独统计就静默失声

## 主张

定点 ADC 溢出有两种：钳位（clip 到 ±32767）和回绕（wraparound 折回 ±(2^15−1)/−2^15）。**回绕后码值仍落在 ±32767 的合法范围内**，若只按「码值是否越界」判断溢出，回绕溢出完全统计不到，饱和告警静默失声。回绕必须单独计数（如统计折回次数），不能复用钳位模式的溢出数。

## 证据

- `[FAIL] 回绕模式同样报溢出计数（否则饱和告警会静默失声）`：`回绕 2071955 个码值 = 钳位模式的 2071955 个；回绕后码值仍落在 ±32767 内（所以不统计就完全看不出来）`。
- 修正断言（负轨 = −2^15 的 peak_code+1）后 `[PASS]`：`回绕后码值被折回 ±(2^15−1)/−2^15`。

## 边界

- 针对「看起来正常、实则溢出」的静默故障类；钳位模式溢出可见（码值顶到边界），回绕不可见。
- 通用到任何定点溢出计数，不止雷达 ADC。
- 判别钳位/回绕的实测签名：同一浮点输入下统计逐分量误差与符号翻转——钳位误差随过驱线性增长且符号翻转=0（单音 1.2×FS：`max|eI|=6143.5 LSB=18.75% FS`、`RMS(err)=4097.2 LSB`、翻转 0/4096），回绕在折回点翻转符号；只看码值越界两者分不开，必须统计误差。
- 误差上界两端不对称：负轨 −2^15（−32768）、正轨 2^15−1（32767），按 ±(2^15−1) 写对称断言会漏掉负半轴 1 LSB。
