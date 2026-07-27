# 条目 Schema（统一 frontmatter）

> 权威来源：`~/Dev/agent-evo/design/build-spec-v1.md` §3.1（13 字段 + 决策② `schema_version` = 14 字段）。
> 解析实现：`bin/evo` 用 `js-yaml`（纯 JS，M0.1 绿地版）；坏 frontmatter 容错为空对象（recall/rebuild 跳过）。
> `schema_version` 为**演化锚点**：解析缺省按 `1`（不报错不拒绝）；**不做迁移框架**——待某次字段变更出现「旧条目静默错读」实例再连同迁移脚本一并补（v4 §11.8）。

```yaml
---
id: lesson-2026-07-23-003        # ① 唯一，格式 <type>-<date>-<seq> 或语义 slug（缺则取文件名）
type: lesson                     # ② episode|fact|bullet|lesson|skill|principle|note
status: candidate                # ③ candidate → validated → solidified → deprecated（capture 写 inbox）
scope: global                    # ④ global | project:<name>（recall 过滤一级维度）
domain: api-design               # ⑤ 领域 slug（缺省 '-'）
tags: [rest, versioning]         # ⑥ 标签数组；recall 中 tag×0.8 计权
triggers:                        # ⑦ ★必填（curate 校验）：3-5 个"什么情境下该想起我"短语
  - "给已有接口加字段"             #   面向未来任务措辞 + 失败信号；recall 主匹配源
  - "ALTER TABLE / migration"
created: 2026-07-23              # ⑧ ISO 日期（YYYY-MM-DD）
evidence: {helpful: 0, harmful: 0}   # ⑨ distill 对账单点回填（reconcile.jsonl，I4）；adopt/reject 为人工兜底
verified_by: none                # ⑩ command|test|human|none（硬反馈等级，影响注入权重 VERIFIED_W）
source: session:xxx 或 人工       # ⑪ 来源
last_verified: 2026-07-23        # ⑫ YYYY-MM-DD；audit 复验超期用
superseded_by: null              # ⑬ 固化升级后指向新条目；非空即 recall 跳过（I2）
schema_version: 1                # ⑭【决策②】当前版本 1；写入新条目时带；解析缺省按 1
---
正文：一句话主张 + 为什么 + 反例/边界 + 证据链接
```

## 规则

- **lessons/ 不允许 `status: validated+`**（验证通过即 `git mv` 到 playbook/facts/skills）。
- **增量 delta 写入**；禁止整体重写（ACE 防 context collapse）。
- **计数是滞后近似信号**（批处理周期级），禁止实时使用。helpful/harmful 只由离线对账回填（reconcile.jsonl，I4 单点写）。
- **注入排除（I2 守恒）**：`inbox/`（未审）与 `lessons/`（candidate）永不进自动注入通道；`superseded_by` 非空条目排除出注入集。

## 状态机（命令 × 源 × 目标）

```
inbox(status:inbox) ──curate──▶ facts|episodes|playbook|principles(status:validated)
                                    │
                                    ├──solidify --to skill──▶ skills/ + archive(status:solidified, superseded)
                                    ├──solidify --to hook──▶ constraints/（原条目留原 zone，D7）
                                    ├──demote --to lessons──▶ lessons(status:candidate)
                                    └──demote --to archive──▶ archive(status:deprecated)
lessons(status:candidate) ──curate──▶ facts|episodes|playbook|principles(status:validated)
```

## 字段与注入权重（§5）

- relevance = max(triggers cover×1.0, tags cover×0.8, body(id+首行) cover×0.5)；<0.2 跳过。
- score = relevance × `VERIFIED_W[verified_by]` × `evW` × `typeW`
  - `VERIFIED_W` = test:1.0 / command:0.8 / human:0.6 / none:0.4（缺省 0.4）
  - `evW` = max(0.3, ln(1 + helpful − harmful))（下限 0.3）
  - `typeW` = principle:1.2 / 其他:1.0
- §5.0 权重恒等：治理权重三因子（verified_w × evW × typeW）跨后端恒等；relevance 属召回层、随后端变化。
