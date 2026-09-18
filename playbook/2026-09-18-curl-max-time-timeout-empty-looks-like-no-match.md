---
id: curl-max-time-timeout-empty-looks-like-no-match
type: lesson
status: validated
scope: global
domain: shell-scripting
tags: [curl, timeout, silent-failure, pipeline, exit-code]
triggers:
  - "curl 拉源码/文档后接 rg/grep 得到空输出，想据此判断某参数或字段不存在"
  - "curl 报 Command exited with code 28（失败信号：--max-time 超时）"
  - "同一条 curl+rg 命令一会儿有命中一会儿什么都没有"
  - "管道里 curl 的失败被下游 rg/grep 吞掉，看不出是网络问题"
  - "跨版本核实某函数/环境变量语义，要拉 GitHub raw 源码来读"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e572-725c-a75a-f97ded032a7c
last_verified: 2026-09-18
superseded_by: null
related: [curl-o-code-000-no-output-file]
---
`curl -s --max-time N <url> | rg <pattern>` 的**空输出不能当成"没有匹配 / 该符号不存在"**：curl 超时（退出码 28）时 stdout 为空，与"文件里真没有这个符号"在管道下游完全同形；同一命令还会因网络抖动时灵时不灵。下"某版本源码里没有 X"这类存在性结论前，必须先让 curl 自身的失败可见。
**为什么（证据链）**：一次排查里，同一个 URL（neovim v0.12.4 的 `src/nvim/eval/funcs.c`，约 215 KB）出现三种结果：
1. 管道形态 `curl -s --max-time 20 <…/v0.12.4/src/nvim/eval/funcs.c> | rg -n -B4 -A 10 'clear_env' | head` → `(no output)`；
2. 同一 `--max-time 20` 在 `for ref in v0.12.4 release-0.12 master` 循环里却拉到了内容——v0.12.4 段输出含 `3388:dict_T *create_environment(const dictitem_T *job_env, const bool clear_env, …`，**证明该文件里确有 `clear_env`**，所以第 1 条的空输出 ≠ 无匹配；
3. 改成 `curl -s --max-time 25 <…> -o /tmp/nvim_funcs.c && awk …` → `✗ (no output)  Command exited with code 28`（`28` 即超时），失败这次才现形；把上限提到 45 后成功落盘 `-rw-r--r-- 215201` 字节。
**做法**：存在性核查先落盘（`-o <file>`）再看退出码/文件，然后 grep 落盘文件；管道形态里 curl 的退出码会被下游 `rg` 覆盖，失败静默成"空结果"。`--max-time` 偏小（本例 20–25s）不足以判"拉不到"，先重试或加大上限再下结论（同 URL/同时长一次成功一次失败）。
**边界**：与 related 的分工——`curl-o-code-000-no-output-file` 讲**连接失败**（http_code 000、`-o` 文件不落盘、下游报 No such file）；本条讲**超时**（exit 28）被管道吞掉、表现为"空结果"，两者症状与判据不同。
**证据**：上列三条命令↔结果均出自本会话切片（`### 命令 ↔ 结果` 段）。
