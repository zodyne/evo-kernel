---
id: pi-skills-path-silent-failure
type: lesson
status: validated
scope: global
domain: harness-config
tags: [pi, skills, settings-json, silent-failure, harness-config, path-config]
triggers:
  - "配置 pi 的 skills 路径（~/.pi/agent/settings.json 的 skills 数组）"
  - "pi 里 skill 不生效 / pi 列不出预期 skill"
  - "改完 skill 配置后验证是否真的注入"
  - "配置项改了但行为没变、且没有任何报错（失败信号）"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:d2f8d5b2-2b60-4913-958b-59d2f937ed95
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# pi 的 skills 路径配置错误是静默失效：不报错、不注入，必须用 pi 实测验证而非看配置文件

## 主张
`~/.pi/agent/settings.json` 里的 `skills` 数组若指向**不存在的目录**，pi 不会报任何错，只是该路径下的 skill **静默不注入**——pi 仍能正常启动、正常对话，唯独 skill 体系整体失效。验证 skill 是否真的注入，必须用 `pi -p -nt --no-session "列出可用 skill"` 这类**实测命令**，看它是否回显出预期 skill 名称；不能只看 settings.json 里路径"写得对不对"。

## 为什么
pi 对 skills 路径做的是"尽力加载"：路径不存在不抛异常，只是该来源的 skill 不进可用集。本会话的断线就是 `skills` 指向了 `~/evo-kernel/skills`（实际应为 `~/Dev/evo-kernel/skills`）——少写了一层 `Dev/`，目录不存在，于是 evo 的全部 skill（evo-recall / evo-learn / evo-capture / evo-reflect）一个都没注入，而 pi 照常工作，问题被完全掩盖。只有实测 skill 列表才会暴露。

## 证据（本会话命令 ↔ 结果，切片硬证据）
- `$ ls ~/Dev/evo-kernel/skills/ 2>&1; ls -d ~/evo-kernel 2>&1` → `evo-capture evo-learn evo-recall evo-reflect` / `ls: /Users/zodyne/evo-kernel: No such file or directory` —— 证明正确路径 `~/Dev/evo-kernel/skills` 存在且有内容，而 settings.json 里写的 `~/evo-kernel/skills` 是不存在的断线路径。
- 修复后 `$ cd /tmp && pi -p -nt --no-session "只输出你当前可用的 skill 名称列表，每行一个，不要任何其他内容"` → `evo-recall evo-learn` —— skill 注入恢复，可被实测回显。
- 写/改文件清单含 `~/.pi/agent/settings.json`；末条 assistant 汇报"skills 从 ~/evo-kernel/skills(不存在)改到 ~/Dev/evo-kernel/skills……修前列不出，修后列出"。

## 边界 / 反例
- 本条只主张"路径不存在 → 静默不注入 + 必须实测验证"，不覆盖其他 skill 失效原因（SKILL.md frontmatter 损坏、--no-skills 旗标、skill 目录结构不规范等）——这些需各自排查。
- `pi -p -nt --no-session` 实测回显的 skill 集合取决于该次调用加载了哪些来源；若某 skill 因描述匹配/触发词未在该 prompt 下被点名，不代表它没加载。验证"注入通道通不通"用它足够；验证"某具体 skill 是否能被触发"需更针对性的 prompt。
- 本条是 pi（Earendil pi-coding-agent）的行为；Claude Code / 其他 harness 的 skill 机制不同，不套用。

## 失败信号（未来命中即该想起本条）
- 改了 ~/.pi/agent/settings.json 的 skills 路径后，skill 体系毫无变化且无报错。
- pi 能跑但 /skill、skill 触发词全无反应。
- 配置里出现 `~/xxx/skills` 这类手写路径，且从未用 `ls` 或 `pi -p` 实测确认过该目录真实存在。
