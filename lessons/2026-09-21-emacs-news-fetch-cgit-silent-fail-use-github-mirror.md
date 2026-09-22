---
id: emacs-news-fetch-cgit-silent-fail-use-github-mirror
type: playbook
status: candidate
scope: global
domain: research-methodology
tags: [emacs, news, curl, savannah, github-mirror, fetch-verify]
triggers:
  - "研究 Emacs 某版本/分支有哪些变化，要拉 etc/NEWS 一手材料"
  - "curl 抓 git.savannah.gnu.org 的 cgit plain 链接后文件不存在（失败信号：ls/head 报 No such file or directory）"
  - "需要 Emacs 发布版 / master / feature 分支的 NEWS 做 grep 或版本对照"
  - "在 savannah 原站与 GitHub 镜像之间选抓取 URL"
  - "下载完马上 grep 关键词，想先把『抓取失败』与『NEWS 里真没写』分开"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bf4c-dbdb-75a1-a035-327aea85cb14
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [curl-o-code-000-no-output-file, curl-max-time-timeout-empty-looks-like-no-match, github-wrong-owner-path-silent-not-found]
---

# 抓 Emacs etc/NEWS 优先走 raw.githubusercontent.com/emacs-mirror，savannah cgit plain 会静默不落盘

**主张**：抓 Emacs 的一手版本材料（`etc/NEWS`）时，用 GitHub 镜像路径
`https://raw.githubusercontent.com/emacs-mirror/emacs/<ref>/etc/NEWS`；
`git.savannah.gnu.org` 的 cgit `plain` URL 本会话静默失败——`curl -sL -o` 跑完后输出文件根本不存在，
下游 `head` 直接报 `No such file or directory`，看起来像「NEWS 没有内容」。
抓完先 `ls`/`[ -s <file> ]` 确认落盘（或干脆不用 `-s` 看 curl 错误），再 grep；失败就切镜像 URL。

**为什么**：cgit plain 端点和 GitHub 镜像是两套可达性不同的路径，而 `curl -s` 会把连接/超时错误吞掉，
让「下载失败」伪装成「文件为空/不存在」；本会话同一步先用 cgit 失败、紧接着用镜像成功，
说明当时该抓取链路可切换而不必放弃任务。

**证据**（本会话切片，命令 ↔ 结果）：
- 失败：`cd /tmp && curl -sL --max-time 60 "https://git.savannah.gnu.org/cgit/emacs.git/plain/etc/NEWS?h=emacs-31.1" -o emacs31-NEWS.txt; ls -la emacs31-NEWS.t`
  → `✗ ls: emacs31-NEWS.txt: No such file or directory`、`head: emacs31-NEWS.txt: No such file or directory`、`Command exited with ...`。
- 成功：`cd /tmp && for ref in emacs-31.1 emacs-31; do echo "== $ref"; curl -sS -L --max-time 60 "https://raw.githubusercontent.com/emacs-mirror/emacs/$ref/etc..." ...`
  → `== emacs-31.1 OK     4274 NEWS31.txt 19:* Installation Changes in Emacs 31.1 21:** Unexec dumper removed. ...`；
  随后 master 的 NEWS 也成功拉到（`600 NEWSmaster.txt`，`* Changes in Emacs 32.1`）。

**边界 / 反例**：
- 本会话没有定位 cgit 失败的原因（超时 / 网络 / 端点行为都有可能），只证明「该时刻该 URL 不可用、镜像可用」，不能断言 savannah 永久不可用。
- `<ref>` 可以是 tag（`emacs-31.1`）也可以是分支（`feature/igc3`，另一条证据里以 jsDelivr 取得）；镜像路径是 `etc/NEWS`，不代表仓库其他路径同样。
- 若上游改动只存在于本地未推送提交，任何镜像都拿不到。
