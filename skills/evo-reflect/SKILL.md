---
name: evo-reflect
description: 周期复盘（进化引擎的曲柄）：盘点 Evo-Kernel 指标、提出固化/下放/清理三类提案。每周固定运行；用户说"复盘/周报/reflect/系统体检"时使用。
---

# Evo Reflect — 周期复盘

## 输入
```bash
evo index rebuild          # 刷新 manifest（聚合 reconcile.jsonl delta）
evo reflect [--save]       # 含判据对照表（§7.3）：注入精度/覆盖率/降级/存续/观察期
evo audit                  # 治理发现
evo doctor                 # 部署自检
```

## 盘点指标（reflect 报告固定含判据对照表）
- recall 命中率与注入精度（reconcile.jsonl 四态）；对账覆盖率（<30% 精度不可解读，先修蒸馏纪律）；判定者分歧率（每周期抽 ≥10 例人工复核）；重复踩坑；candidate 积压；harmful>0 条目；90 天未验证；superseded 未清理；降级事件；transcript 失效比例。

## 产出：三类提案 → `<EVO_ROOT>/ops/proposals/`（人审批后执行）
1. **固化**：经验→skill；经验/skill→hook 硬约束（须过 §8 准入四条件：可程序化判定+违反代价高+软层已失效有 harmful+matcher 覆盖率经复核；新 hook 先 warn 一个周期）
2. **下放**：经验→lessons 回炉重验证；harmful 经验退役 archive
3. **清理**：deprecated → ops/archive/（git mv，可溯源）

## 原则
- 提案须给证据（计数/日志/审计输出），不凭感觉拍板。
- 执行一律 `git mv` + commit + push，可回滚。
