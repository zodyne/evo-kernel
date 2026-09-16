---
id: macos-screenshot-narrow-nbsp-filename
type: lesson
status: validated
scope: global
domain: macos
tags: [macos, screenshot, filename, unicode, u202f, glob, python]
triggers:
  - "要读用户放在 ~/Desktop 的 macOS 截图（Screenshot 2026-.. at ..PM.png）"
  - "cp/mv 一个肉眼确认存在的截图却报 No such file or directory（失败信号）"
  - "把界面上看到的文件名原样抄进命令、shell 说文件不存在"
  - "写脚本按文件名匹配 macOS 自动生成的截图/录屏文件"
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:1363c097-a1c9-4248-a903-814a33facb13
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [macos-bsd-cat-no-dash-a]
---
# macOS 截图文件名里"时间前的那个空格"是 U+202F，不是普通空格

## 主张
macOS 自动命名的截图形如 `Screenshot 2026-08-12 at 8.00.41 PM.png`，其中 **`41` 与 `PM` 之间的分隔符是
U+202F NARROW NO-BREAK SPACE（窄不换行空格）**，不是 ASCII 空格。把界面/`ls` 输出里看到的名字原样抄进命令，
`cp` 会报 `No such file or directory`——文件确实在。**正确做法：不要手拼文件名，用 `glob` 通配（
`glob.glob('/Users/.../Screenshot 2026-08-12*')`）拿到真名再 `shutil.copy`**，必要时 `print(repr(name))` 看清转义。

## 为什么
终端和编辑器把 U+202F 显示成普通空格，肉眼与复制粘贴都区分不出（复制往往还会被规范化成 ASCII 空格）。
于是"路径写得一模一样却打不开"，很容易被误判为权限问题或路径拼错，浪费多轮排查。

## 证据（本会话命令对照）
- `cp "/Users/zodyne/Desktop/Screenshot 2026-08-12 at 8.00.41 PM.png" /tmp/hermes_screenshot1.png`
  → `Exit code 1 / cp: ...: No such file or directory`（用 ASCII 空格手拼）。
- `python3 -c "import glob,os; [print(repr(os.path.basename(p))) for p in glob.glob('/Users/zodyne/Desktop/Screenshot 2026-08-12*')]"`
  → `'Screenshot 2026-08-12 at 2.00.35\u202fPM.png'`、`'Screenshot 2026-08-12 at 5.45.09\u202fPM.png'` —— 真名里是 `\u202f`。
- 后续改用 glob 定位再拷贝即成功：`p = glob.glob('/Users/zodyne/Desktop/*10.38.47*')` →
  `['/Users/zodyne/Desktop/Screenshot 2026-08-12 at 10.38.47\u202fPM.png']`，`shutil.copy(p[0], '/tmp/...')` 通过。

## 边界 / 反例
- `find ~/Desktop -maxdepth 1 -name "Screenshot*8.0*.png"` 这类**由 find 自己做匹配**的写法能命中，
  因为通配符跨过了那个字符；坑只出现在"完整写出文件名"时。
- 本次未验证 `2026-08-12` 中的连字符/其他字段是否也含特殊字符；只确认了时间与 AM/PM 之间是 U+202F。
- 该字符随 macOS 版本/区域设置而来，不能假设所有机器一致——所以用通配符匹配比硬编码字符更稳。

## 失败信号（未来命中即该想起本条）
- `ls` 能看到、`cp/open/cat` 说不存在，且文件名里带 `AM`/`PM`。
- glob 出来的名字 `repr()` 里出现 `\u202f` / `\xa0` 这类不可见空白。
- 2026-09-16 独立复验（交互模型，非原会话）：建 U+202F 文件名：ASCII 空格名 `cp` → `No such file or directory`；`glob('Screenshot 2026-08-12*')` 取真名后拷贝成功
