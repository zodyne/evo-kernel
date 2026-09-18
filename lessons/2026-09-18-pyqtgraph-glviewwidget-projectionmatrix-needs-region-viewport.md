---
id: pyqtgraph-glviewwidget-projectionmatrix-needs-region-viewport
type: lesson
status: candidate
scope: global
domain: pyqtgraph
tags: [pyqtgraph, opengl, glviewwidget, projection-matrix, ndc, qmatrix4x4]
triggers:
  - "要在 pyqtgraph GLViewWidget 上算 NDC/屏幕投影（核验 3D 视图填充度、给 GL 场景叠 2D 标注）"
  - "无参调用 GLViewWidget.projectionMatrix() 直接 traceback（失败信号：缺 2 个必需位置参数）"
  - "分不清 projectionMatrix 与 viewMatrix 的签名：一个要 (region, viewport)，一个无参"
  - "region / viewport 该传什么：getViewport() 返回什么、整窗渲染时两者是否相同"
  - "clip 坐标除以 w 求 NDC 时报 divide by zero / 结果出现 inf（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a82c-5169-7719-ba82-3202517e50bb
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pyqtgraph-gl-textitem-blank-in-grab-use-overlay, 2026-07-28-qmatrix4x4-data-returns-column-major-tuple]
---

# GLViewWidget.projectionMatrix 必须传 (region, viewport)，无参调用直接失败

**主张**：pyqtgraph 的 `GLViewWidget.projectionMatrix(region, viewport)` 是**要两个位置参数**的方法，两个参数都是 `(x, y, w, h)` 四元组；整窗渲染时 `self.getViewport()` 返回 `(0, 0, width(), height())`，直接把它传两次即可：`view.projectionMatrix(view.getViewport(), view.getViewport())`。无参调用只会拿到 traceback（缺 2 个必需位置参数）。相对的 `view.viewMatrix()` 才是无参方法——想在 GL 视图上做 NDC/屏幕投影（核验网面在视口里占多大、给 3D 场景叠 2D 标注），必须按签名把 `region`/`viewport` 显式传进去。

**为什么**：投影矩阵是按**当前视口几何即时算出来**的（源码里 `x0, y0, w, h = viewport`、`dist = self.opts['distance']`、`t = r * h / w`，frustum 完全由视口宽高与 `opts` 决定），所以它不存在"无参形态"。而 `viewMatrix()` 恰好无参，两者并列出现时极易混用：照着 `viewMatrix()` 的用法写 `projectionMatrix()`，失败点在投影那一步，和"矩阵元素顺序/NDC 数学"无关，容易误诊。

**证据（本会话命令 ↔ 结果，session 01a0a82c）**
- ❌ `/tmp/fix865/mesh_ndc.py` 第 24 行 `P = np.array(mesh.view.projectionMatrix().data()).reshape(4,4)  # column-major`（该行原文出现在紧随其后的 `sed` 表达式里）→ `Traceback ... File "/tmp/fix865/mesh_ndc.py", line 24, in <module>  P = np.array(mesh.view.pro...`
- ✅ 签名核对：`inspect.getsource(GLViewWidget.projectionMatrix)` → `def projectionMatrix(self, region, viewport):  x0, y0, w, h = viewport  dist = self.opts['distance']`
- ✅ 把 `region`/`viewport` 显式传进去（`sed -i '' 's|P = np.array(mesh.view.projectionMatrix().data()).reshape(4,4)  # column-major|w0,h0 = mesh.view.width(), ...'`，先取控件宽高）后，脚本不再在投影那一步失败，直接打出 NDC：`NDC x [-0.4616, 0.2614]  y [-0.3953, 0.1798]  z [0.9972, 0.9985] x 像素覆盖 253 / 700 y 像素覆盖 201 / 700`（改相机后同一脚本再测：`x 像素覆盖 365 / 700`）。
- 旁证：同会话 `inspect.getsource(GLViewWidget.viewMatrix)` → `def viewMatrix(self):`（无参），全程没报缺参。
- 本次蒸馏在本机复核（pyqtgraph 0.14.0 / Homebrew python3.14）：`inspect.signature(GLViewWidget.projectionMatrix)` → `(self, region, viewport)`；`getViewport()` → `return (0, 0, self.width(), self.height())`；`paintGL` 自用写法是 `region = self.getViewport(); self.paint(region=region, viewport=region)`。

**边界 / 反例**
- `region` 是"视口里要渲染的子区域"，`viewport` 是实际视口（pyqtgraph docstring：`region specifies the sub-region of viewport that should be rendered`）。整窗时两者相同；分屏/子区域渲染时不同，别照抄两次同一个值。
- 算 NDC 要除以 w：`ndc = clip[:, :3] / clip[:, 3:4]`。顶点落在相机平面附近/背后时 w→0，本会话实测有 `RuntimeWarning: divide by zero encountered in divide  ndc = clip[:, :3] / clip[:, 3:4]`，NDC 会出 inf——先按 w>0 过滤/裁剪再算包围盒。
- `QMatrix4x4.data()` 是列主序，别 `reshape(4,4)` 就当行主序 numpy 用（见 related `2026-07-28-qmatrix4x4-data-returns-column-major-tuple`）。

**失败信号（未来命中即该想起本条）**
- 探针脚本在 `view.projectionMatrix()` 那一行 traceback（缺位置参数），而 `view.viewMatrix()` 同处调用却正常。
- NDC 结果出现 inf / divide by zero 警告 → 先确认是不是 w≈0 的顶点混进了包围盒。
