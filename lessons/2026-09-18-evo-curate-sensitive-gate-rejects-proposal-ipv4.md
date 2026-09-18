---
id: evo-curate-sensitive-gate-rejects-proposal-ipv4
type: lesson
status: candidate
scope: project:evo-kernel
domain: evo-kernel
tags: [evo-kernel, curate, sensitive-info, ipv4, redaction, ingest]
triggers:
  - "`evo curate --file <提案> --to playbook` 被拒，报 `疑似敏感信息（凭据/密钥/内网地址）→ 入库前脱敏（§4.3）`"
  - "提案正文里带 `localhost:端口`、内网 IP 或公共 DNS 地址（如 <dns>），入库卡住（失败信号）"
  - "批量入库一批提案前，想先知道哪些会被闸门拦下"
  - "把带具体探测目标的排障记录写进知识库提案"
  - "curate 报敏感信息但人眼看正文没有密钥（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae1e-1763-764c-a77e-51771fbd8c10
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [git-show-head-verify-committed-secret-redaction, mask-secrets-when-reading-config]
---

# `evo curate` 的敏感信息闸门会把提案里任何 IPv4 判为内网地址而拒收

**主张**：`evo curate` 入库前的敏感信息闸门对**任何 IPv4 字面量**报警并拒绝入库——回环 `localhost:18795` 和公共 DNS `<dns>` 一样中招（它不区分回环/公网/文档示例地址）。带具体地址的排障记录必须在入库前脱敏成占位（如 `<mcp-port>`、`<dns-server>`）；批量入库前先用同一类正则预扫 proposals 目录，把会被拦的挑出来处理。

**证据（2026-09-17 本机）**：
- 对整目录预扫（73 个提案逐个 `evo curate --file …` 干跑）时输出：`✗ 2026-09-14-retired-service-leaves-dangling-monitor-probe.md: ✗ 疑似敏感信息（凭据/密钥/内网地址）→ 入库前脱敏（§4.3）`。
- 用 `rg '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'` 定位，命中第 39 行的 `… curl -sS -m 8 -X POST http://localhost:18795/mcp -H …`。
- 脱敏改写该提案后重跑同一条 curate，得到 `✓ retired-service-leaves-dangling-monitor-probe → playbook/`。
- 同一闸门还拦下 `2026-09-11-ts-net-funnel-alidns-nxdomain-resolver-split.md`，其正文含 DNS 列表 `<dns> / <dns> / <dns>`；改写后复扫显示 `✓ 无 IPv4`。

**做法**：写提案时用占位符替代真实地址（`localhost` 也照样被拦）；批量入库前先跑 IPv4 预扫（`rg '\b\d{1,3}(\.\d{1,3}){3}\b' ops/proposals/`），有命中的先脱敏再 curate，避免"入库一半卡住"。

**边界**：闸门报的是"疑似"，正文里没有密钥也可能被拒——命中信息是 IP 字面量而非凭据本身；这类拒绝不修改文件，脱敏后重跑即可。
