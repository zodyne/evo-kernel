---
id: data-file-discovery-vendor-prefix-glob-skips-batch
type: lesson
status: candidate
scope: global
domain: data-pipeline
tags: [glob, data-discovery, silent-skip, frame-header, parser, suc221]
triggers:
  - "从采集目录自动发现/批量装载数据文件（查看器、解析器、离线分析脚本）"
  - "glob 写死了厂商/批次前缀（TarData* / *_Target_*）"
  - "换了设备或批次后装载帧数骤降或为 0，脚本退出码却是 0（失败信号）"
  - "同一格式的数据文件被改名/换前缀后，工具直接视而不见"
  - "目录里存在多个批次的 .bin，发现逻辑只放行其中一种命名"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bcf1-4733-7265-ada1-fb36116f6be1
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [hardcoded-data-dir-rot-fails-late, macos-tcc-protected-dir-empty-glob]
---

# 数据文件发现写死厂商前缀 glob：同格式的新批次被静默挡住

## 主张

从采集目录发现数据文件时，不要写死厂商/批次前缀 glob（`TarData*.bin`）——同一格式的 `UCM221_Target_*.bin` 会被静默挡在门外（glob 只匹配到旧前缀，脚本不报错）；应扫 `*.bin` 并用帧头（`AA 55`）判格式。本例修复后 UCM221 批 8,957 帧 / 50,005 点正常装载，并补了 `DataFileDiscoveryTests`。

## 为什么

数据文件名带设备/项目前缀是常态，前缀换代（SUC221 → UCM221）不改变二进制格式，但会让前缀 glob 匹配为空。失败模式是静默的：目录存在、命令退出码 0、统计数字变小或为 0，人第一反应是"这批数据有问题"而不是"发现逻辑没放行"。格式校验应该基于帧内容而不是文件名——本例解析器本来就只看帧头 `AA 55` 与类型字节，`*.bin` 是安全上界。

## 证据（session 01a0bcf1，suc221-pointcloud-2.0）

- 旧实现：`sed -n '570,600p' python/viewer_filtered.py` → `files = sorted(glob.glob(os.path.join(data_dir, "TarData*.bin")))`。
- 新批次同格式：`xxd -l 32 data/UCM221_Target_20260914_171039/…_0000.bin` → `aa55 4f02 55aa …`（与解析器只认的帧头一致）；`python/lib/tcp_cfar_parser.py` 的 `load_tcp_frames` 自述"本解析器只看帧头 `AA 55` 与类型字节"。
- 修复与复验：代码注释写明 `叫 UCM221_Target_*.bin，写死前缀会把它们全挡在外面（实测 20260914 那批）`；修复后 `load_frames` 对 `data/UCM221_Target_20260914_171039` 输出 `8,957 帧 · 50,005 点`，`viewer_filtered.py -i data/UCM221_Target_20260914_171039 --headless` 正常给出 `KEEP: 1671 (3.3%)` 等统计。
- 回归：新增 `DataFileDiscoveryTests` → `Ran 82 tests ... OK`；共用装载件 `python/lib/dbf_scene.py` 的 `load_frames` 用 `*.bin`。

## 边界 / 反例

- 与 `hardcoded-data-dir-rot-fails-late`（硬编码目录消失 → FileNotFoundError）不同：本条是路径存在、**文件名模式**不匹配 → 静默漏数据，更隐蔽。
- 目录里混有多种格式时不能只按扩展名收：本例解析器有帧头校验兜底；没有帧头校验的格式要显式列"无法识别的文件"并报错，而不是跳过。
- 修完要注意调用方：`glob` 用法清零后如果还留着 `import glob` 会变成死导入（本例顺手删了），但这不是失败信号。

## 失败信号（未来命中即该想起本条）

- 换了设备/批次后帧数骤降或为 0，脚本退出码 0、无报错。
- 代码/文档里出现带厂商前缀的 glob（`TarData*`、`*_Target_*`），而目录里文件名已经换代。
- 新采的一批数据"解析器读不到"，实际是发现逻辑没放行。
