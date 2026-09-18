---
id: defaults-export-nskeyedarchiver-read-via-plistlib
type: lesson
status: candidate
scope: global
domain: macos-apps
tags: [plutil, plistlib, nskeyedarchiver, defaults, rdp]
triggers:
  - "要读 macOS app 偏好里的历史设备/最近列表（如 Windows App 的 MSAppCenterPastDevices）"
  - "plutil -extract <key> raw 的产物再解析报 Unexpected character Y at line 1（失败信号）"
  - "defaults export 出的 plist 里某键是 NSKeyedArchiver 编码，常规工具读不出值"
  - "要取证某个容器 app 的偏好/历史记录，但不想改动机上任何东西"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b253-5635-7373-a922-2b2ad50891db
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

一句话主张：读 `defaults export` 出来的 plist 里 NSKeyedArchiver 类键（本会话是 Windows App 的 `MSAppCenterPastDevices`），不要走「`plutil -extract <key> raw -o <file>` 再解析那个文件」这条路——本会话两次都失败（产物是 1540 字节、无换行的 ASCII，解析报 `Unexpected character Y at line 1`）；直接用 `python3` + `plistlib.load(原 plist)` 读该键，能拿到 `{'$version': 100000, '$archiver': 'NSKeyedArchiver', ...}` 的对象图。

**为什么**：这类键的值是 NSKeyedArchiver 归档（对象图），不是普通标量；`plutil -extract ... raw` 抽出来的东西不保证还是合法 plist，第二步解析就断在那里，白折腾两轮。plistlib 会正常读出归档的 `$objects/$top` 结构，再由 UID 反查设备条目。

**证据**（会话 01a0b253 命令↔结果切片）：
- `defaults export com.microsoft.rdc.macos <plist> && plutil -extract MSAppCenterPastDevices raw -o - <plist>` → `/tmp/pastdevices.plist: Unexpected character Y at line 1`。
- 换成 `-o pd.bin` 再解析 → `pd.bin: ASCII text, with very long lines (1540), with no line terminators --- 解码 --- pd.bin: Unexpected character Y at l...`。
- `python3 <<'EOF' ... plistlib.load(open('<plist>','rb')) ... for k in ('MSAppCenterPastDevices'...)` → `--- MSAppCenterPastDevices --- {'$version': 100000, '$archiver': 'NSKeyedArchiver', '$top': {'root': UID(1)}, '$objects'...`（成功）。

**边界**：只验证了这一台机器上这一个键（`MSAppCenterPastDevices`）与这一条失败路径；其它键用 `plutil -extract ... raw` 可能是好的，别推广成「raw 一律不可用」。取到对象图不等于读到了业务数据——还要顺着 `$top/root` 的 UID 在 `$objects` 里解析，本会话只走到打印对象图这一步，没有解出设备清单；只想快速看历史设备也可以直接读 app 的 sqlite（见 `rdp-bookmark-sqlite-edit-quit-app-first`）。

两个可复用的写法（2026-09-18 补）：一是免落盘导出用 `defaults export <domain> -`（路径参数写 `-`，本机实测写 `/dev/stdout` 拿不到合法 plist），可直接管道喂给 `python3`；`plistlib` 读出的 NSKeyedArchiver 值**常常是 `bytes`（plist 里的 `<data>` 节点）而不是 dict**——归档既可以存成 dict 也可以序列化成字节串，后者必须对这个 bytes **再 `plistlib.loads()` 一次**才拿到 `{'$version': 100000, '$archiver': 'NSKeyedArchiver', '$top': …, '$objects': …}`。所以解码前先 `isinstance(v, (bytes, bytearray))` 判断，两种形态都兼容，别硬编码两层，也别因只解一层就断言「工具链读不出归档」。
