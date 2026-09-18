---
id: readonly-verify-tmp-variant-git-status-proof
type: lesson
status: candidate
scope: global
domain: verification
tags: [read-only, git-status, porcelain, tmp-workdir, probe, adversarial-verification]
triggers:
  - "被要求『仓库只读/禁止修改任何文件』，但验证需要改配置或翻某个开关"
  - "只读核验/对抗式验证收尾要让『我没动过被审仓库』这句话可被机械复查，而不是口头声明"
  - "要把变体配置和探针脚本落在 /tmp，避免污染被审仓库"
  - "交付报告想写『工作区保持与基线一致』，手上却没有 git 状态对照（失败信号）"
  - "收尾 git status 不是空输出，才发现调试期间往仓库里落过探针或改过配置"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a705-1193-7353-8a3d-43033d78c8cd
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [tmp-script-import-needs-explicit-pythonpath, asan-ubsan-out-of-tree-ctest-audit, built-static-lib-standalone-probe]
---

# 只读核验：变体输入全部落 /tmp，收尾用 `git status --porcelain` 空输出自证仓库未动

**主张**：在「被审仓库只读、禁止修改任何文件」的核验任务里，凡是需要改动的输入（配置 profile、探针脚本）先整体复制到 `/tmp/<probe>/`，在副本上做单变量变体；收尾跑一条 `git status --porcelain`，用**空输出**（相对任务开始时已知干净的基线）作为「仓库确实未被改动」的可引用证据——而不是在报告里只写一句「我保持了只读」。

**为什么**：只读是任务红线，但它最容易被交付成一条无法核验的口头声明——读者分不清「真的没动」和「动过之后忘了还原」。`--porcelain` 给出机械证据：无论是新增探针脚本（`??`）还是改了仓库里的 profile（` M`），都会出现在输出里；把实验输入放 /tmp 副本，则让「改参数做 A/B」与「不动仓库」同时成立。

**做法（本会话实测）**：
1. 复制被测配置到 /tmp、只在副本上翻一个变量：
   `mkdir -p /tmp/probe/profile_off /tmp/probe/profile_on && cp -r <repo>/profiles/sr61_tdm/. /tmp/probe/profile_off/ && cp -r …profile_on/`；随后仅把 **副本** 里的 `sub_bin_interp` 置 true/false（仓库原文件第 141 行未动）。
2. 探针脚本同样写在 /tmp（`/tmp/probe/probe.py`、`probe2.py`），由探针加载 /tmp 副本配置去驱动被测 core。
3. 收尾：`git status --porcelain | head && echo "(clean above = 未改动仓库)"` → porcelain 无输出；把「空输出 = 未改动」的判据直接写进命令自带的 echo，省得事后回看时误读。

**边界 / 反例**：
- `--porcelain` 只反映相对 HEAD 的 tracked/untracked 变化：**被 .gitignore 忽略**的写入不会出现（写进被忽略的 `build/` 等目录，porcelain 依旧干净）。要覆盖这类副作用，需另查目标目录 mtime/内容，或确认改动根本没落在仓库树内。
- 「空输出」只有配合**已知干净的基线**才有意义（本会话任务书即声明基线工作区干净）。若开工时工作区本来就有未提交改动，须先记下基线，收尾比对应相同集合。
- 本条只保证「仓库文件未变」，不等于「被测系统未被影响」：跑 core 可能在仓库内留下被忽略的缓存/构建产物，porcelain 看不到。

**证据（切片命令 ↔ 结果）**：
- `mkdir -p /tmp/probe/profile_off /tmp/probe/profile_on && cp -r /Users/zodyne/Dev/algommw/profiles/sr61_tdm/. /tmp/probe/profile_off/ && cp -r /Users/z…` ↳ `/tmp/probe/profile_on/profile.toml:141:sub_bin_interp = true` / `/tmp/probe/profile_off/profile.toml:141:sub_bin_interp = false` —— 两个变体都只存在于 /tmp 副本。
- `cd /tmp/probe && python3 probe.py 2>&1 | tail -20` ↳ `[off] bSubBinInterp=0 step=0.8565 n_dop=32 pts=811 frac(xDoppler<0)=0.0000 max|xDoppler-signed_velocity|=0.000000 frac_d…`；`python3 probe2.py` ↳ `n off/on: 811 811 mean xRange same order? bin pairs equal: True [off] dbin uniq=[0] …` —— 核验全程由 /tmp 副本+探针完成。
- 切片「写/改文件」仅两条：`/tmp/probe/probe.py`、`/tmp/probe/probe2.py`（无仓库内文件）。
- 收尾 `git status --porcelain | head && echo "(clean above = 未改动仓库)" && sed -n '34,40p' core/src/math/peak.c` ↳ `(clean above = 未改动仓库)     if( dOff > 0.5 ) …` —— porcelain 空输出，仓库与基线一致。

**失败信号（未来命中即该想起本条）**：
- 只读核验报告写了「未修改任何仓库文件」，却没有任何 git 状态/工作区对照可复查。
- 收尾 `git status` 非空，才想起调试期间往仓库里落过探针或直接改过仓库配置。
- 为了翻一个开关，直接编辑被审仓库里的配置文件（事后忘了还原）。
