---
id: test-fixture-id-poisoned-by-upstream-seed
type: lesson
status: deprecated
scope: global
domain: testing
tags: [testing, fixture, shared-state, vacuous-assertion, smoke, false-green]
triggers:
  - "在共享状态的测试文件里新增断言，复用了现成的实体 id/用户名/文件名"
  - "新加的两条断言一条红一条绿，且绿的那条怎么改都绿"
  - "断言逻辑看着对，但测的对象已被同文件上游改过状态"
  - "测试通过了却证明不了任何事（空过 / vacuous pass）"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: skill:test-driven-development
schema_version: 1
---
在**共享同一份状态**的测试文件里加断言时，别图省事复用一个现成的实体 id——同文件上游可能已经把它改成了你要测的相反状态，于是「触发条件」那条断言恒假、「豁免条件」那条恒真（空过）。**一红一绿最危险**：红的那条会让你去怀疑刚写的实现，而绿的那条其实什么都没证明。

**证据**：给 evo-kernel 加"空转退役候选"的两条 smoke 断言，测试对象选了 `arxiv-api-rate-limit`。同一文件上游第 6 行早已给它 seed 了一行 `{"state":"adopted",...}`，而判据正是 `adopted === 0`——所以"进候选"永远不成立、"adopted≥1 即豁免"永远成立。换成上游没碰过的 `seed-failure-lessons-as-templates` 后两条同时转绿（68 → 70 PASS / 0 FAIL）。

**做法**：优先造**本断言专用的一次性 fixture**（`zz-<用途>-probe`），用完就删——不共享就不会被污染。非要复用现成实体时，先 `grep` 该 id 在本文件里的全部出现处，确认上游没动过它的相关状态。

**排错信号**：新加的一组正反断言里，反向那条（"不该触发时不触发"）**从一开始就绿**——先怀疑它是空过，而不是庆幸。让它临时失败一次（改成断言相反结果）确认它真的在测东西，再改回来。

**边界**：只针对共享可变状态的测试（同一临时 ROOT、同一数据库、同一日志文件）。每条用例起独立沙箱的测试不受影响，但那通常更慢——这条讲的正是"为了快而共享状态"要付的代价。
