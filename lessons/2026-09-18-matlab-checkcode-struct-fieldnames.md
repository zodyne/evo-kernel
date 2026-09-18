---
id: matlab-checkcode-struct-fieldnames
type: fact
status: candidate
scope: global
domain: matlab
tags: [matlab, checkcode, static-check, struct, fieldnames]
triggers:
  - "用 matlab -batch 跑 checkcode 做静态检查 / 回归，要取返回结构体里的字段"
  - "MATLAB 报 Unrecognized field name（失败信号），怀疑 checkcode 返回字段猜错了"
  - "把 checkcode 结果汇总成报告，需要拿到消息、行号、修复建议"
  - "无头会话里批量检查 .m 脚本，想一条命令打印所有告警"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a977-6e7b-77c1-a593-51a2cfa0a8bf
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [matlab-batch-awt-x11-warning-nonfatal, macos-matlab-app-bundle-not-in-path, spc865-script-hardcoded-frame-index-overflow]
---
# MATLAB checkcode('-struct') 的字段是 message / fix / line / column

**主张**：`checkcode('<file>.m','-struct')` 返回的结构体数组，每项的字段名为 `message` / `fix` / `line` / `column` 四个（本会话 `disp(fieldnames(r))` 实测）。写批处理 / 回归脚本前先 `disp(fieldnames(r))` 枚举，再按实际字段取值，不要凭记忆猜字段名——猜错时 MATLAB 只报 `Unrecognized field name`，不告诉你正确字段有哪些。

**为什么**：checkcode 是把 .m 静态检查接进无头流水线（agent 会话审 MATLAB 脚本）的最省事入口，脚本里一行取错字段就整条命令失败；先跑一次 fieldnames 是最便宜的确认。拿到字段后可以逐条打印 `line` + `message`，例如本会话就得到 `L209: Variable appears to change size on every loop iteration` 这样的定位行。

**证据（本会话命令 ↔ 结果）**
- 第一次尝试：`matlab -batch "r = checkcode('docs/awr294x_spc865_v1.m','-struct'); if isempty(..."` → 输出 `Unrecognized field n...`（取结构体字段失败）。
- 改为先打印字段名：`matlab -batch "r = checkcode('docs/awr294x_spc865_v1.m','-struct'); disp(fieldn..."` → `{'message'} {'fix'} {'line'} {'column'}`，随后按字段打印出 `L209: Variable appears to change size on every loop ite...`。
- 运行环境：macOS 无头 `matlab -batch`（PATH 探测不到 matlab，需用绝对路径 `/Applications/MATLAB_R2024a.app/bin/matlab`）。

**边界 / 反例**
- 字段列表实测于 MATLAB R2024a（macOS）；其他版本可能增补字段，但「先 fieldnames 再取」的用法不受影响。
- 切片没有保留第一次尝试取的是哪个字段名，只能确认它撞了 `Unrecognized field name`。
- 切片里没看到 `fix` 字段的非空样例，不能据此判断修复建议的可用性。
- checkcode 是静态检查，通过了不代表脚本能跑（见 `spc865-script-hardcoded-frame-index-overflow` 这类运行时问题）。
