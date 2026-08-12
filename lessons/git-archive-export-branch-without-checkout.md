---
id: git-archive-export-branch-without-checkout
type: lesson
status: candidate
scope: global
domain: git
tags: [git, archive, 打包, 跨分支]
triggers:
  - "当前分支在工作/有未提交改动不能切换，却要用另一分支的内容做打包交付"
  - "需要从 main 或其他分支导出一份干净快照，但不能 checkout（会动工作区）"
  - "跨分支取文件：先 git ls-tree -r <branch> 探查、git show <branch>:<path> 抽查，再整体导出"
  - "不想为了打个包去 clone 第二份工作区或 stash 当前改动"
  - "git archive <branch> | tar -x -C <目标目录> 导出后需要确认文件齐全"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fab61-fe72-7a9a-8f70-2988be4a9928
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [package-verify-as-recipient, package-html-deadlinks-missing-assets]
---
# 不切换分支导出另一分支内容：`git archive <branch> | tar -x -C <目录>`

**主张**：当前分支在工作不能 checkout 时，跨分支打包的标准路径是——先用 `git ls-tree -r <branch> --name-only | grep <关键词>` 和 `git show <branch>:<path>` 无 checkout 探查目标分支内容与抽样确认文件存在，再 `git archive <branch> | tar -x -C <目标目录>/` 无损导出整树到仓库外目录。全程零触碰当前工作区与暂存区。

**为什么**：`git checkout`/`git switch` 会改写工作区，有未提交改动时直接被拒或要求 stash，风险大；`git archive` 直接从对象库读树，导出的是该分支**已跟踪**内容的干净快照（不含 .git、不含未跟踪文件），天然适合交付打包。

**边界/注意**：
- `git archive` 只导出 git 跟踪的文件；未被跟踪的静态资产/数据不会进包（参见 package-html-deadlinks-missing-assets 的同类坑）。
- 导出后应以收件人视角实跑验证（如 python import 冒烟），文件齐≠能跑（参见 package-verify-as-recipient）。

**证据**：会话中当前分支 `feat/faf-embedded-port` 在工作，用户要求打包 `main` 分支的 ADC/暗室/测角代码且禁止切分支。用 `git ls-tree -r main` + 抽样循环确认文件存在后，`git archive main | tar -x -C ~/Dev/ucm221-research-bundle/` 导出 11 MB 成功，末条总结确认「未碰当前工作分支」，导出后 python import 冒烟立刻抓到 `doa_calibration.load_coarray_cal_table` 的加载失败。
