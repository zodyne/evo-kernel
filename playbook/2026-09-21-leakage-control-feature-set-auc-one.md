---
id: leakage-control-feature-set-auc-one
type: lesson
status: validated
scope: global
domain: machine-learning
tags: [leakage, feature-engineering, auc, control-experiment, threshold-learning, radar]
triggers:
  - "用带 GT 标签的数据训练/评估门限或分类器"
  - "特征里含与标注口径同源的量（距离门、多普勒、SNR 门、标签生成用的中间量）"
  - "学习模型的 AUC 顶到 0.99+ 或明显超过手工判据基线，怀疑泄漏（失败信号）"
  - "设计『学习阈值 vs 手工判据』的对照实验，要说清增益来源"
  - "写实验报告准备声称「学习模型超过现有规则」"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bcf1-4733-7265-ada1-fb36116f6be1
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [calibration-set-not-validation-set, recalibrate-thresholds-before-comparing-sets]
---

# 学习门限实验必须带「含泄漏特征」对照组：AUC 1.0000 只能来自泄漏

## 主张

做"学习门限 / 学习判据"实验时，固定跑一组"含泄漏特征"的对照——把 距离门 / |多普勒| 这类与标注口径同源的量放进特征：本例 000028 含泄漏 AUC 1.0000 / 召回 99.70%，而无泄漏快照内对照 AUC 0.9558 / 97.00%。AUC 顶到 1.0 只可能来自泄漏；没有这组对照，"学习模型 AUC 0.97 > 现有判据 0.9554"的结论无法排除泄漏解释。

## 为什么

现有判据（s = p1·cos(γ−γ₀) 一类）本身就在 0.95+ 的量级，AUC 上升几个千分点很容易被当成真实增益。当特征里混入标签生成链路上用到的量（距离门、多普勒这类门限/采样口径）时，模型可以直接复现标注规则，AUC 跳到 1.0。把已知的泄漏特征单列一组当"正对照"，是先证伪上限：含泄漏组也上不去，说明这些量没泄漏；上去了，则在真实模型里剔除它们并重新解释增益。

## 证据（session 01a0bcf1，suc221-pointcloud-2.0）

- 实验协议（本会话落地 `docs/design_bf/learned_threshold_study.py`）：`[A] 同场景学习（前半训练 → 后半评测）· 放行率匹配到 0.1714 -- 000028（正样本 3911 / 1,905,881 点） 基：s（现行判据） AUC 0.9554 召回 96.80%`。
- 泄漏对照：`[D] 泄漏对照（把 距离门 / |多普勒| 放进特征） 000028 含泄漏 AUC 1.0000 召回 99.70% ← 对照（快照内）：AUC 0.9558 召回 97.00%`。
- 结论被写进 `docs/design_bf/LEARNED_THRESHOLD.md`（同场景学习、放行率匹配、无标签在线的边界几节）。

## 边界 / 反例

- 切片未展开 GT 标签的生成细节；"距离门 / |多普勒| 与标签同源"是实验设计者的判定（实验即名为"泄漏对照"），本条引用的是它对 AUC 的量级影响，不复述标签构造规则。
- 对照组不改进模型，作用是否证上限；若含泄漏组 AUC 也只有 0.96，则这两个量不构成泄漏，需另找泄漏源。
- 特征泄漏与"标定集当验证集"（`calibration-set-not-validation-set`）是两类泄漏，都要防：前者在特征层，后者在数据划分层。

## 失败信号（未来命中即该想起本条）

- 学习/调参实验报告 AUC 0.99+，特征清单里却有直接参与标签定义的量。
- 拿"学习模型 AUC 0.97 > 现判据"当结论，但没有任何对照说明标签可分性的上限。

## 2026-09-22 独立复核增补

下列是复核时在本机跑过的**自包含最小复现**：

```
python3 - <<'PY'
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
rng=np.random.default_rng(0); n=40000
x=rng.normal(size=n); y=(x>np.quantile(x,0.2)).astype(int)   # 标签 = 关于 x 的确定性门限规则
tr,te=slice(0,n//2),slice(n//2,n)
for name,X in (("clean(no leak)",np.c_[x+rng.normal(size=n),rng.normal(size=n)]),
               ("leak",np.c_[x,rng.normal(size=n)])):        # leak 组把「规则自己的输入 x」放进特征
    m=LogisticRegression(max_iter=2000).fit(X[tr],y[tr])
    print(name, round(roc_auc_score(y[te],m.predict_proba(X[te])[:,1]),4))
PY
# 实测输出（本机 sklearn 1.8.0, numpy）:
#   clean(no leak)   held-out AUC = 0.8563
#   leak             held-out AUC = 1.0000
# 与条目主张同构：无泄漏特征 <1.0；把标签规则同源量放进特征 → AUC 顶到 1.0000。
```


**审核给出的修改意见（要点）**：三处改后即可留，并够格升注入集（真值是本机稳定的通用 ML 事实，已用自包含复现验证）：(1) 删掉或换成切片可核的表述——「学习模型 AUC 0.97」在切片里查无此数（grep 无 0.97），应改为「学习模型 AUC 高于现行判据 0.9554」或直接引用切片确有出现的 0.9558（快照内对照），不要留一个无从核验的 0.97。(2) 给绝对律加限定：标题与主张的「AUC 1.0000 只能来自泄漏 / 只可能来自泄漏」应改为「AUC 1.0000 是泄漏的强指示；本实验里唯有并入泄漏特征才达到」，并补一句边界——退化/极小评测集或本就可分的问题也可能给 1.0（我本次复现里 leak 组恰为 1.0000，也正说明 1.0 是『规则同源量可完全复现标签』的必然而非唯一诊断）。(3) 证据节注明命令状态：第 1 条 [A] 输出（AUC 0.9554）在切片里来自已被截断、且指向 /tmp/learned_thr.py 的命令，不可照抄重跑；持久载体 docs/design_bf/learned_threshold_study.py 在另仓且输入 *.bin 被 gitignore，本机亦不可复跑——把「命令被截断 / 依赖别仓快照数据」写清，避免读者照抄踩空。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 学习模型 AUC 0.97 > 现有判据 0.9554
- 当特征里混入标签生成链路上用到的量（距离门、多普勒这类门限/采样口径）时，模型可以直接复现标注规则，AUC 跳到 1.0
- AUC 顶到 1.0 只可能来自泄漏（标题亦作「AUC 1.0000 只能来自泄漏」）

**判定**：keep-with-fix · 拟 promote-playbook · 原证据快照风险=low · 复核时本机可复跑=true
