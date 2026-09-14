---
id: macos-tcc-protected-dir-empty-glob
type: lesson
status: candidate
scope: global
domain: macos
tags: [macos, tcc, permissions, glob, listdir, desktop, screencapture]
triggers:
  - "在 ~/Desktop / ~/Documents / ~/Downloads 下用 glob 或 os.listdir 找文件"
  - "glob 返回空列表但 os.path.exists(显式路径) 为 True（失败信号）"
  - "ls/python 报 Operation not permitted 而 sudo 也不管用"
  - "想从 /var/folders/.../TemporaryItems/NSIRD_screencaptureui_* 抓还没保存的截图"
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:1363c097-a1c9-4248-a903-814a33facb13
last_verified: 2026-08-13
superseded_by: null
schema_version: 1
related: [2026-07-27-zsh-unquoted-glob-arg-no-matches]
---
# macOS TCC 拒绝会让 glob/listdir 返回空或 Operation not permitted：空结果 ≠ 文件不存在

## 主张
在 macOS TCC 保护的目录（`~/Desktop`、`~/Documents`、`~/Downloads`、`/var/folders/**/TemporaryItems/NSIRD_screencaptureui_*`）
里做**枚举**（`glob.glob` / `os.listdir` / `ls`）可能返回**空列表**或 `Operation not permitted`，
而同一时刻 `os.path.exists(<显式完整路径>)` 仍为 `True`。
**结论：目录枚举为空不能推断文件不存在**；要么改用显式路径直接访问，要么按终端 App 的身份重置 TCC 授权，
不要顺着"文件没了"这条假线索继续排查。

## 为什么
TCC 是按调用进程（这里是终端模拟器）授权的，拒绝表现为目录级不可读；枚举 API 拿不到条目就返回空，
不抛异常也不提示原因，于是"文件消失"与"没有权限"这两种完全不同的状态在输出上长得一样。
更迷惑的是同一会话里早期枚举成功、后期突然为空（授权状态变化），会让人误以为文件被删/被移动。

## 证据（本会话命令对照）
- 会话早期 `ls -la ~/Desktop/*.png | head` 正常列出（`Screenshot 2026-08-01 at 10.45.28 AM.png` 等）。
- 会话后期同类枚举全空/被拒：
  - `ls -t ~/Desktop/*.png` → `(eval):1: no matches found: /Users/zodyne/Desktop/*.png`
  - `python3` `os.listdir('/Users/zodyne/Desktop')` → `err [Errno 1] Operation not permitted: '/Users/zodyne/Desktop'`
  - 多模式 glob → `*7.41* -> []`、`*2026-08-13* -> []`、`Screenshot 2026-08-13 at 7.41* -> []`，
    **紧接着同一脚本打印 `explicit exists: True`**（显式路径存在）。
- 截图临时目录同样不可读：`ls -la ".../TemporaryItems/NSIRD_screencaptureui_zFow2f/"` → `Operation not permitted`；
  `cp` 该目录下文件 → `Exit code 1`；python `os.listdir` → `PermissionError: [Errno 1] Operation not permitted`。

## 边界 / 反例
- 本会话只观测到现象，**未在本会话内执行过 TCC 重置动作**，因此"重置授权即恢复"这一步在此仅为推论方向，不是本条证据。
- zsh 的 `no matches found` 还有另一种成因（未加引号的裸通配符，见 related 条目）；先分清是 shell 展开报错还是权限导致的空枚举。
- `NSIRD_screencaptureui_*` 是截图保存前的临时落点，即便有权限也随时消失；不要把它当作可靠取图路径。

## 失败信号（未来命中即该想起本条）
- glob/listdir 空结果 + `os.path.exists` 为 True。
- 同一路径在会话前半段能列、后半段列不出来。
- `Operation not permitted`（注意不是 `Permission denied`）。
