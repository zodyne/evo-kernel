---
id: singbox-config-doc-validate-with-real-check
type: lesson
status: candidate
scope: global
domain: network
tags: [sing-box, config, validation, documentation, tun]
triggers:
  - "写完 sing-box 配置/部署文档，要确认里面的 JSON 真的能用而不是看起来对"
  - "给别人（或另一台机器）交付 sing-box 配置，发送前做最后校验"
  - "sing-box check 是唯一权威校验，肉眼/格式化通过不算数（失败信号：文档里的配置实际 check 不过）"
  - "把配置写进 markdown 文档交付，担心文档里的 JSON 与实际可用配置脱节"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0affb-58dd-73b1-bdd8-c2ca9d44ed64
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [singbox-legacy-dns-servers-deprecated-1-12]
---

sing-box 配置（尤其是写进部署文档交付的 JSON）必须用目标版本的真实 `sing-box check` 命令验证，肉眼检查/JSON 合法性都不算数——版本相关的 deprecation（如 1.12 DNS 新格式、default_domain_resolver）只有真实 check 才暴露。

为什么：给 Windows 机器写 sing-box TUN 部署方案时，配置先在 macOS 侧逐变体跑 `sing-box check`，过程中抓出两处肉眼完全看不出的版本兼容错误（legacy DNS 格式、缺 default_domain_resolver）；最后还从写好的 markdown 文档里抽出 JSON 块、改写路径后再次交给真实 check 复验，确认「文档里的文本本身」可用，而不是只有草稿可用。文档与可用配置之间隔着手工誊写，这一步防的就是誊写走样。

边界：本机 macOS 的 sing-box 1.13.19 与目标 Windows 版本对齐（同一版本号），check 通过不等于 Windows 运行时行为全同（服务安装、权限等运行时差异未被 check 覆盖）；`sing-box check` 只验语法与引用完整性，不验连通性。

证据：会话内三轮 `sing-box check`——基础版（mixed+SS2022）`✅ PASS`；TUN+DNS 变体两轮报错后修正为 `✅ PASS`；最终从 `~/Desktop/sing-box-Windows-部署方案.md` 抽 JSON 块复验，文档文本本身过 check。
