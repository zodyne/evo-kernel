---
id: deepseek-length-zero-body-disable-thinking-recover
type: lesson
status: validated
scope: global
domain: llm-tooling
tags: [deepseek, reasoning, recovery, thinking, finish-length]
triggers:
  - "deepseek 命中 finish=length 且正文为空，想恢复对话"
  - "思考吃光输出预算后怎么让回复继续"
  - "要不要关 thinking 绕过思考吃光预算"
  - "重试+调大 max_tokens 后正文还是空"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a3ff-16b7-73aa-b447-07d4b5ec2022
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [deepseek-reasoning-max-eats-output-budget-length, deepseek-reasoning-effort-levels-mapping]
---

# 命中 finish=length + 0 正文时，关 thinking 是确定性恢复手段；单纯重试+提 cap 不可靠

**主张**：deepseek-v4 系 reasoning 模型一旦命中「finish=length + 正文 0」，把 thinking 关掉（thinking disabled）再 continue 即可确定性恢复正文产出；而保持思考开启、单纯重试并调大 max_tokens 往往还是失败——CoT 会继续膨胀把新预算再吃掉。

**为什么**：根因在思考与正文共享预算（见 deepseek-reasoning-max-eats-output-budget-length）。关 thinking 直接消掉 CoT 这个无底洞，正文立刻拿到全部预算；只提 cap 不关思考，思考会把新增预算继续吞掉，正文仍是象征性的几十字。

**边界**：关思考牺牲推理质量，只当恢复兜底用，恢复后可再按需开回。实测关思考是唯一验证稳定的恢复路径，不是唯一可能路径，但「重试+提 cap」这一条已被实测否定。

**证据**：slice 命令↔结果配对——实验 A（cap=800）：思考关 + continue → 正文字符 1494、reasoning=0 ✓（现场 1、2 均成功）；真实恢复测试（重试 cap=131072）配对：现场 1 [重试·思考开] → reasoning=14587、正文仅 71、输出到 150（失败），对照思考关则正文恢复。
