---
id: pyqtgraph-imageitem-axisorder-is-attribute
type: lesson
status: candidate
scope: global
domain: pyqtgraph
tags: [pyqtgraph, imageitem, axisorder, api-shape, probe-script]
triggers:
  - "取 pyqtgraph ImageItem 的轴序：写 image.axisOrder 还是 image.axisOrder()"
  - "探针/核验脚本里把 axisOrder 当方法调用（失败信号：取不到值或调用报错）"
  - "对照 pyqtgraph 源码确认某字段是属性还是方法"
  - "写 UI 坐标映射探针前要确认图像的轴序约定"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7d2-d6f6-777c-a410-3276fccc9642
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pyqtgraph-imageitem-maptodata-transposed-coords, pyqtgraph-imageitem-setrect-after-setimage]
---

# pyqtgraph ImageItem.axisOrder 是属性，不是方法

**主张**：`ImageItem.axisOrder` 在 `__init__` 里被赋值（源码 `self.axisOrder = getConfigOption('imageAxisOrder')`），必须按属性访问 `image.axisOrder`；写成 `image.axisOrder()` 是错的。本会话探针脚本里就写成了调用形式，随后用 sed 去掉括号改成属性访问。

**证据**（命令 ↔ 结果）：
- 源码核对：`grep -n "def mapToView\|def mapToData\|def setRect\|def viewRect\|_im…" …/pyqtgraph/graphicsItems/ImageItem.py` → `89: self.axisOrder = getConfigOption('imageAxisOrder') 91: …`——即赋值语句，非 `def`。
- 修正命令：`sed -i '' 's/wb.map_view.image.axisOrder()/wb.map_view.image.axisOrder/' /tmp/audit1.py`，修正后同一命令链重跑该探针（输出首行为已知的 `qt.qpa.fonts` 字体别名警告）。
- 环境：PySide6 6.11.0 / pyqtgraph 0.14.0（同会话版本探针 `6.11.0 0.14.0 2.3.4`）。

**边界 / 反例**：
- 切片里**看不到** `.axisOrder()` 的原始报错文本，本条只钉死「该字段是属性」这一源码事实与本次修正动作，不记录具体异常类型。
- 同类 Qt/pyqtgraph 字段不可一并类推：写探针前对拿不准的字段先 `grep 'def <name>'` 或 `grep 'self.<name> *='` 判形态，比运行后看报错便宜。
