---
id: matlab-batch-awt-x11-warning-nonfatal
type: lesson
status: validated
scope: global
domain: matlab-runtime
tags: [matlab, macos, headless, stderr, warning, java, 判据]
triggers:
  - "在 macOS 上无头跑 MATLAB（-batch / 无人值守会话），stderr 出现 `WARNING: package sun.awt.X11 not in java.desktop`"
  - "看到 MATLAB 打出的 java / awt 模块告警，就想判定脚本失败、回滚或改走别的执行器（失败信号：把启动告警当失败）"
  - "一次 MATLAB 批处理跑完，手上只有 stderr 文本，要判断它到底成没成"
  - "给 MATLAB 脚本写流水线/回归，需要一条可靠的成败判据"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a819-cfaa-7485-9b7c-35a2cf425d94
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [macos-matlab-app-bundle-not-in-path, 2026-07-27-qt-offscreen-opengl-context-warnings-nonfatal]
---

**主张**：macOS 上无头跑 MATLAB 时 stderr 的 `WARNING: package sun.awt.X11 not in java.desktop` 是 Java 桌面模块的启动告警，**不是脚本失败信号**——本次运行在打印它两次之后照常完成并产出文件。判定成败要看产物/退出码，不能看这条 warning。

## 为什么

MATLAB 启动时初始化 JVM/桌面模块，macOS 的 java.desktop 里没有 X11 相关包，于是往 stderr 吐这行 WARNING；它出现在**脚本逻辑执行之前**，与用户的 .m 代码无关。若把它当失败信号，会导致：误判"无头跑不了 MATLAB"、白白改流程，或反过来在真正失败时以为"只是告警"而放过。

本会话实证（同一次运行）：
- 运行：`cd /Users/zodyne/Dev/SPC865 && mkdir -p output/adc_analysis && rm -f output/adc_analysis/* 2>/dev/null; time SPC865_ADC_SHOW_FIGURES=0 SPC865_ADC_SAVE…`（该行在切片里被截断）
- 输出：`WARNING: package sun.awt.X11 not in java.desktop` ×2，随后是脚本自己的 `Elapsed time is …`
- 紧接着 `ls -la output/adc_analysis/`：目录 mtime = 本次运行时刻（Sep 16 10:46），里面已有一个 `-rw-r--…` 产物文件。
- 该次运行的收尾结论（同切片末条 assistant）：`已跑通`。

## 怎么做

1. 看到这行 WARNING 继续跑，不要中断/回滚。
2. 成败判据用：MATLAB 退出码 + **产物是否落盘且非空**（如 `output/adc_analysis/` 下有文件）；只有 stderr 时，把这类 `WARNING: package …not in java.desktop` 与真正的 `Error using … / Undefined function …` 区分开——后者才是失败。
3. 批处理里最好显式检查产物文件存在/大小，而不是 grep stderr。

## 边界

- 告警"非致命"≠"绝不致命"：若脚本本身依赖 Java/AWT 组件（javaObject、GUI 回调），缺 X11 相关包可能真影响功能——以实际产物正确性为准。
- 本证据来自 macOS + MATLAB R2024a + 一次无头 ADC 分析运行；其他 MATLAB 版本/平台告警文本可能不同。
- 同类"离屏/无头告警吓人但非致命"的先例（Qt/OpenGL）见 related。
