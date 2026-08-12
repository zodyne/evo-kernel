---
id: load-api-key-from-zshrc-subshell
type: lesson
status: candidate
scope: global
domain: shell-env
tags: [api-key, zshrc, env, subshell]
triggers:
  - "harness/脚本起的非交互 shell 里 echo $SOME_API_KEY 为空，但交互终端里有"
  - "项目目录找不到 .env，API key 不知配在哪"
  - "要在脚本里临时导出本机的 MOONSHOT_API_KEY / 其他 API key 跑一次测试"
  - "env | grep 不到 key，就断言 key 没配置（失败信号：误判）"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:06d00000-c5a0-4247-9e4a-de361d19d25e
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
---

harness 起的非交互 shell **不会 source `~/.zshrc`**，`env | grep KEY` 为空不代表 key 没配置——本机 API key 常写在 `~/.zshrc` 里。取法：`export KEY=$(zsh -c 'source ~/.zshrc >/dev/null 2>&1; echo $KEY')`，用 zsh 子进程 source 后回显。

硬证据（2026-07-30，排查 MOONSHOT_API_KEY）：`env | grep -i MOONSHOT` 空、`find ~/graph-lab -iname ".env*"` 空；`grep -rl MOONSHOT_API_KEY` 命中 `~/.zshrc`；上述子shell命令取到 key（输出 "key loaded, length: 72"），后续 API 实测脚本正常调通。

定位顺序建议：先 `env | grep`，再 `find <项目> -iname ".env*"`，再 `grep -rl <KEY名> ~/.zshrc ~/.claude.json 等配置位`，逐级排查而不是查一处空就下结论。

注意：取到的 key 只存在于该命令的 export，别写进文件或落盘日志。
