---
id: package-verify-as-recipient
type: lesson
status: candidate
scope: global
domain: packaging
tags: [packaging, tar, verification, distribution, gui]
triggers:
  - "打包脚本/查看器/工具 tar.gz 发给他人前的验证"
  - "包内 --help 能跑就当验证通过"
  - "收件人解压后跑不起来、挂死或找不到依赖"
  - "GUI 程序打包验证（QT_QPA_PLATFORM=offscreen 模拟无显示环境）"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:40a7756a-b82e-42cf-9704-be6eafb35707
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [package-html-deadlinks-missing-assets]
---
# 分发包验证必须做"收件人视角"：解包到干净目录、清环境、真实启动，--help 通过不算

## 主张

打包交付物的验证，只在打包机的工作区里跑 `--help` 等于没验——工作区里的相对路径、PYTHONPATH、本地数据都会掩盖断链。要模拟收件人：**解包到一个干净目录、清空 PYTHONPATH、（GUI 程序）QT_QPA_PLATFORM=offscreen，然后用真实数据完整启动一次**。

## 证据

打包 `ucm221-viewer-filtered` tar.gz 时，初版 verify 只查 `--help`，脚本内注释自述：`"只 copy 文件不验证, 等于把断链留给收件人"`。实际在解包目录验证时：

- ❌ `tar -xzf ... -C recv` 后跑包内 viewer → `✗ Exit code 143 Command timed out after 10m`（挂死 10 分钟被超时杀掉）。
- 改 `package_viewer.py` 的 verify 后重打，终验命令：`cd $D && QT_QPA_PLATFORM=offscreen PYTHONPATH= python3 -u python/viewer_filtered.py -i <真实数据目录>` → 成功输出 `配置: n_grid=21 rho_thresh=0.3692(标定表) ... 500 frames 添加 xyz / 速度`。
- 末条 assistant 结论：`打好了，并且按收件人的方式验证过。`

## 反例/边界

- 真实启动成本高时可降级为"解包后 import + 加载最小样本"，但绝不能停在 `--help`。
- GUI 程序在无显示环境必须用 offscreen 平台插件，否则 QApplication 初始化即失败，验证不出真问题。
