---
id: algommw-nan-passes-status-checks
type: lesson
status: candidate
scope: global
domain: verification
tags: [nan, return-code, dsp, algommw, edge-case]
triggers:
  - "跑 algommw 的 range/doppler 链路，eRangeProcess / eChainRange / eChainDoppler 都返回 0，但 cube/rdmap 元素是 NaN（失败信号）"
  - "审计/核验 DSP 链路时想只用 eStatus/eRet 判断每一级是否正常"
  - "给含除法的数值函数（窗函数、归一化）传退化入参后，下游矩阵出现 NaN 却没有任何错误码"
  - "要判断 NaN 是否穿透了整条处理链（range → doppler → CFAR），需要逐级取证"
  - "对账只读了返回码没读输出值，怀疑漏掉非有限值（isnan/inf）检查"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a704-a5d0-7353-8a3d-42f6d72a337b
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [validate-ok-but-derived-index-overflow-silent, algommw-window-func-n1-nan, built-static-lib-standalone-probe]
---

# 主张

algommw 链路里中间量含 NaN 时，每一级仍返回成功码（本库惯例 0 = eOk）：探针显示 `eRangeInit = 0`、`eRangeProcess = 0`、`eChainInit = 0`、`eChainRange = 0`、`eChainDoppler = 0`，而 `cube[0][0][0]` 与 `rdmap[0][0]` 的元素是 NaN。核验这类处理链不能只看返回码，必须对每级输出做 isnan/有限性检查。

# 证据（切片命令 ↔ 结果）

- 探针链接目标存在：`$ cd /Users/zodyne/Dev/algommw && ls build/core/libcore.a 2>/dev/null; …` ↳ `build/core/libcore.a …`
- range 链路探针（/tmp/rprobe.c，`#include "core/dpu/range/range.h"`，链接已构建静态库）↳
  `waveform validate = 0 eRangeInit = 0 eRangeProcess = 0, cube[0][0][0] re=nan im=nan isnan(re)=1`
- chain 链路探针（/tmp/cprobe.c，`#include "core/chain/chain.h"`）↳
  `eChainInit = 0 eChainRange = 0   cube[0][0][0] re=nan isnan=1 eChainDoppler = 0   rdmap[0][0] = nan isnan=1 eChainCfar =`
  （切片在 `eChainCfar =` 处截断，CFAR 一级的状态与输出未见，本条目不对它下结论）
- 会话前提为只读审查（切片「写/改文件」段为空，探针只落在 /tmp），基线自称 `ctest 24/24 全绿`——全绿基线没有拦住这几处 NaN。

# 反例 / 边界

- 切片只保留探针输出的前缀，`rprobe.c` / `cprobe.c` 的 heredoc 正文被截断，未保留探针的具体入参配置；因此本条只主张「成功码 ≠ 输出有效」，不主张 NaN 由哪组入参、哪一行代码造成。
- 与 `validate-ok-but-derived-index-overflow-silent` 同一返回码家族但坑不同：那条是派生索引回绕、对账要读 fold 表内容；本条是非有限值穿透、对账要在每级输出上做 isnan 检查。
- 与 `algommw-window-func-n1-nan` 互补：那条讲 NaN 从哪来（窗长 N=1 除零），本条讲 NaN 产出后不会被任何状态码拦住。
- 探针用 `isnan()` 打印，不依赖 ctest 用例：只跑测试套件拿不到这条证据（测试套件对退化入参无覆盖）。
