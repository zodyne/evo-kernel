---
id: git-add-n-untracked-into-diff-patch
type: lesson
status: candidate
scope: global
domain: git
tags: [git, diff, patch, untracked, intent-to-add, custom-ui]
triggers:
  - "用 git diff 导出一份自定义改动 patch 交付/存档"
  - "生成的 patch 里少了新增文件，只有被修改的旧文件（失败信号）"
  - "维护跨升级复用的 *.patch（如 hermes-custom-ui.patch）"
  - "统计 patch 覆盖了哪些文件、发现新写的测试文件不在其中"
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:1363c097-a1c9-4248-a903-814a33facb13
last_verified: 2026-08-13
superseded_by: null
schema_version: 1
related: [git-status-has-no-cached-flag, dirty-worktree-patch-freeze-before-revert]
---
# `git diff` 静默漏掉未跟踪的新文件：导出 patch 前先 `git add -N`

## 主张
`git diff` 只看已跟踪文件，**新建的未跟踪文件不会进入 patch，也不会有任何警告**——
用它导出的"全部自定义改动"patch 会静默缺料，恢复时只剩改过的旧文件。
**修法：导出前对新文件 `git add -N <paths>`（intent-to-add，只登记意图不真的暂存内容），
再 `git diff` 生成 patch**，新文件即以完整 `diff --git a/... b/...` 段落出现。

## 为什么
"patch 生成成功且非空"这件事本身没有任何信号告诉你少了文件；只有去数 `diff --git` 条目
才会发现新增的测试/配置文件不在里面。对"跨版本升级后重放自定义改动"这类用途，缺一个新文件
就等于恢复后功能缺失或测试失踪，而 patch 应用时不会报错。

## 证据（本会话命令对照）
- 未处理前统计覆盖面：`grep "^diff --git" ~/Dev/hermes-custom-ui/hermes-custom-ui.patch | head -30`
  → 只有 `a/cli.py`、`a/ui-tui/src/components/appChrome.tsx` 等**已跟踪**文件。
- 执行 `cd ~/.hermes/hermes-agent && git add -N ui-tui/src/__tests__/setup-env.ts ui-tui/src/__tests__/thinkingScroll.euly.test.ts ui-tui/src/__tests__/typewr...`
  后重新导出并统计 → `=== patch 覆盖 === diff --git a/cli.py ... diff --git a/ui-tui/src/__tests__/setup-env.ts b/ui-tui/src/__tests__/setup-env.ts`
  —— 新建测试文件进入 patch。
- 随后两轮同一流程的 patch 规模：`930` 行 / `13` 个文件 → `966` 行 / `13` 个文件（新文件已稳定在覆盖集内）。
- 相关上下文：`git status --short` 当时显示 ` M cli.py`、` M ui-tui/src/app/turnController.ts` 等修改项，
  未跟踪的新测试文件不在 diff 里正是本条现象。

## 边界 / 反例
- `git add -N` 之后工作区状态被改动（索引里多了 intent-to-add 记录）；若不想留痕，导出完可 `git reset <paths>` 撤掉登记。
- 二进制/大文件被 `-N` 拉进 diff 会让 patch 体积暴涨，按需挑文件而不是 `git add -N .`。
- 只解决"新文件进 patch"；被 `.gitignore` 忽略的文件即使 `-N` 也需要 `-f`，本次未验证该分支。
- 想核对暂存结果不要用 `git status --cached`（不存在该选项，见 related）。

## 失败信号（未来命中即该想起本条）
- patch 行数看着不少，但 `grep -c "^diff --git"` 的文件数比你改过的文件少。
- 恢复自定义改动后，"我明明写过的那个文件"不见了。
