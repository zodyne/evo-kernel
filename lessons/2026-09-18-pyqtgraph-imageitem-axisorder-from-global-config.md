---
id: pyqtgraph-imageitem-axisorder-from-global-config
type: lesson
status: candidate
scope: global
domain: pyqtgraph
tags: [pyqtgraph, imageitem, axisorder, global-config, orientation]
triggers:
  - "审查 pyqtgraph 图像（Range–Doppler 等二维矩阵）的朝向是否转置"
  - "同一份绘图逻辑在不同脚本/离屏截图里朝向不一致（失败信号）"
  - "想改图像轴序：动 ImageItem 属性还是 pg.setConfigOption"
  - "给涉图核验脚本写坐标映射探针前要确认轴序是谁给的"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7d2-d730-777c-a410-3278f21956a2
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pyqtgraph-imageitem-axisorder-is-attribute, pyqtgraph-imageitem-maptodata-transposed-coords]
---

# `ImageItem.axisOrder` 是构造期从全局配置 `imageAxisOrder` 取的一次快照

## 主张

pyqtgraph（本机 0.14.0）里 `ImageItem` 的轴序**不是每张图各自的参数**，而是实例化时从全局配置取的一次快照：
安装源码 `.../pyqtgraph/graphicsItems/ImageItem.py:89` → `self.axisOrder = getConfig('imageAxisOrder')`。
所以审「图有没有转置」时要查的是**创建该 item 那一刻的全局 `imageAxisOrder`**（谁、在什么时机调 `pg.setConfigOption('imageAxisOrder', ...)`），
不能只看数据形状或图注；改朝向的正规入口是全局配置，而不是逐图 properties。

## 证据（本会话命令 ↔ 结果）

- 版本与源码行一次拿到：
  `python3 -c "import pyqtgraph,os;print(os.path.dirname(pyqtgraph.__file__));print(pyqtgraph.__version__)"` → `0.14.0`
  （路径 `/opt/homebrew/lib/python3.14/site-packages/pyqtgraph`），紧接着打印出 `=== paint row-major === 89: self.axisOrder = getConfig('imageAxisOrder')`。
  会话正是在这一点上核「图像是按 row-major 还是 col-major 画的」。
- 同一轮 UI 核验是在离屏环境跑的：核验脚本里 `os.environ.setdefault("QT_QPA_PLATFORM","offscreen")`，
  即这套朝向语义同样适用于不弹窗的截图/探针脚本，不只是人工开的窗口。

## 边界 / 反例

- 本会话**没有实测默认值**是 row-major 还是 col-major（切片里只有那一行源码与探测脚本的环境噪声输出），所以本条不写默认值，
  只钉死「值来自全局配置、且在实例化时被赋值」这一源码事实。
- 「item 建好之后再改全局配置不会改已有 item」是由「初始化期赋值」这一源码形态推出的**推断**，本会话未做该对照实验；
  若要在核验脚本里依赖它，先花一行验证。
- 本条与 [[pyqtgraph-imageitem-axisorder-is-attribute]] 是同一字段的两个不同坑：那条讲怎么取值（属性 vs 方法），
  本条讲取到的值是谁给的、什么时候给的，不重复。
