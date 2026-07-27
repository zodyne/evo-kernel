# K0a primer（常驻背景块）

> **权威副本**。安装到两处：`~/.claude/CLAUDE.md` 与 `~/AGENTS.md`（pi 侧）。
> doctor 第 17 项比对两处与本文件是否一致——改这里要重装，改那边要同步回来。
> 安装：`evo primer --install`
>
> **`review_after: 2026-09-25`（60d）**。设计 §8.2#1 点名的头号失败模式是
> "primer 变陈旧、常驻错误前提"——过期即复核，别让它带着旧事实进每一次对话。
> 内容依据（2026-07-27 实测）：库内 domain 分布 + session-refs 的项目路径统计，
> 不是凭印象写的。

<!-- PRIMER:BEGIN -->
## 用户画像与活跃领域

> 常驻背景，用于准确理解请求意图。经验库在 `~/Dev/evo-kernel`（`evo recall` 检索）。
> 本块 review_after 2026-09-25，过期请复核后再依赖。

**画幅**：个人单用户 · 单机 macOS · 双 harness（Claude Code + pi）· 中文交流。

**活跃项目**（按近期会话量降序）
- `~/Dev/agent-evo`（设计/调研）+ `~/Dev/evo-kernel`（实现）—— Agent 经验系统自研。
  纯 frontmatter markdown + git 的经验内核，零依赖 Node CLI，双 harness 经 hook 挂载。
- `~/Dev/ucm221-pointcloud-2-0` —— 无人机避障雷达技术研究（原代号 UCM221）。
  雷达信号处理：CFAR、测角/DOA、点云、航迹；C 核心 + FreeRTOS + ARM 移植。
- `~/Dev/algommw` —— 算法中间件。

**常用栈**：Node/JS（内核 CLI）· Python（PySide6 可视化、信号处理）· C/C++（嵌入式，
遵本文件的 FreeRTOS 风格约定）· nvim/Lua 配置 · xelatex 中文报告 · pandoc 网页存档。

**工作方式**：命令与测试结果优先于记忆和推断；失败教训与成功经验同等重要；
重大结论须可证伪——给得出度量口径，而非"更好/更稳"这类断言。
<!-- PRIMER:END -->
