---
id: tailscale-up-auth-link-timeout-expires
type: bullet
status: deprecated
scope: global
domain: networking
tags: [tailscale, auth, cli, headless]
triggers:
  - "tailscale 登录链接打开报 user is not authorized to view this auth request"
  - "tailscale up --timeout=N 生成的链接迟些打开失效"
  - "无浏览器/远程机器上跑 tailscale up 等用户授权"
created: 2026-08-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:capture-2026-08-11-07-13-39-290-010o
last_verified: 2026-08-12
superseded_by: skill:network-reachability-diagnosis
schema_version: 1
related: [tailscale-funnel-manual-enable-dns-delay]
---
`tailscale up --timeout=N` 生成的登录链接在超时后即失效，用户迟些打开会报误导性的 `user is not authorized to view this auth request`。

**为什么**：链接有效期绑在 CLI 的 timeout 上，超时后授权请求被作废，报错文本却指向"用户未授权"，容易误判为账号权限问题。
**修法**：`nohup tailscale up > /tmp/tsup.log 2>&1 &` 无限等待，数秒后 `cat /tmp/tsup.log` 取链接交给用户，授权完成前进程一直保持。
**边界**：该报错不代表 tailnet ACL 或用户权限有问题，先检查链接是否过期。
**证据**：2026-08-11 远程机器 tailscale 接入实操验证。
