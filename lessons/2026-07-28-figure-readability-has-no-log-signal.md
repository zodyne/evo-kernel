---
id: figure-readability-has-no-log-signal
type: lesson
status: candidate
scope: global
domain: latex
tags: [tikz, figures, verification, vision-check]
triggers:
  - "改完 TikZ/流程图后想确认图是否可读"
  - "编译日志全绿但不确定图长什么样"
  - "图里的边标签和节点挤在一起 / 标签压住方框"
  - "无法直接看到渲染结果时如何验证图表质量"
  - "把 LaTeX 编译检查脚本的输出当作图已合格的依据"
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:dc63fb24-b5f6-455e-87c6-6bfc029de1eb
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
---

编译日志能证明图**没超宽**，但证明不了图**可读**。"标签压住节点""箭头穿过方框""标签互相重叠"这类缺陷在 `.log` 里**零信号**——必须渲染成 PNG 目视。

硬证据（本次两轮修复）：修完宽度后 `latex-figure-check.sh` 报 `overfull boxes > 15pt … (none above threshold — good)`，文本信号全绿；但 `pdftoppm -png -r 110` 渲染出来后，`slice / reflect` 和 `人审 curate` 两个边标签明显压在相邻节点的边框上。把标签 y 从 0.28 提到 0.78 后才干净——这一步没有任何日志能提示。

根因是布局约束冲突：紧凑排版下节点间空档约 1cm，而 `slice / reflect` 在 `\scriptsize` 下约 1.5cm，塞进去必然压到邻居。

手法：**边标签放到节点上沿之上那条空带**（y > 节点半高），横向多宽都无所谓，因为那一层没有别的东西：

```latex
% 节点在 y=0、minimum height=1.0cm → 占据 y ∈ [-0.5, 0.5]
\node[annot] at (2.15, 0.78) {slice / reflect};   % 让开节点带
```

比在节点间空档里挤更可靠：空档宽度取决于节点实际内容宽（不可心算），上沿空带的净空只取决于节点高（可心算）。

验证流程：`pdftoppm -png -r 110 -f <n> -l <n> doc.pdf out` → 交给能看图的 agent 或自己看，问具体问题："有箭头穿过节点吗？标签重叠吗？文字溢出方框吗？"
