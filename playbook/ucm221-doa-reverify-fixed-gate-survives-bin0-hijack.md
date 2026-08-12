---
id: ucm221-doa-reverify-fixed-gate-survives-bin0-hijack
type: bullet
status: validated
scope: project:ucm221
domain: radar-doa
tags:
- ucm221
- doa
- 暗室
- 固定门
- eta校准
- 数据质量
- 采集完整性
triggers:
- UCM221 新采集数据集上复验测角，bin0/bin3 比值接近或超过 1
- 看到 bin0>bin3 就判测角失效（失败信号：只杀峰值搜索不杀固定门）
- 大角度测角误差增大，要区分算法极限还是数据质量
- 跨采集会话复用 eta 校准 LUT
- 接收新采集的暗室数据集，做完整性检查
created: 2026-08-12
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: 人工（整理 inbox/capture-2026-07-29-05-28-46-708-615w.md）
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related:
- ucm221-chamber-doa-bin3-fixed-gate-rx-pair
---
# UCM221 测角复验：固定门不怕 bin0 反超；大角度失效是数据质量；eta 需逐会话 LUT

在 20260713 暗室数据集上参数化复跑（`analysis/rx_pair_doa.py --chamber`）的四条结论：

**①固定 bin3 下"bin0>bin3"≠测角失效**：峰值劫持只杀峰值搜索，不杀固定门（Hann 窗整 bin DC 音副瓣 -78dB 再实证）。新数据 bin0/bin3 在 0° 已达 0.49，但方位可用至 ±65°、俯仰全程 ±51°。

**②大角度失效是数据质量而非算法极限**：杂波基底 vs 方向图滚降决定边界，**边界随信杂比移动**——不要把某数据集上的失效角度当成算法固有限制。

**③eta（角度相关相位偏差）随采集会话变化**：旧数据俯仰正侧欠估、新数据过估——eta 非标定常数，**逐会话 LUT 校准必要**，不能跨会话复用。

**④新采集数据集要做完整性校验**：实测发现 8 文件尾部截断、俯仰 +6° 缺文件、存在" (2).bin"重复下载副本名——采集流程需完整性校验（文件数、尾部完整性、重名副本）。

**反例/边界**：结论①成立的前提是泄漏未污染 bin3 本身（实测污染量级见 related 泄漏条目）；用峰值搜索而非固定门的链路不适用①。

**证据**：capture-2026-07-29-05-28-46-708-615w（复验实测数据如上）。
