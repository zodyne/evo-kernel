---
id: spectra-state-off-conflates-not-computed-with-not-selected
type: lesson
status: candidate
scope: global
domain: testing
tags: [state-machine, test-gate, discriminative-power, algommw, spectra]
triggers:
  - "状态字段默认值把『未计算/未执行』和『执行后关闭/未选』合并成一个字面量，导致测试闸门判别力不足"
  - "外部从产物状态无法判断一个功能到底跑没跑（off/None 二义）"
  - "审查发现测试闸门判别力不足，要定位是哪个状态字段把没算报成没选"
  - "写状态机/枚举时，初始态与『关闭』态共用同一个字面量（失败信号）"
  - "验收测试绿但实际某功能从未被触发，状态字段读出来仍是 off"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a6aa-68f9-7353-8a3d-42e1f185ce1b
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [adversarial-review-repro-as-written]
---

状态字段的默认值若把「未计算」和「执行后关闭/未选」合并成同一个字面量（如 `off`），测试/验收闸门就失去判别力：外部无法从产物状态判断这个功能到底是被跳过还是被用户主动关掉。

## 为什么

algommw 的 Python 绑定 `python/core_bind/native.py`（约 160-185 行）里，`spectra_state` 的默认值写死为 `"off"`，源码注释自证其问题——`#: 把"没算"报成"没选"，把锅推给用户。` 随后紧跟 `self.spectra_state = "off"` 与 `self._spectra = dtypes.Spectra() if capture_sp...` 的条件初始化。也就是说：spectra 到底「没被计算」还是「被算了但用户没选」在产物状态里无法区分，读状态的人只能得到一个笼统的 off，于是判别「这条路径真跑过没有」的测试闸门失效。该发现经对抗式逐行复核后成立（refuted=false）：`chain.c:402` 是 `eChainDoaSpectraAttach`，guard 在 412/416，与 `bDirect/bIs1D` 分发对应。

## 边界 / 反例

- 不是所有 off 默认值都错：若「未计算」有独立哨兵（如 `None`/`"unset"`）而 off 仅表示「算过且关闭」，则无此问题。坑在两个字面量二义。
- 修复方向是引入可判别的三态（unset/computed-off/computed-on）或一个 `computed` 布尔，而非把 off 改个名字。
- 这类缺陷通常不是测试数量不够，而是状态建模本身把判别信息丢掉了——补再多断言也判不出来，得先修状态字段。
- 与 adversarial-review-repro-as-written 互补：那条管「逐字复现/逐行对行号核验发现」，本条是它核验出来的一条具体质量结论（状态建模削弱测试闸门判别力）。
