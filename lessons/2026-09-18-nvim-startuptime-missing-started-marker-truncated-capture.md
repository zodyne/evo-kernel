---
id: nvim-startuptime-missing-started-marker-truncated-capture
type: lesson
status: candidate
scope: global
domain: nvim
tags: [nvim, startuptime, artifact-integrity, verification, truncation]
triggers:
  - "拿 nvim --startuptime 的日志文件分析启动耗时/找慢插件"
  - "startuptime 文件里只有 NVIM STARTING 行，却找不到 NVIM STARTED 终止标记（失败信号）"
  - "要判断一份启动日志/采样日志是否被中途截断、进程有没有跑完"
  - "准备按日志行数或尾部条目下性能结论，先要确认产物完整"
  - "日志最后一行的格式明显停在中间（插件名/阶段没写完）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ad-67d6-725c-a75a-f9894a03787a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [grep-alternation-count-cannot-prove-single-pattern-present]
---

# nvim --startuptime 产物缺 `--- NVIM STARTED ---` 终止标记 = 捕获不完整，不能据此分析启动耗时

**主张**：分析 `nvim --startuptime <file>` 的产物前，先确认文件里有终止标记 `--- NVIM STARTED ---`；只有 `--- NVIM STARTING ---`（以及停在中间的最后一条插件/阶段行）说明这次捕获**没有跑完就被中断**，文件是截断产物，基于它算启动耗时或找慢插件都不成立。

**为什么**：startuptime 文件是**边启动边写**的流式日志。nvim 没走到启动完成那一刻（被 kill、终端关闭、`--startuptime` 之后没正常退出）时，文件里就永远不会有终止标记，但前面的行看起来完全正常——行数与内容都"像"导出成功的日志，很容易被当成可用的性能数据直接引用。

**证据（本会话命令对照）**：
- `rg -c 'NVIM STARTED|--- NVIM' /tmp/nvim_st.txt` → `1`（先用这个"看起来有命中"的计数做了存在性判断）；
- 换成逐行定位：`rg -n 'NVIM STARTED|--- NVIM' /tmp/nvim_st.txt` → 只有 `7:000.000  000.000: --- NVIM STARTING ---`；`wc -l` → `239`。即全文**没有** `NVIM STARTED` 行，且末行停在中间；
- 该终止标记确由 nvim 自身产出：`rg -a -l 'NVIM STARTED' /opt/homebrew/Cellar/neovim/0.12.4/` → 命中 `/opt/homebrew/Cellar/neovim/0.12.4/bin/nvim`（该字符串是二进制内建常量，不是环境里别人写的）。
- 诚实标注：切片里**没有**完整的对照样本（跑完的 startuptime 文件）可做逐行比对，因此"缺标记即截断"这一步属于由"标记由 nvim 产出 + 该文件缺失标记"推出的判断，非本次实测的 A/B 对照。

**边界 / 反例**：
- 缺失标记也可能来自"用了别的工具生成同名文件"或"日志被后处理工具裁过"，判据是"标记来源可证 + 文件确实由 nvim 写出"，两点都要满足；
- 只关心 `--- NVIM STARTING ---` 之前那段（如 early-init 顺序）时，截断文件仍可用于定性观察，但不要用它报任何总耗时数字。

**失败信号（未来命中即该想起本条）**：拿到 startuptime 文件后 `rg -n 'NVIM STARTED'` 空 → 先别分析，重跑一次并确保 nvim 正常退出。
