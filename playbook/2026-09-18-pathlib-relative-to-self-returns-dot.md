---
id: pathlib-relative-to-self-returns-dot
type: lesson
status: validated
scope: global
domain: python
tags: [pathlib, relative-to, single-file-mode, path-handling, silent-wrong-value]
triggers:
  - "写『相对 root 的路径』辅助函数，root 可能是目录也可能是单个文件"
  - "输出/CSV 里的相对路径列出现孤零零一个 .（失败信号）"
  - "Path.relative_to 抛 ValueError: ... is not in the subpath of ..."
  - "目录模式与单文件模式共用同一套扫描 / 输出代码"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a80b-0eeb-7719-ba82-31f86fbaeaa7
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# `Path.relative_to(自己)` 返回 `.` 而不是抛错：单文件模式下相对路径列静默变成 "."

**主张**：`Path.relative_to()` 对**同一个路径**不抛错，返回 `Path('.')`；只有目标不在 root 子路径下时才抛 `ValueError`。所以"path 相对 root"这类辅助函数在**单文件模式**（root 就是该文件）下会把相对路径写成 `"."`（落进 CSV 就是 `.` 列值）——既不是文件名也不是异常，静默错误。

**证据（会话 01a0a80b）**：
- 探针直接打印产物 CSV（原样）：
  `SPC865_OK_2021-12-07-04-10-22_0.bin,.,SPC865_OK_2021-12-07-04-10-22_0.bin,0,...`
  —— `path` 列的值就是 `.`（同一行还暴露了表头重复列 `file,path,file,...`，属另一处问题）。
- 该 bug 让"单帧 batch 产出的 path 列 == 文件名"这条断言连续失败两轮（先猜"root 是文件时 relative_to 抛 ValueError"、按此改了一版仍未通过），直到把产物流水原样打印出来才定位。
- 修法：先判等，再退回相对化——

  ```python
  if path == root:
      return path.name
  try:
      return str(path.relative_to(root))
  except ValueError:
      return str(path)
  ```

- 本机复验（Python 3.14，2026-09-18）：`Path('/tmp/a/b.bin').relative_to(它自己)` → `PosixPath('.')`；`relative_to(Path('/other'))` → `ValueError: '/tmp/a/b.bin' is not in the subpath of '/other'`。

**边界 / 反例**：判等要当心绝对/相对两种写法——`Path('x') == Path('/abs/x')` 为 False，而 `relative_to` 可能仍然成功；必要时先 `resolve()`（或用 `os.path.samefile`）再判。另外 `os.path.relpath(path, root)` 在 `path == root` 时同样返回 `"."`，不是替代品。

**失败信号（未来命中即该想起本条）**：输出里的相对路径列出现 `.`，或突然出现本不该有的绝对路径。
