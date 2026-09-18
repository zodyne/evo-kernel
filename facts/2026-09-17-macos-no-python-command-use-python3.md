---
id: macos-no-python-command-use-python3
type: fact
status: validated
scope: global
domain: macos
tags: [python, python3, homebrew, macos]
triggers:
  - "在本机写/跑 Python 脚本或探针，报 `python: command not found`"
  - "在 macOS 上跑 `python` 命令得到 exit 127 / 找不到命令"
  - "要给项目跑 Python 验证脚本，不确定该用 `python` 还是 `python3`"
  - "需要确认本机 python3 到底指向哪个解释器路径"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5ba6-7353-8a3d-42cce2d6a039
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [zshrc-alias-missing-in-noninteractive-bash]
---
本机（macOS）没有 `python` 命令，只有 `python3`：跑 Python 脚本/探针一律用 `python3`，且本机 `python3` 指向 Homebrew 的 python@3.14（`/opt/homebrew/opt/python@3.14/bin/python3`）。

为什么：审查 algommw 仓库时，第一个探针用 `python - <<'EOF'` 直接报 `python: command not found`（exit 127），随后 `which python3` 返回 `/opt/homebrew/opt/python@3.14/bin/python3`，改用 `python3` 后 `import PySide6, pyqtgraph, numpy` 打印 `ok`、探针正常产出结果（51 条 spec 行、afm761 路径 ok）。

边界：这是本机环境事实，不代表所有 macOS 都没有 `python`（部分机器装过 pyenv/python2 会有）。与 `zshrc-alias-missing-in-noninteractive-bash` 易混淆——那条讲「zshrc 里的别名在非交互 shell 失效」，本条讲「本机压根没有 `python` 可执行文件，只有 `python3`」，根因不同。
