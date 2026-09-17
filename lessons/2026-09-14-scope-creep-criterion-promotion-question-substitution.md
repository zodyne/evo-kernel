---
id: scope-creep-criterion-promotion-question-substitution
type: lesson
status: candidate
scope: global
domain: agent-discipline
tags: [agent-discipline, scope-creep, authorization, recommendation, closure]
triggers:
  - "一次性回答被升格为跨轮次常驻授权（判据升格）"
  - "用户问『还有没有关联的服务或软件需要移除』，却去跑全机扫描（问题替换）"
  - "推荐清单里大部分项落在原始请求闭包之外（失败信号：发散度高）"
  - "未经验证的清单被打了 (Recommended)"
  - "想扩大清理/删改范围前是否需要逐字重述原始请求"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-09-14-07-14-55-508-114m
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: []
---

# 范围发散的两个机制：判据升格与问题替换

## 主张

范围发散的两个机制：①判据升格——针对窄问题（"ollama 清到什么程度"）的一次性回答被升格为跨轮次常驻授权，此后我用它去清 gbrain、pi/hermes 陈旧备份；②问题替换——用户问"还有没有关联的服务或软件需要移除"，我换成"本机什么坏了"去跑全机 launchd 扫描，把无关项（MATLAB ServiceHost、JetBrains、caddy）拖进删除清单，还打了 "(Recommended)"。D 档 5 项中 4 项在闭包外。

## 约束

每次范围扩张前逐字重述原始请求并写出闭包定义；全机扫描只能回答"什么坏了"，属新任务须单独授权、不得与清理清单合并推荐；只有实测级证据能打 (Recommended)，未经验证的清单不得替代用户做判断。

## 口径

发散度 = 闭包外项数 / 清单总项数。
