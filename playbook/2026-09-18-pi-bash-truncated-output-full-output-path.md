---
id: pi-bash-truncated-output-full-output-path
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, bash-tool, output-truncation, temp-file, forensics]
triggers:
  - "pi 的 bash 工具结果末尾出现 [Showing lines a-b of N (50.0KB limit). Full output: <path>]"
  - "命令输出很大或含超长单行（压缩 JS / 单行 JSON），只回显了尾部一小段"
  - "要在结果里找某条命中，怀疑关键行已被截掉（失败信号：拿截断后的尾部当全部输出下结论）"
  - "想反查刚才那条命令的完整 stdout/stderr 说了什么"
  - "在 macOS 上找 pi 落在 /var/folders/... 下的命令输出文件"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e625-725c-a75a-f9838675a59a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# pi 的 bash 工具截断输出时会把完整输出落到临时文件并给出路径，直接读它而不是缩小命令重跑

## 主张

pi 的 bash 工具输出超限时**只回显尾部**，并在结果末尾附一行提示：
`[Showing lines a-b of N (50.0KB limit). Full output: <path>]`，其中 `<path>` 是**完整输出的落盘文件**。
需要完整内容（找被截掉的命中、核对全量结果、留证据）时直接读那个路径（或用 rg 在它上面搜）即可；
不要用 `head`、`--max-count`、缩小范围之类的办法重跑——那只是换一种截断，命中照样可能不在。

## 证据（本会话命令 ↔ 结果）

- 切片里的命令与返回：
  `$ P=/opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent; echo "=== tui-mode flag def ==="; rg -n 'tui-mode' $P/dist/*.js $P/dist/**/*.js 2>&1`
  → `=== help text ===  [Showing lines 16-16 of 16 (50.0KB limit). Full output: /var/folders/_9/mtxm3vm57vb0_686607pg8fm0000g…`
  （本次只回显了 16 行里的第 16 行，完整输出被写到 `/var/folders/...` 的临时文件。）
- 本机同版本实现核对（pi 0.85.1，与切片里 `~/.pi/agent/settings.json` 的 `lastChangelogVersion: "0.85.1"` 同版本）：
  - `dist/core/tools/truncate.js`：`DEFAULT_MAX_BYTES = 50 * 1024`，`formatSize()` 输出 `50.0KB`；
  - `dist/core/tools/bash.js` 的 `formatOutput()` 按 `truncatedBy` 分支追加提示，按字节截断那一支正是
    `[Showing lines ${startLine}-${endLine} of ${totalLines} (${formatSize(DEFAULT_MAX_BYTES)} limit). Full output: ${snapshot.fullOutputPath}]`，与切片里的字符串逐字吻合；
  - `dist/core/tools/output-accumulator.js`：`fullOutputPath = join(tmpdir(), '<prefix>-<id>.log')`（macOS 即 `/var/folders/...`）；
    `closeTempFile()` 只关写入流、**不 unlink 文件**，所以命令结束后该文件仍在。

## 边界 / 反例

- 只有真被截断时才有这个路径；输出没超限时结果里不会有 `Full output:`。
- 提示里带 `(50.0KB limit)` 说明是**按字节**截断（不是按行数），此时可见行号范围可能只有一两行——因为单行本身就超 50KB。
  别把"只显示了一行"误读成"命令没产出/没命中"。
- 文件在系统 tmpdir，重启或临时目录清理后会消失；要长期留证得自己复制出去。
- 本条只覆盖 pi 的 bash 工具（本机 0.85.1 核对）；其他 harness/工具的截断提示格式不同，不能套用这条的判读。

## 为什么值得记

被截断的尾部**天然像是"完整结论"**：命令退出码正常、输出有内容，只是前面的命中没了。
不认这个提示就会得出"rg 没搜到 / 该字段不存在"的假阴性结论——这是拿截断当证据的典型失败形态。
