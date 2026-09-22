---
id: wtr10-firmware-range-window-tukey-16tap
type: fact
status: candidate
scope: project:wtr10
domain: radar-signal
tags: [wtr10, 窗函数, tukey, 旁瓣, 距离谱]
triggers:
  - "分析 WTR10 距离谱泄漏/旁瓣，需要知道固件实际用的窗"
  - "dss_data_path.c 里距离 FFT 前那 16 个窗系数（0.08 + 0.92 组合）是什么窗"
  - "WTR10 距离谱最大旁瓣约 -13 dB，怀疑窗与 TI 默认 Hann 不一致（失败信号）"
  - "估 WTR10 泄漏污染时找不到等效窗的 3dB 主瓣宽/相干增益损失"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bdef-64b5-738d-af4a-290ada962882
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [suc221-leakage-far-exceeds-hann-sidelobe, noncoherent-sum-statistic-dof-2nk]
---

# WTR10 固件距离窗：首尾 16 抽头的 Tukey（α≈3.1%），不是 Hann

## 主张

WTR10 DSS 固件在距离处理前施加的窗是首尾各 16 抽头、系数形如 `0.08 + 0.92 × hann32 前半支` 的等效 Tukey 窗（α≈3.1%），不是 TI 默认 Hann/Hamming。其实测指标：3 dB 主瓣宽 ≈0.90–0.91 bin、最大旁瓣 ≈−13.3 dB（出现在 1.5 bin）、相干增益损失 −0.13 dB。

## 证据（session 01a0bdef，wtr10）

- 系数来源：`high_accuracy_68xx_dss/dss/dss_data_path.c` 的 16 个系数（命令注释：`0.08 + 0.92*hann32 的前半支`）。
- 复算输出：`固件等效窗(Tukey α=3.1%)  3dB主瓣宽 0.91 bin  最大旁瓣 -13.3 dB (在 1.5 bin)  相干增益损失 -0.13 dB`。
- 窗对比表复现同一行：`固件等效窗(首尾16抽头) -13.3  0.90 ...`。
- 对照：同一批复算里独立核对 Hann（`np.hanning(sym)`）最大旁瓣 −31.47 dB、3 dB 主瓣 1.44 bin。

## 边界 / 反例

- 数值来自按固件系数做的 numpy 复算（源文件与切片命令一一对应），未做上板实测；换固件版本/换配置前应重新核对系数。
- 引用该窗做泄漏污染估算时注意：−13.3 dB 旁瓣意味着比 Hann（约 −31.5 dB）高近 18 dB，把 Hann 的理论泄漏量直接搬来会低估。

## 2026-09-22 独立复核增补

下列是复核时在本机跑过的**自包含最小复现**：

```
cd /Users/zodyne/Dev/wtr10 && sed -n '627,642p' wtr10_v3.00/project/high_accuracy_68xx_dss/dss/dss_data_path.c && python3 - <<'EOF'
import numpy as np
coef=np.array([0.0800,0.0894,0.1173,0.1624,0.2231,0.2967,0.3802,0.4703,0.5633,0.6553,0.7426,0.8216,0.8890,0.9422,0.9789,0.9976])
print("matches 0.08+0.92*hann32[:16]:", np.allclose(coef, 0.08+0.92*np.hanning(32)[:16], atol=1e-4))
N=1024; NF=2**18
fw=np.ones(N); fw[:16]=coef; fw[-16:]=coef[::-1]
def met(w):
    W=np.abs(np.fft.rfft(w,NF)); W/=W[0]; d=20*np.log10(W+1e-30)
    k=np.argmax(d<-3); frac=(d[k-1]+3)/(d[k-1]-d[k]); width=2*(k-1+frac)*N/NF
    s=np.diff(d); idx=np.where(np.diff(np.sign(s))>0)[0]; fn=idx[0]
    return width, d[fn+np.argmax(d[fn:])], 20*np.log10(w.mean())
a,b,c=met(fw);   print("fw   : 3dB %.2f bin  旁瓣 %.1f dB  CG %.2f dB"%(a,b,c))  # 期望 0.90 / -13.3 / -0.13
a,b,_=met(np.hanning(N)); print("hann : 3dB %.2f bin  旁瓣 %.2f dB"%(a,b))          # 期望 1.44 / -31.47
EOF
```


**审核给出的修改意见（要点）**：主张无误、数值全部复验通过，问题只在证据节与一处措辞，按下面改后即可留候选： 1) 证据第 1 条：切片里读系数的 heredoc 被截断（`c=np.array([0.080`），不能照抄重跑。把「系数来源」改成可复查的锚点：dss_data_path.c:626-642（win1DLength=16 起 16 个 win1D 赋值），并注明「系数值不在切片里，直接读源文件核对」。同时保留「命令注释」这一措辞（源文件确无该注释）。 2) 证据第 4 条：切片里 Hann 的 3dB 主瓣被截断成「1.4」；「1.44」是复算真值而非切片可见值，建议注明。 3) 主张/标题里的「不是 TI 默认 Hann/Hamming」：切片只证了「不是 Hann」。Hamming 我已复算（−42.67 dB，同样不是），但「TI 默认」的归属无本仓证据。要么删 Hamming/TI 默认 这半句，要么标明「Hamming 为另行复算、TI 默认窗归属未核」。 4) 可选：在证据节补一条自包含最小复现（见 minimalRepro），使 -13.3/0.90/-0.13 与 Hann 1.44/-31.47 不依赖被截断的会话命令。 不建议升 playbook：本条真值绑在外部仓 /Users/zodyne/Dev/wtr10 的固件快照（哪一版固件硬编码哪 16 个系数），属 project

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 「不是 TI 默认 Hann/Hamming」中的 Hamming 一半：切片只做了 np.hanning 对照，全程未与 Hamming 比较；「TI 默认」这一归属也非切片/产物所证。Hann 一半有切片支撑。

**判定**：keep-with-fix · 拟 keep-lessons · 原证据快照风险=high · 复核时本机可复跑=true
