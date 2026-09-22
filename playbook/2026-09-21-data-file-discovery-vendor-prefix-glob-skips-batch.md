---
id: data-file-discovery-vendor-prefix-glob-skips-batch
type: lesson
status: validated
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

## 2026-09-22 独立复核增补

下列是复核时在本机跑过的**自包含最小复现**：

```
d=$(mktemp -d) && cd "$d" && touch TarData_20260801_0000.bin UCM221_Target_20260914_0000.bin && python3 -c "import glob; print('prefix glob ->', sorted(glob.glob('TarData*.bin'))); print('*.bin ->', sorted(glob.glob('*.bin')))"
# 实测输出：
#   prefix glob -> ['TarData_20260801_0000.bin']            <- 静默漏掉 UCM221_Target_...，无报错
#   *.bin       -> ['TarData_20260801_0000.bin', 'UCM221_Target_20260914_0000.bin']
#   退出码 0（无异常）—— 即「前缀 glob 静默挡文件」这一条本机可当场复现
```


**审核给出的修改意见（要点）**：主张与证据要改三处（核心方向「不要写死厂商前缀、按内容/通用模式判格式」是对的，但被举例写歪了）： 1) 罪魁 glob 不是 `TarData*.bin`，而是 TCP 分支的 `SUC221_Target*.bin`。viewer_filtered 旧实现有两支：`TarData*.bin`→load_file_fast（裸 64 KiB/帧），`SUC221_Target*.bin`→load_tcp_frames（外层 6 B 帧头）。UCM221 抓包是被第二支的写死前缀挡住的。把「旧实现」引用与主张里的 `TarData*.bin` 换成 `SUC221_Target*.bin`，或明确写成「两支 glob 都写死了前缀」。 2) 删掉「同一格式」。TarData 与 *_Target_* 是两种框架（差 6 B 外层帧头），本机实测：`glob('*.bin')` 后交给 TarData 解析器 load_file_fast 硬解 UCM221 抓包，不报错但得 8,957 帧 / 8,290,692 个「点」（真值 50,005）。故「应扫 *.bin 并用帧头判格式」/「*.bin 是安全上界」只在「按帧头或前缀分派到正确解析器」时才成立——仓内现行 `dbf_scene.data_files()` 正是用 `TarData*.bin` / `*_Target_*

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 同一格式的 `UCM221_Target_*.bin` 会被静默挡在门外（主张节）—— 产物反证二者不是同一格式：TarData 为裸 65,536 B/帧，`*_Target_*` 为外层多 6 B 帧头的 TCP 抓包（viewer_filtered docstring + dbf_scene.data_files 注释）。
- `*.bin` 是安全上界（为什么节）—— 本机实测：`glob('*.bin')` 后交给 TarData 解析器 load_file_fast 硬解 UCM221 抓包，不报错但产出 8,957 帧 / 8,290,692 个「点」（真值 50,005），即静默垃圾；仓内 ce07a71 亦以「拿 TarData 解析器硬解抓包不报错，只是永远错位」记之。
- 失败模式是静默的：目录存在、命令退出码 0、统计数字变小或为 0（为什么节 / 失败信号节）—— 切片从未跑过修复前的代码；且旧 viewer_filtered.load_frames 在无匹配时 `raise FileNotFoundError`（响亮），静默产垃圾的其实是 dbf_scene 的单 `*.bin` glob。

**判定**：keep-with-fix · 拟 promote-playbook · 原证据快照风险=low · 复核时本机可复跑=true
