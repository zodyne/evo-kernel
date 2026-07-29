---
id: proposal-independent-review-before-curate
type: lesson
status: validated
scope: global
domain: experience-engineering
tags: [distill, review, quality-gate, proposals]
triggers:
  - "distill 蒸馏写完提案、准备 curate 入库前"
  - "一批经验提案要批量入库，想加一道质量闸"
  - "提案的证据其实撑不住主张，但自己反复看看不出来（失败信号）"
  - "给经验库/知识库设计写入侧流程，决定评审插在哪一步"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [independent-design-review, review-packet-completeness-is-assemblers-duty]
---

# 提案入库前过一次独立模型评审：伪经验在自审里是隐形的

## 主张

distill 产出的提案在 curate 入库前，先交给独立模型（非产出者）逐条评审"主张是否站得住、证据是否支撑普适程度"。作者是盲的——本次 4 份提案自审全过，独立评审一轮抓出：1 份中心证据不满足自己的前提（删除重写）、3 份措辞/边界修正。

## 为什么

本次会话对 4 份待入库提案用 pi 做独立评审，裁决结果：

- `self-contained-task-needs-no-tools`：中心证据不满足自己声明的前提 → `rm` 删除并重写成另一条主张收窄的提案；
- 其余 3 份（test-may-pass、streaming-protocol、review-packet）：分别修正 trigger 与边界矛盾、"逐字"降级为标注推理 + 补 confound、修单位 + 补最致命反例。

评审包按 review-packet-completeness-is-assemblers-duty 组装（用户原话逐字 + 完整材料），且评审任务本身 `-nt`（无工具），符合 open-ended-task-plus-tools-has-no-stop-condition 的边界。

## 反例/边界

- 评审结论**逐条裁决、不照单全收**——评审员也会错，每条意见要回证据复核后再改。
- 单条琐碎提案（typo 级）不必走评审，批量/高风险（要进注入集影响后续所有会话）才值得。
- 评审模型与产出者同模型时独立性打折，尽量换 harness/换模型。

## 证据

- 命令：`pi -p --mode json -nt --thinking medium "$(cat /tmp/prop-review.txt)"` 输出逐条意见；随后 `rm ops/proposals/2026-07-28-self-contained-task-needs-no-tools.md` 并重写为 open-ended-task 提案；另三份按意见修订后 4 份全部 curate 入库（commit `421e9a5` / `5b36f57` / `0eb3d42` / `6c30291`；
  manifest 60→67，该区间含同批 rebuild 带入的非提案条目，故差值大于 4）。
- 入库前复核订正（2026-07-29）：本条初稿写「manifest 64→66」与「4 份全部入库」自相矛盾，
  按 `git show <commit>:index/manifest.yaml` 逐提交复算后订正——**提案自报的数字同样要交叉核对**。
