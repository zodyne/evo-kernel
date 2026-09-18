---
id: algommw-xcalib-per-virtual-antenna-complex-calib
type: fact
status: candidate
scope: project:algommw
domain: radar-calibration
tags: [algommw, xCalib, 通道标定, 虚拟天线, SR61, rxChPhaseComp]
triggers:
  - "读/移植 algommw 的通道标定，想知道 xCalib 是标量相位还是逐虚拟天线复数（增益+相位）"
  - "SR61 AOP 的 ±1 交替相位补偿（rxChPhaseComp）与 algommw 的 xCalib 是不是同一套标定"
  - "想拿 ±1 交替当通道标定的通用形式套到别的阵型/波形上（失败信号：漏掉复增益与逐虚拟天线这一维）"
  - "在 core/include/core/types/array.h 附近找 xCalib 的语义说明"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a704-a605-7353-8a3d-42f97b9a411d
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
---

# algommw 的 xCalib 是逐虚拟天线的复数标定（增益+相位）；SR61 AOP 的 ±1 交替只是它的特例

**主张**：algommw 的通道标定 `xCalib` 的语义是**每虚拟天线一个复数**——同一个值上同时带增益与相位；SR61 AOP 那种 ±1 交替的相位补偿（`rxChPhaseComp`）是这套标定的**特例**，不是它的通用形式。

**为什么**：既然 `xCalib` 是"复数标定（增益+相位）"而 ±1 交替被源码自己标注为"其特例"，标定的自由度就远大于二值相位翻转；把 AOP 的 ±1 交替当成通道标定的完整形式，等于把特例当通则。（此推论直接来自该行注释的两个限定语，未超出注释本身。）

**证据（切片内命令 + 结果）**：

- `grep -rn "xCalib" core/ --include=*.c --include=*.h` → `core/include/core/types/array.h:18: * xCalib:每虚拟天线复数标定(增益+相位)。SR61 AOP 的 ±1 交替(rxChPhaseComp)是其特例`

**边界 / 反例**：

- 本条只来自 `array.h:18` 这一行注释（切片内 grep 命中）；切片**没有**展开 `xCalib` 的结构体定义、维度、标定文件格式，也没有展开它在哪一层被施加——不要据本条推断这些。
- "在哪施加"是另一条口径（切片内另有 `core/include/core/types/radar.h:57` 的"标定在 DOA 消费侧施加"与同批提案 `algommw-snapcube-uncalibrated-consumer-side-calib`），与本条的"标定是什么"是两个问题，别混。
- 切片只给出 `core/` 头的这一处定义；其他仓库（如 SPC865/SUC221）是否有同名同义字段，切片未涉及。
