# K0a primer（常驻背景块）

> **权威副本**。安装到 `~/.claude/CLAUDE.md` 与 `~/AGENTS.md`（**双 harness**）。
> 2026-09-14 订正：**pi 已真实回归，作为主力 harness**（日常会话在 pi；本文件下方的
> 知识检索协议即 2026-09-12 改写的「pi 实况版」）。
> 「pi 已于 2026-08 退役」对应的是 2026-08-12 的一次**正式退役**（留档
> `ops/archive/pi-retired-2026-08-12/`），但该决定**已被推翻**——
> 那是已失效的旧状态，**不是临时回归**，后续不要把 pi 当过渡态处理。
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

**画幅**：个人单用户 · 单机 macOS · **双 harness（pi 主力 + Claude Code）** · 中文交流。

**活跃项目**（按近期会话量降序）
- `~/Dev/agent-evo`（设计/调研）+ `~/Dev/evo-kernel`（实现）—— Agent 经验系统自研。
  纯 frontmatter markdown + git 的经验内核，零依赖 Node CLI。
  **挂载现状（2026-09-14）**：**pi 侧桥接已恢复并实测生效** —— 扩展
  `~/.pi/agent/extensions/evo-kernel.ts`（存续件 `ops/integrations/pi-evo-kernel.ts`，
  同日从 `ops/archive/pi-retired-2026-08-12/` 取消归档）。三个钩子均有落盘证据：
  `before_agent_start`→`hook-recall`（recall.jsonl）、`tool_call`→`guard`（guard-hits.jsonl，
  两条规则均为 warn 观察期、非 block）、`session_shutdown`→`hook-session-end`
  （session-refs.jsonl，`harness:"pi"` 标注正确）。
  Claude hooks 已退役（设计迁 Hermes）；**Hermes `config.yaml` 的 hooks 段仍未写**。
- `~/Dev/suc221-pointcloud-2.0` —— 无人机避障雷达技术研究（原代号 UCM221，现名 SUC221）。
  雷达信号处理：CFAR、测角/DOA、点云、航迹；C 核心 + FreeRTOS + ARM 移植。
- `~/Dev/algommw` —— 算法中间件。

**常用栈**：Node/JS（内核 CLI）· Python（PySide6 可视化、信号处理）· C/C++（嵌入式，
遵本文件的 FreeRTOS 风格约定）· nvim/Lua 配置 · xelatex 中文报告 · pandoc 网页存档。

**工作方式**：命令与测试结果优先于记忆和推断；失败教训与成功经验同等重要；
重大结论须可证伪——给得出度量口径，而非"更好/更稳"这类断言。
<!-- PRIMER:END -->
