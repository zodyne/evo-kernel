---
id: bpm-adc-captures-in-tmp-keyed-by-note
type: lesson
status: candidate
scope: project:ant_design
domain: radar-sim
tags: [bpm, adc, capture, tmpdir, offline-data, verification]
triggers:
  - "核验 bpm_2t8r_sim 离线 ADC / 采集容器（IMRE、量化）相关结论，要找本次运行真正用的那份采集"
  - "同一台机器上累积了多份 bpm_adc_* 临时目录，不知道该读哪一份（失败信号）"
  - "仓库内随附的 bpm_2t8r_sim/captures/demo 与现场运行参数对不上"
  - "capture.json 里有 note 字段，不清楚它标的是哪个测试项"
  - "只读审查时要在仓库外定位被审项目跑出来的中间产物"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7d2-d6ba-777c-a410-327560871932
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [tmp-script-import-needs-explicit-pythonpath]
---

## 主张

`bpm_2t8r_sim` 的离线采集**不落在仓库里**：每次运行在 `/var/folders/<x>/T/` 下新建一个随机名目录 `bpm_adc_<rand>/`（内含 `adc_*.bin` + `capture.json`），`capture.json` 的 `note` 字段标明这份采集属于哪个测试项（如 `T14`），机器上会同时累积多份。核验采集/离线 ADC 相关结论时，要用「`note` 匹配 + 时间戳最新」的那一份，而不是仓库里随附的示例 `bpm_2t8r_sim/captures/demo`。

## 为什么

demo 与核验脚本每次调用采集都会新建一份随机目录，旧目录不清理，于是「目录里有一份 capture.json」并不代表它是本次运行产出的那份。仓库内的 `captures/demo`（`adc_0000.bin` + `capture.json`）是随仓库分发的示例数据，与本次运行的量化 spec/参数未必同源；只看它会把别的运行（别的 headroom/满量程/位数）的参数当成本次结论的证据。

定位方法（只读安全，不进仓库）：`ls -d /var/folders/*/*/T/bpm_adc_*` 逐个读 `capture.json` 的 `note` + 目录 mtime，挑 `note` 命中目标测试项且最新的一份。

## 反例 / 边界

- 若结论只依赖仓库内示例数据本身（例如审查 `captures/demo` 的文件格式），用仓库那份是对的；本条针对「核验本次运行产生的采集」。
- `note` 只标到测试项（T14）粒度，同一测试项内多次运行靠时间戳排序；若两次运行相差数秒（切片里 T14 的三份目录时间戳为 1789522026 / 1789522028 / 1789522055），按 mtime 取最大者。
- 这些目录在系统临时区，可能被系统清理：跨会话复现结论时应先把需要的那份拷到 /tmp 自定义目录（仍不写回被审仓库）。

## 证据

session 01a0a7d2 核验切片：

- 仓库内示例：`ls -R bpm_2t8r_sim/captures` → `demo bpm_2t8r_sim/captures/demo: adc_0000.bin capture.json`
- 运行产生的临时采集（按 note 归组）：`1789522055 bpm_adc_ja56bdip T14 / 1789522028 bpm_adc_bafigep3 T14 / 1789522026 bpm_adc_upz4jnk9 T14 / 1789521591 bpm_adc_abc54…`
- 核验脚本的取数被显式改成临时目录（`sed -i ''` 落在 `/tmp/vf/v8_fig8.py` 上）：
  `s|cap = A.open_capture("/Users/zodyne/Dev/ant_design/bpm_2t8r_sim/captures/demo")|cap = A.open_capture("/var/folders/_9/…|`
  改后随即读出本次采集的 spec：`spec8: AdcSpec(bits=16, full_scale=array(41.82471674), headroom_db=12.0, dc_offset=0.0, iq_gain_db=0.0, iq_phase_deg=0.0…`
