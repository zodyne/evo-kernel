---
id: uv-lock-outdated-check-uv-version-first
type: bullet
status: validated
scope: global
domain: python-tooling
tags: [uv, hermes, install, lock, pypi-mirror]
triggers:
  - "uv 报 uv.lock needs to be updated but --locked"
  - "install.sh / uv sync --locked 误判 lock 过期"
  - "pyproject.toml 用了 exclude-newer-package 的布尔写法"
  - "GitHub releases 被墙装不了/升不了 uv"
created: 2026-08-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:capture-2026-08-11-07-00-08-900-o1o8
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
---
uv 报 `uv.lock needs to be updated but --locked` 常是假信号——先怀疑 uv 版本与 pyproject 写法的匹配，而不是真去 `uv lock` 重生成。

**为什么**：hermes-agent 安装失败排查实例：真因是 hermes 托管的 uv（`~/.hermes/bin/uv` 0.11.28）过旧，解析不了 pyproject.toml 里 `exclude-newer-package` 的布尔写法，settings 解析静默失败后误判 lock 过期。
**修法**：GitHub releases 被墙时可用 PyPI 镜像装 uv 本体（`UV_INDEX_URL=aliyun uv tool install --force uv`），`cp -L` 真二进制覆盖 `~/.hermes/bin/uv`，新版 `uv lock --check` 通过后带 `UV_INDEX_URL` 重跑 install.sh，即走通 hash-verified tier。
**边界**：settings 解析静默失败是根因特征——报错文本指向 lock，实际 lock 文件无问题；盲目 `uv lock` 重生成会改变锁定版本，引入无关 diff。
**证据**：2026-08-11 本机 hermes 安装排障全程命令验证。
