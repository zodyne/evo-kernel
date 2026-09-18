---
id: nskeyedarchiver-value-is-bytes-second-plistlib-load
type: lesson
status: candidate
scope: global
domain: macos-apps
tags: [plist, plistlib, nskeyedarchiver, defaults, stdout]
triggers:
  - "defaults export 出的 plist 里某键用 plistlib 读出来是 bytes / <data>，不是 dict（失败信号）"
  - "读 NSKeyedArchiver 偏好键时 plistlib 返回 bytes，不知道下一步怎么解出 $archiver"
  - "想在只读/不落盘的前提下读 macOS 容器 app 的偏好，找 defaults export 到 stdout 的写法"
  - "defaults export <domain> /dev/stdout 拿不到有效 plist，想找免落盘的导出方式"
  - "解 NSKeyedArchiver 对象图时发现 $version/$archiver/$top 不在外层 plist 里，需要再解一层"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-52aa-73b1-bdd8-c2d3487bea9e
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [defaults-export-nskeyedarchiver-read-via-plistlib]
---
**主张**：`defaults export <domain> -`（目标写 `-`，不是 `/dev/stdout`）会把整份偏好 plist 打到 stdout，可以不落盘直接喂给 `python3`；但 `plistlib.loads()` 读出的 NSKeyedArchiver 键值往往是 **`bytes`（plist 里的 `<data>` 节点）**，不是对象图 —— 必须对这个 bytes **再 `plistlib.loads()` 一次**，才拿到 `{'$version': 100000, '$archiver': 'NSKeyedArchiver', '$top': …, '$objects': …}`。

**为什么**：NSKeyedArchiver 归档在 plist 里可以存成 dict，也可以序列化成 `<data>` 字节串；后者会让外层 load 只得到一个 bytes。只解一层就断言「读不出归档结构」，会误判工具链不可用（要再解一层才发现对象图就在 bytes 里）。

**证据**（会话 01a0b2ce 切片，命令↔结果）：
- `defaults export com.microsoft.rdc.macos - 2>&1 | head -c 300` → `<?xml version="1.0" encoding="UTF-8"?> <!DOCTYPE plist PUBLIC "-//Apple//…`（有效 XML plist 从 stdout 出来；对照同会话 `defaults export … /dev/stdout` 拿到的不是合法 plist）；
- `defaults export com.microsoft.rdc.macos - | python3 -c "…plistlib.loads(sys.stdin.buffer.read())…"` → `outer type: bytes`，接着 `plistlib.loads(v)` → `inner keys: ['$version', '$archiver', '$top', '$objects']`。

**边界/反例**：
- 归档也可能直接以 dict 存在外层 plist 里（那样一层 load 就是对象图）；解码前先 `isinstance(v, (bytes, bytearray))` 判断，两种形态都兼容，别硬编码两层。
- 拿到对象图 ≠ 读到业务数据：还要顺 `$top` 的 UID 在 `$objects` 里解析；本条只管「怎么把归档解出来」。
- `defaults export` 的免落盘写法是路径参数 `-`；写 `/dev/stdout` 在本机实测不产出合法 plist。
