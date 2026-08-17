---
id: tailscale-funnel-manual-enable-dns-delay
type: bullet
status: deprecated
scope: global
domain: networking
tags: [tailscale, funnel, dns, expose]
triggers:
  - "tailscale funnel 报错并给出 login.tailscale.com/f/funnel?node= 链接"
  - "首次用 tailscale funnel 把服务暴露到公网"
  - "funnel 开启后立刻 curl 返回 000"
created: 2026-08-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:capture-2026-08-11-07-13-39-325-oubb
last_verified: 2026-08-12
superseded_by: skill:network-reachability-diagnosis
schema_version: 1
related: [tailscale-serve-preserves-host-header, tailscale-up-auth-link-timeout-expires]
---
tailscale funnel 默认未启用，需浏览器手动开启；开启后公网 DNS 有数秒传播延迟，立刻 curl 可能 000。

**做法**：CLI 报错会给出 `https://login.tailscale.com/f/funnel?node=xxx` 链接，需在浏览器手动开启该节点的 funnel；开启后稍等重试即可，000 只是 DNS 记录尚未传播。
**边界**：000 不等于配置错误——CLI 已报错文本不含"DNS 传播"提示，容易误判为 funnel 没开成功而反复重开。
**证据**：2026-08-11 本机首次启用 funnel 暴露服务时复现，等待数秒后恢复。
