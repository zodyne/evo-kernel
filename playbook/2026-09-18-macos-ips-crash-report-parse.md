---
id: macos-ips-crash-report-parse
type: lesson
status: validated
scope: global
domain: macos
tags: [macos, crash-report, ips, json, forensics, crash-triage]
triggers:
  - "拿到 ~/Library/Logs/DiagnosticReports 下的 .ips 崩溃报告，要读崩溃栈、信号类型和出事的库"
  - "用 json.load 整份解析 .ips 直接抛异常（失败信号：首行不是完整 JSON）"
  - "手上有几十份 .ips，想按崩溃栈签名归并分类、找出重复最多的那一类"
  - "要判断一次崩溃是谁触发的 / 属于哪条代码路径（帧里只有 symbol，没有库名）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a90b-fa1b-769f-b2a4-6c411d10843a
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: []
---

# macOS `.ips` 崩溃报告是「两段 JSON」：首行头 + 其余 body，栈要经 `usedImages` 还原库名

## 主张

`~/Library/Logs/DiagnosticReports/*.ips` 不是单份 JSON：**第一行是元数据头 JSON，剩下的全部是 body JSON**，
必须分开解析（`h, body = open(p).read().split('\n', 1)` 后各自 `json.loads`）。常用取数位置：

- 头 `H`：`app_name` / `app_version` / `bug_type` / `bundleID`（进程与解释器版本在这里）。
- body `B`：`B['exception']['signal']`（SIGSEGV / SIGABRT）、`B['threads'][B['faultingThread']]` 取崩栈。
- 帧对象**只有** `imageIndex` 与 `symbol`，库名要回查 `B['usedImages'][frame['imageIndex']]['name']`——
  不还原库名会把 `destroyQCoreApplication`（Qt 收官）和 `glDrawArrays`（GL 渲染）看成同类。
- 把 `(app_version, signal, 前 N 帧 "image/symbol" 拼接)` 当 key、用 `collections.Counter` 归并，
  几十份报告立刻收敛成「哪一类崩得最多」的可行动结论。

## 为什么

崩溃报告的签名判据是「信号 + 库 + 符号链」，缺任一项都会把不同责任方混在一起；
先归并再下结论，才能把「Qt/Python 退出路径的问题」与「自家 C 库越界」「GL 渲染路」分开对待。

## 证据（2026-09-16 会话内命令与结果，均 exit 0）

- `glob('Python-*.ips')` 计数 + 按日统计：共 21 份 = 09-11 两份 + 09-16 十九份。
- 单份解析：`proc: Python 3.14.7 | os: macOS 15.7.8 (24G824)`、`bug_type 309`、
  faulting thread `com.apple.main-thread`、栈顶 `Python/func_dealloc`。
- 归并分类输出：9×`atexit → destroyQCoreApplication → QGraphicsScene/QGraphicsWidget dtor → func_dealloc`
  （libqoffscreen）、7×`GLEngine/glDrawArrays`（libqcocoa）、
  2×`libalgommw_bind.dylib/prvGridPeak2D ← eDoaBeamEstimate`、1×`QFrame` 构造 SIGABRT、
  1×`QTableWidget::setRowCount`、1×退出时 `func_dealloc`。
- 头部字段实测（同一份报告）：`app_name = Python`、`app_version = 3.14.7`、`bug_type = 309`、
  `bundleID = org.python.python`。
- 运行时线索补位：`log show --last 12m --predicate 'process == "ReportCrash" OR process ==
  "CrashReporterSupportHelper"' --info` 能拿到报告生成时刻的系统日志。
- 这份分类直接决定了当天的三条修法（静音弹窗 / `os._exit` 收尾 / 另立真 bug 待查），
  说明「先归并再修」的路径可复现。

## 反例 / 边界

- 头行字段随 `bug_type` 变化，脚本一律用 `.get()` 容错；直接 `json.load(open(p))` 整份解析必然抛异常。
- 帧里的 `symbol` 可能缺失（显示为 `?`），归并 key 要允许空符号，否则会把同一类拆成多类。
- 没有视觉通道时的替代：`screencapture` 未获屏幕录制权限只拍得到壁纸，看不见弹窗；
  本会话全部取证都靠 `.ips` + `log show`，没有截图证据。
