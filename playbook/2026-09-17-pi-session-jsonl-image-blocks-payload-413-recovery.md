---
id: pi-session-jsonl-image-blocks-payload-413-recovery
type: lesson
status: validated
scope: global
domain: agent-harness
tags: [pi, transcript, jsonl, images, base64, payload-413, recovery]
triggers:
  - "pi 会话反复报 413 Payload Too Large 且无法继续/自恢复"
  - "pi 会话 jsonl 文件体积异常膨胀到几十 MB，想找原因"
  - "要抢救一个被图片撑爆的 pi 会话，或想给它瘦身恢复 fork 能力"
  - "统计 pi 会话里图片块占多少体积、排查请求 payload 超限"
  - "想从 pi 会话 jsonl 里剥离图片块，恢复可继续对话"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0adea-c461-72a1-ba4c-1e07e08c6101
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [claude-session-jsonl-drops-pasted-images]
---
# pi 会话 jsonl 里的 base64 图片块会累积撑爆 payload，报 413 且无法自恢复——剥离图片块即可抢救

## 主张
pi 会话 jsonl 里的 `{"type":"image"}` 块携带**完整 base64 图片数据**，随会话累积会把文件撑到几十 MB
（本会话：54 张图 = 48.3 MB base64，占文件 96.4%），导致后续请求 payload 超限、反复报
`413 Payload Too Large`，且会话无法自恢复。
**恢复办法**：备份原文件并 sha256 逐字节校验一致 → 用脚本把 image 块就地替换成自解释文本占位符 →
`pi --fork <id> --thinking off -p "探针"` 验证可恢复。

## 为什么
"会话坏了就重开一个"的直觉会让人直接放弃一个已有大量中间成果的会话；而根因其实是可逆的——图片块是
会话里最肥的可剥离成分（96% 体积），剥掉它就能恢复 fork，其余文本/工具调用记录原样保留。诊断时先
摸清"体积大头在哪"再动手，比盲猜上下文溢出、模型配置错要快得多。

## 证据（本会话命令对照）
- 首次统计字段摸错：`images in session: 54, total base64 bytes: 0`（字段名不对，得到假 0）。
- 正确字段：`image blocks: 54  base64 total: 48,266,376 B = 48.3 MB`，最大的 8 张各 2.26~4.27 MB。
- 占比：`session file: 50.85 MB  session content bytes: 50.09 MB  image(base64) 48.27 MB = 96.4%`。
- 413 时间点：`413 errors: [(1459,'05:16:38'), (1462,'05:16:45'), (1465,'05:18:07'), (1468,'05:19:11'), (1470,'05:48:06'), ...]`。
- 备份校验：`=== 备份校验 === 297c79b4…`（50,852,501 B，sha256 与原文件逐字节一致）。
- round-trip：`round-trip 校验（前 400 行）: 一致 400 / 不一致 0`。
- 恢复验证：`pi --fork 01a0ad3c-a28f --thinking off -p "恢复探针：只回复两个字「就绪」…" → 就绪`。

## 边界 / 反例
- 覆盖本机这一版 pi 的落盘行为；若未来 pi 改为图片不落 base64（像 Claude Code 只留 `[Image #N]` 占位，
  见 related 条目），则"撑爆 payload"失效，但"剥离 image 块"脚本仍无害。
- 剥离后图片不可见，需要看图须回到 `.orig-bak-before-image-strip` 备份或原始文件——剥离是**可逆**的。
- 图片块是"最肥可剥离成分"，但若某会话文本/工具调用本身就已超限，剥离图片不足以恢复，需另找大头。

## 失败信号（未来命中即该想起本条）
- pi 会话 jsonl 单文件几十 MB，且 python 统计出 base64 段占绝大头。
- 会话末尾反复 413 / payload too large / bad_response_status_code，换模型或重试都无效。
- 想给 pi 会话瘦身/抢救时，第一反应是"重开"，而不是"剥离最肥的可逆成分"。
