---
id: synthetic-sandbox-mechanism-is-not-target-repo-risk
type: lesson
status: validated
scope: global
domain: code-review
tags: [adversarial, verification, evidence-provenance, sandbox, repro]
triggers:
  - "对抗式复核一条发现，发现方给的『该变换会改变行为』证据是它自己新建/手写文件跑出来的"
  - "准备判 isReal / confirm 时，发现所声称的代码形态在目标仓库里根本没以那种上下文出现（失败信号）"
  - "复核 include 顺序 / pragma 作用域类编译器变换『风险』，要判它在目标仓库是否真的会触发"
  - "最小复现在自造沙箱里成功，就想把发现升级成阻塞项"
  - "复核报告引用了一段变换前后差异，却没说明那段代码来自哪个仓库、哪个文件"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-ee02-7475-af70-36c7ee72ff22
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [adversarial-review-repro-as-written, adversarial-review-separate-evidence-from-impact-attribution, blind-spot-claim-needs-instance-count, readonly-verify-tmp-variant-git-status-proof]
---

**主张**：发现方在**自己新建/手写的文件**上复现出的机制（如「include 顺序会改变代码生成」）只证明**机制存在**，不证明**目标仓库里存在该风险**。判 isReal 必须回到目标仓库真实 HEAD 的副本上跑同一变体（看 rc/产物），并查该形态在仓库里是否真有对应上下文与消费者。

**为什么**：机制是编译器的普遍属性，任何一段手写代码都能把它演出来；而「风险」是「这个仓库里这处代码真的会这样」的断言。两者之间隔着「目标仓库是否真以那种形式写了那段代码」这一环。把前者当后者，就会把「理论上可能」升级成「实测风险」。

**证据（切片命令 ↔ 结果）**：

- 机制侧（合成载体）：复核方在 /tmp 自建的 `pragma-scope` / `order` 目录里手写内容后编译 → `=== alone === 8: fmadd … === before_fp === 8: fmadd … === after_fp === 8: fmul …`——机制确实可复现，但复现载体是复核 agent 自己造的文件。
- 目标仓库侧（真实 HEAD 副本，`git rev-parse HEAD` = `33a58c0ebd7ca6f71eb1b1e72f9453d478f92a38`，同一 hash 被复制到 `/tmp/review-refute-…/repo`）：
  - 同一批变体：`=== variant skip === rc=0 OK === variant add === rc=0 OK`（没有可观测差异）；
  - 入度核查：`sensor.hpp` 被 `core/src/types/waveform.cpp:14` 与 `core/include/types/radar.hpp` 真实引用；`compiler.hpp` 除 `./PLAN.md:74`（M18 检查行，指 `compiler.h` 宏使用）与 `./docs/baseline-manifest.txt:25` 的哈希外零引用；
  - 工作区核查：真实仓库 `git status --porcelain -- core tests tools` = 0 行，P1.0b 的 REPORT 里未提及这两个头。
- 裁决：`isReal = false`（事实属实，但「风险」不成立；所引变换证据是复核 agent 自己沙箱的模拟产物）。

**边界 / 反例**：

- 不否定合成复现的价值：它用来**证明机制存在**、为真实验证选靶点；本条只禁止把它当作风险成立的证据。
- 目标仓库里真存在同形态上下文（那处代码、那种 include 位置真的存在）时，机制复现 + 仓库实例两者齐备才判成立。
- 与 related 三条互补而不重叠：`adversarial-review-repro-as-written` 管「按发现方的原命令复现」；`adversarial-review-separate-evidence-from-impact-attribution` 管「证据与影响面分开判」；`blind-spot-claim-needs-instance-count` 数闸门覆盖域里的实例数；本条判「证据载体来自合成文件还是目标仓库」。
- 在目标仓库上验证时用 HEAD 副本（避免动被审仓库），收尾用 porcelain 自证只读，见 `readonly-verify-tmp-variant-git-status-proof`。

**失败信号（未来命中即该想起本条）**：发现方贴出的 repro 文件路径在 /tmp 或它自己的沙箱目录里；目标仓库里搜不到同形态的上下文/调用点；报告只给机制演示，给不出该形态在仓库中的一次真实出现。
