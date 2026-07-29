---
id: 2026-07-28-qmatrix4x4-data-returns-column-major-tuple
type: playbook
status: validated
scope: global
domain: qt-opengl
tags: [qt, pyside6, pyqt, qmatrix4x4, opengl, column-major, pick, raycast, coordinate]
triggers:
  - pyqtgraph.opengl / PySide6 / PyQt 里做鼠标点击拾取（pick），要把屏幕坐标投影回 3D 求射线或交点
  - 用 QtGui.QMatrix4x4 的投影/视图矩阵做坐标变换（unproject / ray-cast / 逆投影）
  - 鼠标拾取算出的射线方向或交点坐标系统性偏移、平移量错位，怀疑矩阵元素读取顺序
  - 把 QMatrix4x4.data() 直接 np.array(...).reshape(4,4) 当行主序 numpy 数组用
  - OpenGL unproject 后点云/物体的世界坐标整体偏一个平移量
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:b417294c-e36b-45ac-a400-4a60f30d3453
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
---

# QtGui.QMatrix4x4.data() 返回列主序的 16 元素 tuple，平移在第 4 列

PySide6/PyQt 的 `QtGui.QMatrix4x4.data()` 返回的是**列主序**（column-major）的 16 元素 `tuple`，与 OpenGL 的存储约定一致：平移分量落在**第 4 列**（index 12/13/14），不是行主序；返回类型是 `tuple`，不是 numpy array。直接 `np.array(m.data()).reshape(4,4)` 当行主序用、或假设前 4 个元素是第一行，会把平移/旋转算反，导致拾取、逆投影、ray-cast 的坐标系统性错位。

## 证据

本会话做 pyqtgraph.opengl 点云点击拾取时，直接探测了矩阵存储：

```
$ python3 -c "
from PySide6 import QtGui
m=QtGui.QMatrix4x4(); m.translate(1,2,3)
print(type(m.data()), list(m.data()))"
  ↳ <class 'tuple'> [1.0, 0.0, 0.0, 0.0,  0.0, 1.0, 0.0, 0.0,  0.0, 0.0, 1.0, 0.0,  1.0, 2.0, 3.0, 1.0]
```

`m.translate(1,2,3)` 之后，平移 `(1,2,3)` 出现在 index 12/13/14，前 12 个是单位旋转/缩放矩阵的**三个列**——这是列主序排布（按列填充：列1=[1,0,0,0]、列2=[0,1,0,0]、列3=[0,0,1,0]、列4=[1,2,3,1]）。`type` 是 `tuple`。

## 怎么做

1. 从 `QMatrix4x4.data()` 取矩阵喂给 numpy 时，**显式按列主序 reshape**：`np.array(m.data()).reshape(4,4, order='F')`（Fortran order = 列主序），或 reshape(4,4) 后转置 `.T`，别默认行主序。
2. 若只需取平移量，直接用 `m.row(3)` 之外的专用 API：`QMatrix4x4` 提供 `m(0,3)/m(1,3)/m(2,3)`（行,列）按行列下标访问，或 `m.data()[12..14]`——但**别**误读成 `data()[0..2]`。
3. OpenGL unproject / ray-cast 对不齐时，第一步先打印 `list(m.data())` 确认平移落在哪 4 个槽，再决定转不转置。

## 边界

- 这是 `QMatrix4x4`（Qt 自己的 4×4）的行为；`QTransform`（2D 仿射）和 numpy 自己构造的矩阵存储顺序另说，别外推。
- 不同 Qt 主版本（Qt5/Qt6）的这个 API 行为一致，但若换了绑定（如 PySide2 早期）建议重测。
- 证据来自 PySide6 6.11.0 + Python 3.14；只验证了 `translate` 一种构造，旋转/缩放/投影复合矩阵的列序同理但未在本会话单独验证。
