---
id: checker-positive-control-or-negative-void
type: lesson
status: candidate
scope: global
domain: verification
tags: [checker, positive-control, false-negative, regex, plist, launchd, delete-safety]
triggers:
  - "写脚本判定某文件/服务不存在、准备据此删除或下线"
  - "自造检查器的否定结论（假阴性）被当成成果"
  - "从 launchd plist 用正则抽路径判定存在性（路径含空格被截断）"
  - "结构化格式（plist/XML）该用 plutil/PlistBuddy/plistlib 而不是正则"
  - "判定脚本要先喂已知为好的样本做阳性对照"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-14-07-14-55-471-oypb
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [grep-verify-untracked-artifact-stale-before-delete, substring-matcher-cannot-tell-exec-from-mention]
---

# 主张

自造检查器必须做阳性对照，否则其「发现量」与可靠性负相关。

# 实例

用 `python re.findall(r"(/[A-Za-z0-9_./+-]+)")` 从 launchd plist 抽路径判定存在性，字符集不含空格 → `~/Library/Application Support/MathWorks/...` 被截成 `/MathWorks/...`，谎报缺失，据此删掉一个正常工作的 MATLAB ServiceHost LaunchAgent（损失 1KB plist，可从 `mci/InstallMathWorksServiceHost.app` 恢复）。

同批 3 条中 2 条恰好正确（JetBrains 确已卸载；caddy 路径无空格故解析正常），部分正确掩盖了整体不可靠。

# 机理

坏检查器生产假阴性，而假阴性看起来像成果（你发现了可删的东西）。

# 规则

- 判定脚本必须先喂已知为好的样本并断言回报「好」，不过关则其否定结论整批作废；
- 结构化格式用 `plutil`/`PlistBuddy`/`plistlib` 不用正则；
- 判缺失前先 `cat` 原始文件。
- 自研检查要先排除「恒假判据」：`i not in src`（import 名必出现在自己那行 import 里）这类条件会让检查对所有输入都返回空、把「没检查」伪装成「全绿」；未使用符号检查应基于 ast 的 Name/Attribute 引用集合，并用第二种独立手段（`grep -c <name>`）交叉确认。
- 自动化的**阴性**结果不能升级为普遍结论：osascript 驱动的 Finder 场景全部报「未生成 .DS_Store」，17 小时自然使用后普通目录再生 13 个推翻——阴性只说明「这套脚本没触发」；阳性对照（桌面放文件 3 秒即生成）仍有效，判定 GUI 副作用以自然使用后的现场观测为主。
