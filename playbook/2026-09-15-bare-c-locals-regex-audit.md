---
id: bare-c-locals-regex-audit
type: bullet
status: validated
scope: global
domain: c-style
tags: [c, naming, regex, audit, ripgrep]
triggers:
  - "审查/审计 C/C++ 代码的命名规范（无前缀裸变量、前缀约定）"
  - "要一次性列出 C 模块里所有无前缀局部声明并逐文件计数"
  - "reviewer 声称某文件有 N 个无前缀裸变量，要验证这个数量"
  - "改完 C 代码后想扫一遍有没有新引入的裸局部变量"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a736-c1c3-7353-8a3d-4313be973fae
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
---

用正则匹配「缩进(≥4 空格) + 自定义类型 + 小写裸变量名」的组合，能一次性列出 C 模块里所有无前缀局部变量并逐文件计数，量化命名违规的影响面。

为什么：本例对 `core/src/math/` 跑 `rg -n '^\s{4,}(uint32_t|Real_t|ComplexF_t)\s+[a-z][A-Za-z0-9_]*\s*[;,]'`，得到逐文件计数（complex.c 3 / eig.c 20 / fft.c 24 / …），并精确定位 eig.c:26 `uint32_t i;`、:27 `uint32_t j;`、:28 `uint32_t sweep;`、:48 `uint32_t p;`、:49 `uint32_t q;`。关键在「变量名首字母小写且无约定前缀」即命中违规——裸 `i/j/p/q` 这类局部计数器不符合「路径即命名空间 / 前缀约定」规范。

边界：类型集合要按项目实际用的自定义 typedef 替换（Real_t/ComplexF_t 是本项目的），前缀约定不同（如要求 ptr/const 前缀）需相应调整模式。此正则只扫声明，不扫使用处；缩进阈值 4 空格是为避开函数签名/宏里可能误匹配的项，单文件代码风格不同时需微调。
- 2026-09-16 独立复验（交互模型，非原会话）：在合成 C 文件上重跑该正则，命中 `uint32_t i;`/`uint32_t j, k;`/`Real_t scale;`，未命中函数签名 `Real_t foo(Real_t x)` 与 `int z;`——模式行为与声称一致。
