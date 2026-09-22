---
id: mount-check-must-verify-ownership-not-existence
type: playbook
status: validated
scope: global
domain: verification
tags: [deployment-check, hook-mount, path-drift, ownership, existence-check, doctor]
triggers:
  - "自检项只确认「挂载存在」，但要防的是「挂载指向了别处」"
  - "同一台机器上有两份同名工具的副本，不确定命令实际跑的是哪一份"
  - "换了仓库位置 / 建了第二份副本之后，工具照常工作但写的数据不见了"
  - "给部署自检加一项挂载检查，不确定该判到什么粒度"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:2a5c9cfe-7ff2-46f2-800e-c160ffe842a5
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [bin-shim-symlink-still-points-old-repo, config-symlink-reference-scan-before-delete, same-name-repo-verify-by-remote-url, launchd-service-rebootstrap-after-dir-move, check-expected-state-must-flip-with-design-decision]
---

# 挂载检查必须判「归属」（路径），只判「存在」发现不了指向别处

**主张**（范围：**绝对路径形式的 command + 本库这一处自检**的一次实现，n=1）：
部署自检里查挂载时，`command 里含不含工具名` 这个判据只能证明**存在**，证明不了**归属**。
失效信号是**静默**的——挂载在、命令也跑得通，判据照样报绿。判据必须**比较路径**
（挂载点是否指向本仓库）。

> **同源**：本条与 `check-expected-state-must-flip-with-design-decision` 出自**同一次** doctor 第 6 项重写
> （commit `db6fd48`）——**一次观测被拆成两条**，别当两条独立的经验计权。

## 证据（2026-09-22，命令 ↔ 结果）

- 本次改判据时把这一维显式写进检查与 smoke（fixture 用不存在的路径模拟「指向他处」，
  **没有观测到一次真实的「写进了另一份库」**——那一步是推断，不是实测）：
  三件套齐且 command 含本仓库绝对路径 → PASS；
  齐但指向别处（fixture 用 `/nonexistent/other-evo/bin/evo`）→ WARN「挂载指向非本仓库路径」；
  缺件 → WARN「部分挂载，缺: …」。`npm test PASS=149 FAIL=0`。
- 对照：`doctor` 第 6 项改前的判据只看 `c.includes('evo') && c.includes(sub)`——任何叫 evo 的可执行文件
  都能通过，看不出它是不是本仓库的那一份。

## 边界 / 反例

- 同族但不同载体，别互相套用：`bin-shim-symlink-still-points-old-repo` 讲的是仓库迁出后
  `~/bin` 里的**软链**仍指旧树；本条讲的是**harness 挂载命令**里的路径参数。机制同源
  （「入口指向别的树、照常工作、静默」），但排查手法不同（那条查软链目标，本条比对命令里的路径）。
- 路径比较要防**同一路径的多种写法**（软链、`..`、相对路径）。本库的挂载点用的是绝对路径，
  所以直接 `includes(ROOT)` 够用；换成软链指向时该判据会失效，需要先 `realpath` 归一。
- 判到 WARN 而不是 FAIL：挂载指向别处不会损坏内核（库本身照常可用），但它会**静默地**把数据写到别处——
  所以必须可见。
- **未度量**：「这是最难发现的一类漂移」这类最高级/比较级断言本条没有支撑，不写；
  本条只主张「失效信号是静默的」。
- 一般化的边界：证据只覆盖「绝对路径 command + 本库这一处自检 + 合成 fixture」。
  把它推广到别的载体（软链、相对路径、别的 harness 的挂载）未经任何验证。
