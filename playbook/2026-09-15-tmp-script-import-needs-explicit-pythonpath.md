---
id: tmp-script-import-needs-explicit-pythonpath
type: lesson
status: validated
scope: global
domain: python
tags: [python, sys-path, pythonpath, tmp-scripts, import]
triggers:
  - "把核验/探针脚本写到 /tmp 再运行，import 项目包直接炸（失败信号：traceback 停在 import 行）"
  - "python3 -c 'import <项目包>' 在项目根能过，同一个 import 写进脚本文件就报错"
  - "为保持被审仓库只读，把临时验证脚本放在项目目录外运行"
  - "对抗式核验/只读审查任务里需要 import 被审项目代码做数值验证"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a4f5-f87f-777c-a410-3245b1d17afc
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [cwd-script-shadows-stdlib-module]
---
# 脚本放在项目目录外运行时，项目包 import 不会自动可见，须显式 PYTHONPATH

## 主张
`python3 -c "import <项目包>"` 在项目根目录下能成功（cwd 恰好在 import 路径上），
但把同样的 import 写进脚本文件、放到 /tmp 等项目外目录运行就会在 import 行报错——
因为脚本方式下起作用的是 `sys.path[0]`=**脚本所在目录**而不是 cwd。修复：运行时显式
`PYTHONPATH=<项目根> python3 /tmp/xxx.py`。

## 为什么
两条路径的 import 解析基准不同：`-c` 模式把 cwd（''）放进 sys.path，脚本模式把脚本文件
所在目录放进 sys.path。只读核验场景天然要把脚本放项目外（不污染仓库），于是「在项目根
探测通过」给人一种 import 没问题的错觉，换到 /tmp 立刻翻车，容易被误判成环境坏了。

## 边界 / 反例
- 与 cwd-script-shadows-stdlib-module 同源于 sys.path[0] 语义，但坑面相反：那条是
  脚本与 stdlib 同名**抢占**模块，本条是项目包**找不到**；排查方向不同（看 traceback
  落点是第三方库内部还是项目包 import 行）。
- 把脚本写进项目目录内也能修，但会污染被审仓库，只读核验场景不可取。
- PYTHONPATH 的值必须是含包的父目录（本例 ant_design/，包为 bpm_2t8r_sim/），不是包目录本身。

## 证据（2026-09-15 会话命令对照）
- `cd /Users/zodyne/Dev/ant_design && python3 -c "...import bpm_2t8r_sim..."` → 正常打印
  Python 3.14.7 / numpy 2.3.4 / 包路径。
- 同一 import 写入 `/tmp/vrfy/a1.py` 直接跑 → ✗ Traceback，落在 `File "/tmp/vrfy/a1.py",
  line 2, in <module>  from bpm_2t8r_sim.config import ...`（import 行即炸）。
- `PYTHONPATH=/Users/zodyne/Dev/ant_design python3 /tmp/vrfy/a1.py` → 成功输出 Tc/t_frame/
  cumsum 数值，脚本跑通。
