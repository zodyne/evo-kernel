---
id: image-rect-left-edge-from-data-axis-first-element
type: lesson
status: candidate
scope: global
domain: visualization
tags: [imageitem, rect, fftshift, doppler-axis, rd-map, coordinate-mapping, silent-offset]
triggers:
  - "给二维矩阵（距离-多普勒谱/时频图/多普勒-距离图）设 ImageItem 的 rect / 视图范围"
  - "fftshift 过的速度/频率轴，图上目标位置整体偏 N/2 个 bin（失败信号）"
  - "rect 左边界写成不含数据轴首元素的对称假设（如 -dv/2、-N·dv/2）"
  - "核对图像 rect 与数据轴是否对齐：打印 rect.left() 与 axis[0]-step/2 比对"
  - "刻度看着正常、读出的速度/频率却整体差一个固定常数（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a82c-5169-7719-ba82-3202517e50bb
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [gui-pick-coordinate-roundtrip-verify, pyqtgraph-imageitem-setrect-after-setimage]
---

# 图像 rect 的左边界必须由数据轴首元素推出：left = axis[0] − step/2

**主张**：给二维矩阵（距离-多普勒谱、时频图）设显示矩形/坐标范围时，左边界要用**数据轴的首元素减半步长**（`left = velocity_axis[0] - dv/2`），不能用"轴以 0 为中心"的对称假设（例如只写 `-dv/2`）。fftshift 过的轴首元素不是 0（Nc 点、步长 dv 时 `axis[0] = -Nc/2·dv`），对称假设会让整幅图 x 轴连同刻度、目标读数一起偏移 `Nc/2` 个 bin——**不报错、不崩溃，只是图上每个点的速度都差同一个固定量**。

**为什么**：bin 中心与像素边界差半步长，所以 rect 边界 = 首中心 − 半步长；而"轴首元素是不是 0"取决于处理链做没做 fftshift、点数奇偶如何。把左边界写成常数，等于把"axis[0] = 0"当成了不变量；该不变量一旦不成立（本例 Nc=64 的 fftshift 轴，`axis[0] = -32·dv`），偏差就是 `Nc/2` 个 bin，且没有任何断言会红。

**证据（本会话命令 ↔ 结果，session 01a0a82c）**
- 复现脚本自述即此现象：`/tmp/fix865/repro_s1.py` 的 docstring ——「S1 复现：探测矩阵 x 轴（速度）是否整体偏 32 bin」。
- 修复后实测几何自洽：`python3 /tmp/fix865/repro_s1.py` → `rect = QRectF(-12.556915, -0.836023, 24.727464, 856.087082)  viewRange x = [-12.5569153640521...`。由此算：`dv = 24.727464/64 = 0.386367`，`left/dv = -32.5`，即 `left = -(Nc/2 + 0.5)·dv = axis[0] - dv/2`，与"偏 32 bin"里的 `Nc/2 = 32` 互相印证。
- 落地的写法：`rg -n "vel0 - dv|..." spc865/ui/views.py` → `1248:  return QtCore.QRectF(vel0 - dv / 2.0, -dr / 2.0, nd * dv, nr * dr)`（`vel0 = velocity_axis_mps()[0]`，常量取自 `BeamConfig.velocity_axis_mps()`）。同文件 18 行的距离轴约定是 `距离 = bin_index * range_resolution_m，**不加半 bin**`——两处合起来正是"边界 = 首中心 − 半步长"。
- 处理链确实做了零频居中：`rg -n "doppler_fft|fftshift" spc865/dsp.py` → `14: temp = fftshift(fft(squeeze(cube1D(ns,rx,tx,:)) .* dopplerwin)); % hamming(Nc)`。
- 会话末条修复报告（同一切片）写明改动：`_image_rect()` 左边界由 `-ΔV/2` 改为 `velocity_axis_mps()[0] - ΔV/2`。多普勒轴 fftshift 过，`axis[0] = -Nc/2·…`（切片 200 字符截断）。
- 收尾验收：`python3 -m pytest tests/python` → `273 passed in 6.54s  exit=0`（含 `tests/python/test_ui_views.py::test_doppler_profile_follows_max_target` 对 `rect.left()` 的断言）。

**边界 / 反例**
- 修复前的确切写法取自同一切片的末条修复报告；本次蒸馏**没有**独立命令复现"改前偏 32 bin"的对照（切片里 repro 打出的是修后几何）。本条最硬的部分是修后几何的数字自洽（-32.5·dv）+ 已落地的代码行，引用时对"改前"留一分保守。
- 只有当轴首元素确实不是 0 时对称假设才错：若轴本来就是 `0…(N-1)·d`（未 fftshift 的实数谱），`-d/2` 恰等于 `axis[0]-d/2`，本条不适用。
- 半步长加不加取决于约定（本仓库距离轴明确"不加半 bin"，速度 rect 则是"首中心 − dv/2"）；要点是**rect 边界由轴首元素推**，不是照抄某个常数。

**失败信号（未来命中即该想起本条）**
- 图上目标"看着在动、位置也对"，但读出的速度/频率整体差同一个常数（尤其差 `N/2` 个 bin）——先怀疑 rect 左边界而不是 FFT 或符号约定。
- 审代码时看到 rect 左边界是不含 `axis[0]` 的常数表达式 → 立刻打印 `rect.left()` 与 `axis[0]-step/2` 比对。
