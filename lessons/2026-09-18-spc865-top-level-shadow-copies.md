---
id: spc865-top-level-shadow-copies
type: fact
status: candidate
scope: project:spc865
domain: code-recon
tags: [spc865, repo-layout, duplicate-copy, diff, recon]
triggers:
  - "在 /Users/zodyne/Dev/SPC865 里改顶层 .m 脚本（awr294x_spc865_v1.m / batch_865_1.m / view_awr294x_spc865_time_domain.m）"
  - "同一脚本在仓库顶层和 MatlabSpc865/ 子目录各有一份拷贝，拿不准该改哪一份"
  - "改完顶层脚本但运行结果没变化、怀疑改的是没被引用的那份（失败信号）"
  - "找 SPC865 采集数据：顶层 data/ 与 MatlabSpc865/data/ 各有一套日期批次目录"
  - "只读侦察 SPC865 仓库，要判断哪些顶层文件只是子目录里的影子副本"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7de-99c5-7719-ba82-31ede22f47b0
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [dual-repo-copy-drift-fails-golden-first-diff]
---

# SPC865 是「顶层 + MatlabSpc865/」双份仓库：改动前先 diff 确认改哪一份

**主张**：`/Users/zodyne/Dev/SPC865` 的脚本与数据各有一套并存——顶层 `awr294x_spc865_v1.m` 与 `MatlabSpc865/matlab/awr294x_spc865_v1.m` **逐字节相同**（`diff` 无差异）；数据也分居两树：顶层 `data/`（`吸波材料` / `20260605` / `20260606`，其中 `data/20260605/` 放 `SPC865_NG_2021-12-07-*.bin`）与 `MatlabSpc865/data/`（`SPS865对暗室采数_20260610` 等日期目录）。所以在这个仓库里**改脚本或找数据前先确认目标副本**：改到不被引用的那份，运行结果不会变。

**为什么**：两份内容相同时，从内容本身判不出哪份是权威——只有引用关系（MATLAB path / 调用方 / 文档指向哪一份）能判。侦察阶段最省事的判据是 `diff`：退出 0 说明是纯副本，退出非 0 说明副本已漂移（漂移比重复本身更危险，参见 `dual-repo-copy-drift-fails-golden-first-diff`）。

**怎么做**
1. 见到顶层同名文件，先 `diff <顶层文件> MatlabSpc865/matlab/<同名文件>`：退出 0 → 影子副本；非 0 → 已漂移，先定权威再动手。
2. 找数据按日期入两个入口：`data/2026xxxx/` 与 `MatlabSpc865/data/<采集批次名>/`；只搜一处不能断言数据不存在。
3. 确认权威副本后再改；只改一份时，明确是否同步另一份或删掉影子副本。

**反例 / 边界**
- 本次只证明两份 `awr294x_spc865_v1.m` **当前**相同，**没有**证明哪一份被真正引用——不能据此假设顶层就是权威。
- 顶层还有 `batch_865_1.m`、`view_awr294x_spc865_time_domain.m`，本次**没有**对它们跑 diff，是否存在子目录副本未验证。
- 该文件是 CRLF 行尾：`git diff` 会先打出 `warning: in the working copy ... CRLF will be replaced by LF`，别把它当成内容差异。

**证据（slice 命令 ↔ 结果）**：`diff awr294x_spc865_v1.m MatlabSpc865/matlab/awr294x_spc865_v1.m`，输出段 `=== diff top awr294x vs nested ===` 之后打出 `(identical)`（无差异才走 `&&` 分支）；`ls -la docs/ tests/ output/ data/` → `data/: 吸波材料 / 20260605 / 20260606`；`ls data/20260605/` → `SPC865_NG_2021-12-07-04-10-29_0.bin` 等；`find MatlabSpc865/data -maxdepth 3 -type d` → `MatlabSpc865/data/SPS865对暗室采数_20260610`。会话「写/改文件」段为空，以上均来自只读命令。
