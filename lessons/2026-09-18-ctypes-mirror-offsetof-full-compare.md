---
id: ctypes-mirror-offsetof-full-compare
type: lesson
status: candidate
scope: global
domain: ffi-verification
tags: [ctypes, offsetof, struct-layout, mirror-drift, c-compile]
triggers:
  - "要证明 Python ctypes 镜像与 C 头文件逐字段零漂移，而不是抽样几个字段"
  - "手写/生成 ctypes.Structure 后担心字段偏移或 padding 与 C 侧不一致"
  - "想写出『N 个字段全部比对，0 mismatch』这种可复现的镜像一致性结论"
  - "编译 offsetof 探针报 fatal error: 'core/...h' file not found（失败信号：漏了 -I<include 根>）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5bdd-7353-8a3d-42cfac95e3a6
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [mmw-cpp17-port-golden-equivalence]
---

# 验 ctypes 镜像零漂移：由 Python 侧生成 C 的 offsetof 探针，编译后全字段比对

## 主张
判断 ctypes 镜像是否与 C 头文件字面一致，**别抽样几个字段、也别手推 padding**：从 ctypes 侧反射出字段清单，生成一份 C 程序（每个字段打印 `Struct|field|offsetof(Struct, field)`），本机 `cc -I<include 根>` 编译运行，再与 Python 侧 `getattr(cls, field).offset` 逐字段比对。结论形式是「N 个字段全部比对；mismatches: 0」——可复现、可直接写进结论，而不是"看起来对"。

## 证据（本次只读审查实录）
- Python 侧枚举：`/tmp/gen_offsets.py` → `282 fields`（反射出的待检字段清单）。
- 第一版生成器（`/tmp/gen2.py`，手工 f-string 拼 `printf` 行）报 `Traceback ... line 24 ... lines = "\n".join(f'    printf("%s|%s`；改成先 `json` 序列化字段清单再拼源码后生成通过。生成器本身别用易错的字符串拼接。
- `cc -o /tmp/offsets /tmp/offsets.c` → `fatal error: 'core/chain/chain.h' file not found`；加 `-Icore/include` 后编译通过（头文件按 `core/...` 相对 include 根书写），运行输出 `261` 行 `Struct|field|offset`。
- `/tmp/cmp.py` 比对 → `compared 261 field offsets; mismatches: 0`。
- 该结果被写进最终审查结论："ctypes 镜像本身经 261 个字段偏移全量比对零漂移，这一步不是推断而是实测"。

## 边界 / 注意
- 编译参数必须带 include 根（本次 `-Icore/include`）；报的错是"头文件找不到"，容易被误读成探针写错。
- **两侧字段数要先对齐再看结论**：本次 Python 侧枚举 282、C 侧实际参与比对 261。差额从哪来必须解释清楚，否则 `mismatches: 0` 可能只是比对集合缩水，而不是真的零漂移。
- 探针程序放 `/tmp`，不改被审仓库，适合只读审查。
- 这条闸门只覆盖布局（offset/size）；字段类型、函数签名漂移要用别的闸门（如 argtypes/restype 自检）另查。
