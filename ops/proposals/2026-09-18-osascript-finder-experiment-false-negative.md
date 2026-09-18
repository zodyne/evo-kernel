---
id: osascript-finder-experiment-false-negative
type: lesson
status: candidate
scope: global
domain: verification
tags: [osascript, finder, ds_store, controlled-experiment, false-negative, macos]
triggers:
  - "用 osascript/AppleScript 驱动 Finder 做实验，得出『不会发生 X』的阴性结论"
  - "受控 GUI 实验全部阴性，准备据此定论系统行为（失败信号）"
  - "要验证 Finder 何时写 .DS_Store、何时刷新视图"
  - "脚本复现不出用户实际遇到的 GUI 现象"
  - "自动化实验结论与现场观测数据打架"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a8c1-5e3e-710a-b61a-fd2478c30f87
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [checker-positive-control-or-negative-void, ds-store-cleanup-not-durable-17h-regrowth]
---

**主张**：用 osascript 驱动 Finder 做的受控实验，**阴性结果不可信**——它能证明「发生了」，不能证明「不会发生」。本会话一整套自动化场景（仅开窗 / 切图标视图+设图标大小+排序 / 开窗期间新建文件 / 关窗 / 重启 Finder / 窗口置前时内容变化）全部报「未生成 .DS_Store」，据此几乎定论「普通目录不会被写」；但 17 小时自然使用后普通目录再生 13 个，结论被现场数据推翻。

**为什么**：脚本化操作与真实用户交互不等价（事件来源、焦点、会话状态都可能不同），阴性只说明「这套自动化没触发」，不说明机制不存在。拿阴性自动化实验当定论，会把错误结论写进交付物。判定 GUI 副作用应以自然使用后的现场观测为主，自动化实验只作为阳性复现手段。

**边界/反例**：阳性结果仍然有效且高效（本会话桌面放 `testfile.txt` 3 秒后即生成 `.DS_Store`，这个阳性对照给出了「桌面这种常驻显示目录会被写」的硬结论）。本条的适用范围是「阴性结论 + 用它下普遍性判断」；如果阴性结论只是「在我这套自动化下没触发」，那它本身没错，错在升格。

**证据**（session 01a0a8c1，evo slice 「命令 ↔ 结果」）：
- 受控实验（/tmp 与家目录）：`场景 A: 只用 Finder 打开窗口，不做任何操作，等 5 秒` → 未生成；家目录实验 `A: 仅打开窗口 5 秒…生成? [否]`、`D: 先开窗，窗口开着时新建文件…生成? [否]`；`G: 改视图 → 关窗 → 等待 → 检查 → 重启 Finder → 再检查` → `关窗后 10s: 未生成 / 重启 Finder…未生成`；`H（对照实验：普通文件夹 + 窗口置前 + 内容变化）` → `放入文件…6s 后: 未生成 / 再 6s: 未生成`。
- 阳性对照：往 Finder 常驻显示的桌面放文件 → `3s 后: ★`（生成）。
- 现场数据：17 小时内普通目录（`~/Dev/SPC865` 等）自然再生 13 个 `.DS_Store`，推翻自动化实验给出的「普通目录不生成」。
