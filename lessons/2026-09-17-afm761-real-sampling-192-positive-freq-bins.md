---
id: afm761-real-sampling-192-positive-freq-bins
type: fact
status: candidate
scope: project:algommw
domain: radar-dsp
tags: [algommw, afm761, range-fft, real-sampling, mirror-truncation]
triggers:
  - "移植/对拍 AFM761 range FFT，距离维 bin 数对不上上游（失败信号）"
  - "问 AFM761 real 采样下 range 谱哪些 bin 有物理意义"
  - "配置 profile.toml 的 [cfar] min_range_bin / 距离截断，担心切掉真实距离"
  - "距离维出现对称假峰/镜像峰，怀疑复数谱负频率没排除"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae37-a909-77c1-a593-51c0d61c185c
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [algommw-profile-single-config-source, mmw-cpp17-port-golden-equivalence]
---

AFM761 是 real 采样，range FFT 只有 192 个正频率 bin 有物理意义；`profiles/afm761_ddm/profile.toml` 的 `[cfar]` 段以 `min_range_bin` 配置项承载"镜像截断"语义（`min_range_bin = 0` 后跟 ⛔ 注释说明此背景）——距离维有效口径是 192 个正频率 bin，不是 FFT 全长。

**为什么**：移植或对拍时若按 FFT 全长/复数谱 bin 数处理距离维，会把无物理意义的镜像 bin 一并送 CFAR，产生镜像假峰、点数对不上 golden；上游已把这条口径写死在 profile 注释里，移植前先对齐它。

**边界**：192 对应的 FFT 长度/采样率切片未给，不得反推；该注释在切片输出中被截断，`min_range_bin` 数值与 192 的精确关系（0 是否即取全部正频率 bin）未完整取证，只断言注释所述事实。

**证据**：slice 命令↔结果第 6 条：`sed -n '85,140p' profiles/afm761_ddm/profile.toml` ↳ `[cfar] peak_group_scheme = "det_matrix" min_range_bin = 0 # ⛔ 镜像截断:AFM761 是 real 采样,range FFT 只有 192 个正频率 bin 有物理意义。 # 复…`（行尾截断）。
