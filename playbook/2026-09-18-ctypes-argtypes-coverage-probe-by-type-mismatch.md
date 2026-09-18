---
id: ctypes-argtypes-coverage-probe-by-type-mismatch
type: lesson
status: validated
scope: global
domain: ctypes-bridge
tags: [ctypes, argtypes, audit, fail-open, probe]
triggers:
  - "审查 ctypes/native 绑定层，要判定哪些符号的参数真受 argtypes 约束"
  - "绑定漏声明 argtypes 时错误指针被静默接受（fail-open），只读源码对不出保护面"
  - "探针调用报 ArgumentError: argument N: TypeError: expected X instance instead of Y，想知道这说明什么（失败信号）"
  - "给绑定层写启动自检 / 集中驱动表前，要枚举还没被类型声明覆盖的符号"
  - "怀疑某次 ctypes 调用传错类型却一点报错都没有，想确认是真的合法还是没被检查"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a705-5306-7353-8a3d-4304b0cbfa61
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [ctypes-argtypes-table-drift-silent-cint-restype]
---

# 用「故意传错类型」的调用探针判定 ctypes 符号是否真受 argtypes 约束

**主张**：一个 ctypes 符号有没有被 `argtypes` 保护，可以用**运行时探针**问出来，不必只读绑定源码：
故意把实参类型传错（或把两个不同类型的位置对调），调用一次，看是否在调用点抛
`ArgumentError: argument N: TypeError: expected <CType> instance instead of ...`。
- **抛了** → 该位置的 argtypes 已声明，ctypes 在边界做类型转换/校验；
- **没抛、照常返回或把实参当裸指针传下去** → 该符号的参数没有类型约束，属于 **fail-open**：
  传错类型的指针不会被拦，错误只会推迟到 C 侧以段错误/静默错值的形式显现。

**为什么**：`argtypes` 是「声明了才检查」的机制，缺省不检查也**不报错**；而绑定层里
声明的覆盖面常常是手工维护、参差不齐的（`beam_is_dbf.py:124` 这类零散声明与
`native.py` 混在一起），读源码只能看出「写了什么」，看不出「漏了什么在运行时是否真的无害」。
类型探针给的是可复现的判决：错误类型在调用点的报错形态，就是该符号受保护的直接证据；反之，
静默通过就是保护缺口的直接证据。

**做法**：
1. 探针里逐符号取 `getattr(lib, name)`，先打印 `.argtypes` / `.restype`（缺省 `restype` 是
   `c_int`，见 related 条目）；
2. 对每个符号用**错类型实参**（或对调两个已知不同类型的位置）调一次，`try/except` 捕获
   `ctypes.ArgumentError`，把「符号 → 报错/静默」列成清单；
3. 清单即「哪些符号漏保护」的审计面，可直接喂给集中驱动表 / 启动自检的补全工作。

**边界**：
- 报错消息必须区分形态：`argument N: TypeError: expected X instance instead of Y` 才是类型
  检查；**实参个数不对**也算 `ArgumentError`，别把缺参报错误读成「已受保护」。
- `c_void_p` / `c_char_p` 这类「什么指针都能装」的声明本身拦不住语义错误：这类位置要保护
  得靠更窄的 `LP_*` 结构体类型或调用方断言。
- 本条只给**探测手段**；漏保护的成因与「集中驱动表 + 启动自检」的修法见 related 条目。
- 探针要调用被测符号（会给 C 侧传坏指针），只在可崩的独立进程里跑，别与主流程同进程。

**证据（切片 01a0a705）**：`cd /tmp && python3 -c "...sys.path.insert(0,'…/algommw/python')…"`
逐符号探针的输出片段：`1) eChainDoa swapped -> ArgumentError argument 2: TypeError: expected
LP_Cube instance instead of pointer to …` —— 对调实参后该符号在调用点被 ctypes 拦下。
同一会话（对抗式验证同一仓库的「绑定漏声明 argtypes ⇒ fail-open」发现）的复核结论为
`refuted=false`、confidence high、fail-open 主张可复现，即：未声明的那几个符号
（`vChainTrackDefaults` 等）传指针不报错。两条臂合起来支持上面的判读规则。
