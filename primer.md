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
  **Claude Code 是有意不接入 evo**（使用与接入是两件事）—— 它的 hooks 已退役且无替代桥接，
  故 Claude 侧会话既不回流经验也得不到 recall 注入，此为设计取舍。**不要再当缺口处理**：
  2026-09-14 曾把登记数下降（7月 121 → 8月 67 → 9月 1）误盘成「半个 harness 失效」。
  **Hermes 侧已于 2026-09-18 退役**（用户口径「摘掉 evo↔hermes hooks」）：三件套从
  `~/.hermes/config.yaml` 摘除，hermes 会话同样不再回流、不再注入、不再走 guard。
  即现**只有 pi 一个 harness 接入 evo**。退役原因：实测 hook 在蒸馏路径上本就被
  `EVO_DRIVER=1` + prompt 哨兵短路（本轮 47 个蒸馏会话在 recall.jsonl 里 0 行），
  对速度无收益；真正的成本在模型思考块（12–43KB 思考/次调用，43KB÷126 字符 = 340 倍）。
  恢复办法写在 config.yaml 被注释掉的那段旁边（三步，含 copies 回 `~/.hermes/agent-hooks/`）。
  存续件仍在 `ops/integrations/hermes-evo-hooks/`（doctor 第 16 项继续比对副本）。
- `~/Dev/suc221-pointcloud-2.0` —— 无人机避障雷达技术研究（原代号 UCM221，现名 SUC221）。
  雷达信号处理：CFAR、测角/DOA、点云、航迹；C 核心 + FreeRTOS + ARM 移植。
- `~/Dev/algommw` —— 算法中间件。

**常用栈**：Node/JS（内核 CLI）· Python（PySide6 可视化、信号处理）· C/C++（嵌入式，
遵本文件的 FreeRTOS 风格约定）· nvim/Lua 配置 · xelatex 中文报告 · pandoc 网页存档。

**检索有两条通道，别只用第一条**（2026-09-14 盲标实测后补）
- `evo recall "<关键词>"` —— 词法自动注入。**实测天花板：降阈值到 0.10 也只有 63% 召回**
  （1292 对全标注：漏 31 : 误 9 = 3.44，且阈值已在最优点附近）⇒ **它够不着的那 37%，必须靠下一条**。
- `evo candidates` → 自己读完挑出相关的 → `evo get --ids a,b` —— **语义粗筛**。
  `candidates` 输出**全量 86 条摘要（约 15KB）、零过滤即最高召回**；`get` 拉全文。
  **当用词法与库内写法不同时（换词/同义/近义，如「nvim 报错」vs 库里的「vim.fs 展开 ~」）主动用它**——
  词法匹配不到不代表库里没有。语义判断由你做，不需要额外模型调用。
  设计依据：`playbook/2026-07-23-rerank-channel-design.md`（形态 B：主 agent 即精筛器）。
- **接手 evo 的后续工作，先读 `~/Dev/evo-kernel/README.md` 的「继续后续工作」节** ——
  那里有现成的判据表（看到什么→做什么）、四个仪表的用途、以及**一批已排除的方向**
  （调阈值 / 换评分公式 / 零模型显著性 / 治长 prompt 过度注入 / 靠加闸门提精度），
  每条都附了排除依据的数字。**没有它，会重新踩一遍已经花了几小时才排除的路。**

**工作方式**：命令与测试结果优先于记忆和推断；失败教训与成功经验同等重要；
重大结论须可证伪——给得出度量口径，而非"更好/更稳"这类断言。
<!-- PRIMER:END -->
