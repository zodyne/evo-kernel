---
id: verify-dylib-port-completeness-via-nm-symbols
type: lesson
status: candidate
scope: global
domain: c-porting
tags: [nm, dylib, symbols, porting, macos]
triggers:
  - "移植 C 库后验证动态库产物是否完整"
  - "检查 dylib/so 里预期函数符号是否真的导出了"
  - "nm -gU 查导出符号、nm 查 U 未定义符号（命令）"
  - "库里某模块的符号缺失或意外未定义（失败信号）"
  - "不确定新加源码有没有被编进最终库产物"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fb0ee-1906-76a9-a190-ba6c6e81dc29
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [compile-flag-zero-cost-verification]
---
验证 C 库移植完整性，不要只看"构建成功"：用 `nm -gU lib.dylib | grep -i <模块名>` 确认预期符号**导出齐全**，再用 `nm lib.dylib | grep ' U '` 排查**未定义符号**（本该库内定义的符号出现在 U 列表 = 对应源码没被编进去或依赖缺失）。

**为什么**：UCM221 libucm221 移植核查会话中，`make CC=cc` 构建通过后，正是靠 `nm -gU libSPX_ALG.dylib | grep -iE "Faf|Fpga"` 确认 faf 9 个导出符号齐全、靠 `nm ... | grep Track` 排查 Track* 未定义符号，才把"能编译"和"模块真的进了库"分开验证。构建系统（尤其 GLOB 收集源文件）可能静默漏编整个目录，链接成 dylib 时不报错（macOS 动态库默认允许未定义符号）。

**边界**：静态库 .a 的未定义符号语义不同（按需归档，U 属正常）；本条目针对动态库产物核查。与 compile-flag-zero-cost-verification 互补：那条用 nm 验证"符号不存在"，本条用 nm 验证"符号存在且已定义"。

**证据**：会话 019fb0ee 中 6+ 次 nm 检查命令及结果（faf 导出符号齐全、Track* 未定义符号逐项排查）。
