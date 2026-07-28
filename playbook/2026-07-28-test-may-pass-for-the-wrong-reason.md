---
id: test-may-pass-for-the-wrong-reason
type: lesson
status: validated
scope: global
domain: testing
tags: [smoke, regression, verification, vacuous-test, evo-kernel]
triggers:
  - 为刚修好的缺陷补一条回归用例，准备提交
  - 断言写的是"没发生坏事"（无关文件未被卷入 / 无错误日志 / 计数没变），且没经历过"先红后绿"
  - 为某个具体分支补的用例一次就绿，而你说不出它红的时候长什么样
  - 怀疑某个分支到底有没有被测到，但只看到一片绿
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: test
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
related: [git-add-untracked-source-path-aborts-staging, doc-selfreported-counts-drift]
---
# 用例可能"因为错误的原因通过"：没见它为修复而转红，就不算守护

## 主张
一条**没有见过红**的回归用例，不能算证明了任何事。它可能因为目标分支根本没被走到而平凡成立——
此时它不仅没有守护作用，还会**制造已被覆盖的假象**，把更大的缺陷挡在视线外。
唯一可靠的检验：**把修复回退，看该断言是否真的转红**；不转红就是空转用例，必须重写或删除。

## 为什么
同一天在同一个仓库里撞了两次，机制不同但形态一致：

1. **`curate 不卷入无关文件（提交边界）`**：探针提案写在 `$TMP`（ROOT 之外），`git add ../…`
   本就 fatal、整批提交失败，于是"无关脏文件没被卷入"平凡成立。它通过了，却掩盖了
   **commit 从未成功**这个更大的缺陷（连续 4 次 curate 全未提交、自动 push 静默失效）。
2. **`curate 空提交容错`**（我为修复补的新用例）：想测 stdout 并查分支，写完一次就绿。
   回退修复后**它照样绿**——查下来 `manifest.yaml` 头部有 `# rebuilt: <ISO 时间戳>`，
   每次 rebuild 必产生 diff，而 curate 总会 rebuild，所以经 curate 永远到不了"无可提交"。
   用例从来没碰到目标分支。

两次都是"断言的是没发生坏事"这一形态：**坏事没发生**既可能因为修复生效，也可能因为
根本没走到那条路径，二者在绿色里不可区分。改用 `solidify --to hook`（只提交 constraint、
不带 manifest，同 id 重跑内容字节一致）才真正走到该分支，回退验证转红。

## 证据（本会话命令 ↔ 结果）
- `npm test`（修复版）→ `✓ 空提交（无实际变更）判成功，不记降级` / `PASS=93 FAIL=0`
- 回退 `String(e.message) + String(e.stdout || '')` → `String(e.message)` 后 `npm test`
  → `✗ 空提交容错 (实得降级: "reason":"solidify: … :: Command failed: git commit -qm")` / `FAIL=2`
- 第一版（curate 构造）回退后仍 `PASS=93 FAIL=0` —— 空转的直接证据
- `diff` 连续两次 `evo index rebuild` 的 manifest → 仅 `# rebuilt:` 时间戳一行不同（空转成因）

## 边界 / 反例
- **不是要求每条用例都做红绿演练**：断言"发生了好事"（输出含某字符串、返回某值）的用例，
  写错通常直接就是红的，成本收益不划算。**该做演练的是断言"没发生坏事"的用例**——
  它们的绿色天然二义。
- 回退演练本身也可能骗人：若回退方式不等价于"缺陷仍在"（改错了行、改了不相关的地方），
  转红也不说明用例守住了目标分支。回退点要正对修复点。
- 分支不可达时，**正确动作是换构造路径或如实记为未覆盖，不是留个空转用例充数**。
  本次若找不到 solidify 这条路径，应当在注释里写明"该分支经公开命令不可达"。

## 失败信号（未来命中即该想起本条）
- 新加的用例第一次跑就绿，且你说不出它红的时候长什么样。
- 断言形如「grep -q 没有找到坏东西」「计数没变」「日志里没有错误」。
- 修复提交里用例和实现同时进去，从未单独跑过只有用例、没有实现的状态。
