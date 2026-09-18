---
id: milestone-status-claims-conflict-in-repo
type: lesson
status: candidate
scope: global
domain: documentation
tags: [doc-drift, status-claims, git-show-head, bundle, remote-branch, progress-report]
triggers:
  - "被问『项目现在到哪一步了 / 进展如何』，手里只有仓库文档"
  - "文档里出现里程碑/移植状态断言：未做、缺硬件、未上板、未 push"
  - "同一仓库不同文件对同一里程碑给出相反结论（失败信号）"
  - "要判断某个分支/交付包到底有没有进远端（从未 push 类断言）"
  - "续接一个多轮迭代的仓库，导航文档与提交历史对不上"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2d9-e94b-7323-8254-c19b2aefb87d
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [doc-selfreported-counts-drift, git-pickaxe-verify-doc-date-claim, nav-doc-pinned-head-goes-stale]
---

# 里程碑状态断言在同一仓库内互相矛盾：以 git 实体为裁决源

## 主张
回答"项目进展到哪一步"时，不要把任何一份文档的状态断言当真：同一仓库里"未做 / 缺硬件 / 未上板 / 从未 push"与"已于 X 真板收口 / 已并入 origin/dev"可以同时存在（不同文件、甚至同一文件的不同段落）。裁决源是**仓库实体**：`git show HEAD:<file>`（已提交口径，区别于工作区未提交改动）、`git bundle list-heads` + 在对应仓库核对该 sha（"从未 push / 未并入"类断言）、以及仓库里后出的结果文件（用新结论取代旧结论的那份）。而且要**逐条**判：并存的旧口径里有一部分仍然为真。

## 为什么
状态口径是手写元数据：写它的动作发生在里程碑收口之前或之后都可能，没人负责回头统一；而里程碑一旦另立结论文件（如 `port/board/RESULTS.md`），其它文件里的旧结论不会自动失效。于是"读一份文档就下进展结论"必然错——本次会话开场正是被互相矛盾的口径绊住，最终产出是一串 `docs(status):` 修正提交。

## 证据（session 01a0b2d9，suc221-pointcloud-2.0）
- 两套口径并存：`git show HEAD:port/PORTING.md | grep -n '已于 2026-08-31'` → `194:**✅ M1 已于 2026-08-31 在真板收口**(Zynq Cortex-A9 实板,…)`；同一条命令里"全仓 M1 未做/缺硬件 类声明"另有命中。工作区 README 的阶段行当时仍写移植未完成。
- 并非全部过期（必须逐条判）：`rg -n '未上板|准备进入嵌入式|未实测|未落锤'` → `port/PORTING.md:246:| **目标板耗时未落锤** | 🔴 高 | ×40 系数标定自 MAC 密集内核，对本内核未必成立（§2.4）…` —— 目标板耗时未落锤仍是真待办，不能一刀切"文档都过期"。
- "从未 push"类断言用远端核实：`git bundle list-heads port/m6_integration.bundle` → `e32b748… refs/heads/feat/pcf-m6`，随后"该分支是否已在 origin"在 `libsuc221` 里核对同一 sha（命中该提交日志）→ 分支其实已在远端。
- 修正与残留：commit `0e736ba docs(status): 修正移植口径 — M1 已真板收口、M6 已并入 origin/dev`；`port/board/RESULTS.md` 自述取代 `FREEZE.md` §3 中"「M1 未做,缺硬件」的旧结论"。一轮没搜干净：`rg … --glob '!archive/**'` 又命中 `data/baseline/pcf-v1-20260830/README.md:38`（「从未 push」），补提交 `aa48a19 docs(status): 补两处漏网的旧口径`。

## 边界 / 反例
- 本条只管**里程碑/状态类**断言（做没做、上没上板、push 没 push）。计数类数字见 `doc-selfreported-counts-drift`；HEAD sha 指针见 `nav-doc-pinned-head-goes-stale`；日期/版本断言见 `git-pickaxe-verify-doc-date-claim`。
- 修正时只改"活着的权威文档"，历史归档与历史设计文档保持原样（本次自查用 `--glob '!archive/**'` 把归档排除在外）——统一口径 ≠ 篡改历史。
- `git show HEAD:<file>` 读的是**已提交**口径；工作区里可能已有更新的改动，要区分"文档口径过期"与"改了还没提交"，两者处置不同。
- 远端存在 ≠ 已并入主干：核验"已并入 dev"要另看分支拓扑 / merge-base，不能只凭"远端有这条分支"。
- 文档口径与代码/产物现状冲突时，以可复现的实体证据（提交、构建产物、设备实测记录）为准，不以"哪份文档更新"为准。

## 失败信号（未来命中即该想起本条）
- 两份文档对同一里程碑给出相反结论（一份"未做/缺硬件"，另一份"已收口"）。
- 文档写着"未上板 / 未 push / 缺硬件"，但 `git show HEAD:<file>`、`git bundle list-heads` 或远端分支显示对应工作已完成。
- 你刚据文档写下"这一步还没做"，随后被同仓库的提交历史推翻。
