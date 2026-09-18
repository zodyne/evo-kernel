---
id: numpy-fftshift-takes-axes-not-axis
type: lesson
status: validated
scope: global
domain: python-numpy
tags: [numpy, fft, fftshift, keyword-argument, api-trap]
triggers:
  - "numpy 里写 fftshift(x, axis=...) 报 TypeError（失败信号：fftshift() got an unexpected keyword argument 'axis'. Did you mean 'axes'?）"
  - "同一行里 np.fft.fft(x, axis=1) 正常，np.fft.fftshift 却报关键字错误"
  - "写频谱 / 距离-多普勒处理脚本，fftshift 那一步从没跑通"
  - "照 MATLAB fftshift(X, dim) 或 scipy.fft.fftshift(x, axes=) 的习惯写 numpy 版"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ef-b8f1-777c-a410-327bb9fe35ad
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# np.fft.fftshift / ifftshift 的关键字是 axes=，不是 axis=

## 主张

`np.fft.fftshift` / `np.fft.ifftshift` 的轴关键字是 **`axes=`**（可接 int 或 tuple），传 `axis=` 直接抛 TypeError；而同一行里的 `np.fft.fft(x, axis=1)` 恰恰只能用 `axis=`——变换类函数用 `axis`、shift 类函数用 `axes`，两套关键字不能互相套用。

## 为什么

numpy 的 FFT 模块里 `fft/ifft/rfft` 等走 `axis=` 语义，而 `fftshift/ifftshift` 走的是"可一次 shift 多个轴"的 `axes=` 语义（历史 API 分裂）。排查时容易被报错行误导：报错指向 fftshift 那一行的关键字，而写的人往往刚在上一行成功用过 `axis=`，于是转去怀疑维度/shape。

## 证据（session 01a0a7ef 切片，命令 ↔ 结果）

- 首次运行失败：`python3 analyze.py "<...>/865_0801_2025-10-09-11-40-04_0.bin" 1` → `Traceback ... File "/private/tmp/bpm_check/analyze.py", line 193, in <module>  report_frame(p, ...`。
- 就地修关键字：`sed -i '' 's/fftshift(np.fft.fft(s0 * dwn, axis=1), axis=1)/fftshift(np.fft.fft(s0 * dwn, axis=1), axes=1)/; ...' analyze.py` —— 只把 **fftshift 的** `axis=1` 改成 `axes=1`，内层 `np.fft.fft(..., axis=1)` 原样保留。
- 重跑即恢复并出结果：`=== 865_0801_2025-10-09-11-40-04_0.bin frame 1 rangeBin 3 (R=3.327 m) === mean|X| across Rx: 25532.3 ...`。
- 落笔时在本机 numpy 2.3.4 复核关键字语义：`np.fft.fftshift(np.zeros((2,3)), axis=1)` → `TypeError: fftshift() got an unexpected keyword argument 'axis'. Did you mean 'axes'?`；`np.fft.ifftshift(..., axis=1)` 同样报错；两者换成 `axes=1` 均正常返回 `(2, 3)`。

## 边界 / 反例

- 报错信息自带建议（`Did you mean 'axes'?`），看到这条直接按提示改即可，不必去查 shape / dtype。
- 不要顺手把同行的 `np.fft.fft(..., axis=1)` 也改成 `axes=`——那才会引入新错误；两套关键字分属不同函数族。
- `axes=` 支持 tuple（一次多轴 shift），`axis=` 从来不是 fftshift 的合法关键字，与 numpy 版本无关（2.3.4 实测）。
