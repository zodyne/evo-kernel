---
id: streaming-protocol-snapshot-vs-delta
type: lesson
status: validated
scope: global
domain: integration
tags: [streaming, ndjson, memory, protocol, pi]
triggers:
  - 消费 LLM/CLI 的流式输出（NDJSON、SSE、--mode json），准备把 stdout 整段收集
  - 输出文件或内存占用与回复长度不成正比地暴涨（几十上百 MB）
  - 写包装器/适配器，只需要最终结果却把中间事件也留着
  - 长回复时进程内存飙升，短回复一切正常
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
related: [self-contained-task-needs-no-tools]
---
# 消费流式协议前先确认它发的是增量还是快照：发快照时整段累积是 O(n²)

## 主张
流式事件协议有两种发法：**增量**（每次只发新增的 token）与**快照**（每次发累积至今的完整消息）。
后者下，把 stdout 整段收集起来再解析是 **O(n²)** ——回复越长膨胀越猛。写包装器时必须
**先确认是哪一种**，若是快照就逐行丢弃中间事件、只留终态事件，不能 `out += chunk` 一把梭。

## 为什么
pi 的 `--mode json` 属于快照型：每个 token delta 发一份 `message_update`，内容是**完整消息**。
一次评审类长回复实测：

```
行数: 7255   事件: {message_update: 7249, message_start: 2, message_end: 1, …}
各类型占字节: message_update 132.7MB / 其余合计 < 0.1MB     总计 ~133MB
```

最终有用的信息只有 `message_end` / `agent_end` 里的一份终态消息（`output` 计 13649 **token**，
按中文折算约数十 KB——注意 token ≠ 字节，别把两者混算）——**绝大部分字节是同一段文本被
重复发了 7249 遍的前缀**。我的 MCP server 原先 `out += d` 会把这 133 MB 全部驻留内存。

判别方法很便宜：跑一次长任务，按事件类型统计字节占比（见下方命令）。占比压倒性集中在某个
"update/delta"类事件上，就是快照型。

## 证据（本会话命令 ↔ 结果）
- 按类型统计：`message_update` 7249 条、132.7 MB；`message_end` / `agent_end` 各 1 条、< 0.1 MB
- 同一次调用最终 `usage: input 10481 / output 13649` —— 有效产出约 14 KB，落盘 133 MB
- 修复：`server.js` 改为逐行过滤，`line.includes('"type":"message_update"')` 即丢弃，
  只累积终态事件；另加单行超长兜底（`tail.length > 1e7` 时截断）防内存失控
- 早前一次带工具的评审同样形态：62 MB 文件里 `message_update` 7849 条

## 边界 / 反例
- **不是所有流式协议都是快照型**。OpenAI SSE 的 `delta` 是增量，整段累积无此问题。
  别把本条当成"流式一律要过滤"——判别一次，再决定。
- 丢弃中间事件的代价是**失去进度可见性**。若需要向用户回显进度，应当解析并只保留
  "新增部分"（快照相减），而不是简单丢弃。
- **最致命的反例：终态事件不一定携带完整负载。** 本条的处方（丢中间、留终态）成立的前提是
  终态事件里有完整消息——pi 的 `agent_end` 确实有。但不少快照型协议的终态事件只是**完成信号**
  （无 payload 或仅含 usage/统计）。对这类协议照搬本条，会**静默产出空结果**：内存不涨了，
  内容也没了。这比下面那条字段序失效更隐蔽（后者至少表现为内存回归）。
  **落地前必须先确认终态事件里到底有没有你要的东西**，没有就得改成"保留最后一份快照"。
- 丢弃条件用字符串匹配 `"type":"message_update"` 依赖字段序稳定；协议升级改了字段顺序或
  事件名，过滤会静默失效（表现为内存问题回归，不是报错）。

## 失败信号（未来命中即该想起本条）
- 子进程输出文件以百 MB 计，而实际回复只有几千字。
- 短提问一切正常，长回复就卡死或 OOM。
- 包装器里出现 `out += chunk` 且下游只用得到最后一个事件。
