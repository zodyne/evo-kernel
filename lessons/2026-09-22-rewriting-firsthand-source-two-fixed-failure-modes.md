---
id: rewriting-firsthand-source-two-fixed-failure-modes
type: lesson
status: candidate
scope: global
domain: verification
tags: [rewriting, evidence-fidelity, overreach, self-audit, adversarial-review, diff-only]
triggers:
  - "把一手来源（会话 capture / 口述 / 观测摘要）改写成经验条目或报告"
  - "改写稿读起来比原始材料更完整、更有说服力，但说不清多出来的部分是哪来的"
  - "自己审自己的改写稿，判不出问题（失败信号：只有你觉得没问题）"
  - "改完一轮之后想确认修复没有引入新的问题"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:2a5c9cfe-7ff2-46f2-800e-c160ffe842a5
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [proposal-independent-review-before-curate, label-evidence-source-type-per-recommendation, seed-failure-lessons-as-templates, doc-selfreported-counts-drift, evidence-grade-is-command-record-not-observed-wording]
---

# 改写一手来源的两个固定失效（同一批 8 条、同一来源类型的观测）；「修完」还会再犯一次

**主张**（范围：**同一支笔、同一批 8 条、同一来源类型（prose 摘要）**的一次观测，n=1）：
把一手来源改写成条目时观察到两个固定手法，写完值得按这两条逐句倒查；
并且**这一次修复动作本身引入了同类断言**，所以修完必须再审、且只审 diff。

两个固定手法（8/8 条同时命中）：

1. **补机制段** —— 每篇都加一节来源里没有的「为什么」。机制读起来最合理，也最没有证据。
   实测 8/8 `inventedMechanism=true`：来源只写「程序进了备用屏、buffer 行数恒等于窗口高度」，
   改写稿补出「备用屏按**终端语义**就是不滚动的画布 / libvterm **忠实实现**了这一点 /
   所以这不是 nvim 的 bug 而是**两种终端模型的碰撞**」——三条机制全部无据。
2. **去限定升格** —— 把一次性观测升成一般律。同一处观察：`Claude Code` → 泛「CLI」、
   `SSE 代理` → 泛「流式代理」、`\section` 标题 → 「标题/目录/**交叉引用**」、
   只测过**删除**导致索引前移 → 「中间发生了**增删**位置就会重排」、单次实测 → 普遍规律。

**修复会再犯一次，而且更难发现**：第一轮整改后给 8 条**统一**加了一句
「跑一次 X **即可复现**，跑通后可升回 `command`」——来源从未断言可复现性，8 条一个模板、6 条直书「可复现」。
更关键的是：**第一轮审核结构上看不到它**——它审的是改之前的文本。

> **同源**：本条与 `evidence-grade-is-command-record-not-observed-wording` 出自**同一批 8 条改写**
> （同一组审核产物 + 同一组 commit `1019166`/`6d366bb`）——一次观测的两个侧面，不是两条独立经验。

## 证据（2026-09-22 本会话，三轮审核）

- **数字口径（两条不同命令，不能并成一条——本条自身曾被独立评审指出并合并过一次）**：
  ① 按「证据节里含箭头/退出码/输出样式的行数」量（`awk 'f&&/^## /{exit} /^## 证据/{f=1} f' <entry> | grep -cE '→|rc=|exit=|http=|bytes'`）：
  8 条得 `1 1 0 0 0 0 0 0`（headless-ultracode 与 nvim-alt-screen 各 1，其余 0）；
  同一条命令量 reflector 写的 `bsd-grep-empty-subexpression-hard-error` 得 **2**。
  ② 换口径数「含行内代码跨度的行」（`grep -cE '`[^`]*`'`）时，对照条目得 **7**。
  → 两组数各自成立，但**不是同一条命令的产出**；引数时必须带口径。
  （踩过的坑：最初的 `awk '/^## 证据/,/^## /'` range 会塌成表头单行、对**所有**条目一律返回 0，
  正是它让「8 条一律为 0」看着像结论。修正 range 后并非一律 0。）
- **三轮结果**：原始稿 8/8 过度概括（审核产物实测 **3 significant**（headless-ultracode /
  nvim-terminal-alt-screen / auto-classifier）**+ 5 mild**）→ 整改后复核
  **0 still-broken / 0 改废**，但抓到修复新引入的统一模板句 + 5 处缺陷 → 对 diff 复审 **converged**。
- 审核产物（模型判定，非确定性命令，故本条 `verified_by: human`）：
  `~/.claude/projects/-Users-zodyne-Dev-evo-kernel/2a5c9cfe-.../subagents/workflows/wf_{cd870181-715,8b02d43b-448,d5e9a680-161}/journal.jsonl`

## 三条可复用判据

- **自查通过 ≠ 干净**（本次实例）。同一支笔自查时宣布 2 条「无走形」；独立审核判它们
  significant 与 mild，各带 5–6 条无据增写。→ **不要**把它升格成「作者普遍判不出自己的模式」
  这种对作者的一般断言：本条只有这一次观测。
- **修完只审 diff 的 `+` 行**，不重审全文——新引入的断言只可能在新增行里。
- **收敛判据要写明「什么不算问题」**：第三轮明确告知审核方「否定式限定（本次未测 / 不作断言）是收窄，
  不要判；只抓肯定式的、来源没有的事实/机制/可复现性断言」，才得到可解读的 converged。
  不加这条，审核会把「不要替它们下结论」也判成断言。
- **不要用统一模板句**：8 条一致的措辞正是无据断言的温床（同一支笔 8 条一致）。

## 边界 / 反例

- **n=1**：两个手法是在**同一支笔、同一批 8 条、同一来源类型**上观察到的。换作者、换来源类型
  是否同样成立未测——但**检查这两条的成本极低**，值得无条件倒查一遍。
- **「修完会再犯」也是一次观测**：本次是**一个**修复动作（一句模板被复制到 8 条），
  不等于「每次修复都会」。同理，「只审 diff 的 + 行」「不要用统一模板句」是**批内启发式**，
  待更宽样本检验，不要当已确立的规律读。
- 机制段并非一律该删：来源里**本来就写着**的机制必须留（本会话整改后逐句核对，来源支持的机制全在，
  没有出现「统一删整节为什么」的过度修正）。判据是**来源有没有**，不是「机制该不该有」。
- `human` 是因为核心主张依赖语义比对（模型判断），不是因为证据弱：单条「这个机制在来源里有没有」
  任何人都能靠读两段文字复核。
