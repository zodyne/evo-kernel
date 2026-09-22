---
id: ti-ccs-cproject-build-config-extract
type: lesson
status: validated
scope: global
domain: embedded
tags: [ti, ccs, cproject, mmwave, iwr6843, build-config, python]
triggers:
  - "拿到不熟悉的 TI Code Composer Studio (CCS) / mmWave 工程，要弄清它 include 了哪些 SDK 路径、链了哪些库"
  - "源码里 #include 的头文件不知道来自哪个 SDK/工程目录，要反查编译配置"
  - "工程根目录有 .cproject，要把 include / 库 / 器件配置批量列出来而不是在 XML 里逐项肉眼看"
  - "分析 IWR6843 这类 MSS+DSS 双核 CCS 工程，要核对两个核的 include/库差异"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bf05-a4c7-7043-b23e-f82967643bc9
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [2026-09-16-tiarmclang-subtarget-cortex-r5-not-r5f]
---

# CCS 工程的 include / 库 / 器件配置在 `.cproject` 里：用 Python 扫 `listOptionValue` 一次提全

**主张**：TI Code Composer Studio 工程的编译配置（`-I` 级 include 路径、链的库、器件配置）存放在工程根目录的 `.cproject`（XML）中，以 `listOptionValue` 项序列化；用 Python（`re`）读入 `.cproject` 扫这些项，一条命令就能把全部路径列出来，输出是 CCS 变量形式（`${PROJECT_ROOT}` / `${CG_TOOL_ROOT}` / `${COM_TI_MMWAVE_SDK_INSTALL_DIR}`）而非绝对路径。

**证据**（本会话切片，命令 ↔ 结果）：

1. `cd project/high_accuracy_68xx_mss && python3 - <<'EOF' … open('.cproject', encoding='utf-8', errors='replace') …` → 输出 include 路径 `${PROJECT_ROOT}/utils ${CG_TOOL_ROOT}/include ${COM_TI_MMWAVE_SDK_INSTALL_DIR}/packages/ti/utils/cli/lib`。
2. 同法扫 `project/high_accuracy_68xx_dss/.cproject` → `${PROJECT_ROOT}/utils ${CG_TOOL_ROOT}/include ${COM_TI_MMWAVE_SDK_INSTALL_DIR}/packages/ti/utils/mathutils/lib libmathut…`（**两核库集不同**：MSS 有 `utils/cli/lib`、mathutils 出现 0 次；DSS 反之）。
3. 第三次扫 MSS `.cproject`，脚本自身带段标 `---- listOptionValue entries containing path-ish text ----`；同一次提取还带出器件配置 `DEVICE_CONFIGURATION_ID=Cortex R.IWR6843 DEVICE_CORE_ID= …`。
4. 旁证：`Debug/` 下的 `sources.mk` / `objects.mk` / `subdir_vars.mk` 结果的第 2 行是 `# Automatically-generated file. Do not edit!`（第 1 行是 `####…` 分隔行） —— Debug 侧是工具生成的派生物，配置来源不在那里。

**为什么**：源码里只有 `#include` 名字，没有 `-I` / `-l` 信息；CCS 把 build configuration 的 include / 库 / 器件设置写进 `.cproject`，所以「这个头文件从哪来、要不要链某个库」只能从这里反查。

**边界 / 反例**：
- 切片只证明能**提取出**这些项，未验证 `${PROJECT_ROOT}` / `${CG_TOOL_ROOT}` / `${COM_TI_MMWAVE_SDK_INSTALL_DIR}` 如何展开成本机绝对路径；要在本机复现构建仍需 CCS 或对应 SDK 安装。
- 同一仓库 MSS / DSS 两个 `.cproject` 配置并不相同（DSS 多 mathutils），核对 include/库时两个核必须各扫一遍，只扫一个会漏。
- 本次为纯只读分析（切片「写/改文件」段为空），未与 CCS GUI 导出的配置对账，也未验证按此配置能否构建成功。

**证据链接**：`evo slice --session /Users/zodyne/.pi/agent/sessions/--Users-zodyne-Dev-wtr10-wtr10_v3.00--/2026-09-20T13-33-33-256Z_01a0bf05-a4c7-7043-b23e-f82967643bc9.jsonl --ids 01a0bf05-a4c7-7043-b23e-f82967643bc9`，命令 11–13（.cproject 提取）与命令 5、9（Debug/*.mk）。

## 2026-09-22 独立复核：本机复跑通过，建议**升格进注入集**

复核在本机重跑了提取（真实 `.cproject` 上）：

```
$ cd <proj>/high_accuracy_68xx_mss && python3 -c "import re;s=open('.cproject',encoding='utf-8',errors='replace').read();v=re.findall(r'<listOptionValue[^>]*value=\"([^\"]*)\"',s);print('total',len(v));print([x for x in v if '${' in x][:3]);print([x for x in v if 'DEVICE_' in x])"
total 152
['PRODUCT_MACRO_IMPORTS={...}', '${COM_TI_BIOS_INCLUDE_PATH}', '${COM_TI_MMWAVE_SDK_INCLUDE_PATH}']
['DEVICE_CONFIGURATION_ID=Cortex R.IWR6843', 'DEVICE_CORE_ID=', 'DEVICE_ENDIANNESS=little', ...]
```

主张成立、本机可复跑、与别仓无关 ⇒ **够格从 lessons 升进 playbook**（待升格）。
原证据 1–3 的 python 命令在切片中被截断（不能照抄），上表是可重跑的那份。

