---
id: searxng-google-cse-risk-control-disable
type: lesson
status: candidate
scope: global
domain: self-hosted
tags: [searxng, docker, google-cse, risk-control, engines, settings-yml]
triggers:
  - "SearXNG 日志刷 ERROR:searx.engines.google cse，或搜索被 Google 风控/reCAPTCHA 拦（失败信号）"
  - "排查『web 搜索/研究为什么总触发 Google 验证』类任务"
  - "要在 use_default_settings: true 的 SearXNG 容器里关掉某个默认开启的引擎"
  - "改完 /etc/searxng/settings.yml 不确定覆盖段生不生效，要验证引擎 enabled 状态"
  - "docker logs 里某引擎错误按小时稳定复现，要找是哪个引擎在持续打 Google"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7d3-c853-744a-939b-f6e91f2f995b
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# SearXNG 的 `google cse` 会随每个查询打 Google，必须在 settings.yml 覆盖段里显式 disabled 才能清零

**主张**：本机 SearXNG 容器（`use_default_settings: true`）里 `google cse` 是默认启用的引擎；在出口 IP 已被 Google 风控标记的环境下，它会对**每次查询**发起一次带 CSE token 的 Google 请求并稳定报错（日志形态 `ERROR:searx.engines.google cse`，按小时成片），持续把风险打在同一个 IP 上。修法是在 `/etc/searxng/settings.yml` 追加 `engines:` 覆盖段 + `- name: google cse` + `disabled: true`（**不要**去改镜像内 `/usr/local/searxng/searx/settings.yml`），再 `docker restart searxng`；之后该错误计数归零。

**为什么**：`use_default_settings: true` 时容器里的 settings.yml 只是**增量覆盖**，镜像默认引擎表仍全量生效——"我改过配置了"不等于"这个引擎关了"。而 google cse 走 Google 自家 element/v1 服务，风控按出口 IP 记账，每查一次就多打一次，属于典型的"配置里没写、日志里才看得见"的隐性流量。

**证据（本会话命令 ↔ 结果）**：
- 默认引擎表里确有它：`docker exec searxng grep -n -B2 -A6 -i 'google cse' /usr/local/searxng/searx/settings.yml` → `1234-    inactive: true` / `1236:  - name: google cse` / `1237-    engine: g…`
- 按小时统计（容器启动以来）：`docker logs -t searxng --since 2026-09-15T11:44:00Z 2>&1 | rg 'ERROR:searx.engines.google cse' | rg -o '^[0-9T-]+[0-9]{2}'` → `2 2026-09-15T11 / 18 T12 / 14 T13 / 3 T14 / 1 T…`（持续在打，非一次性）
- 覆盖段生效：向 `/etc/searxng/settings.yml` 追加（带注释 `# 2026-09-16: 禁用 Google CSE。实测：cse.google…`）后 `docker restart searxng`，`curl -s 'http://localhost:8888/config?format=json'` → `google cse enabled = [False]`，general 类别启用引擎为 `['360search','bing','sogou','yandex','zapmeta','brave']`
- 效果验证：`docker logs -t searxng --since 2026-09-16T01:42:00Z 2>&1 | rg -c 'ERROR:searx.engines.google cse'` → `0 —— 未再触发`
- 同轮排查的落库提交信息：`fix: 禁用 google cse（每个查询都触发 Google 风控）+ 扩展钉死引擎 + 门禁加判据`

**反例/边界**：
- 切片只证明「该引擎错误按小时稳定复现 + 禁用后归零」，**没有**证明用户看到的 Google `unusual traffic` / reCAPTCHA 页面全部由它造成（那个因果是 docs/design.md 里的推断，IP 被标记这一点已由用户确认）。引用时别把因果说满。
- 禁用 google cse 不等于"搜索链路干净了"：同一时间窗仍有 `2 ERROR:searx.engines.brave`、`1 ERROR:searx.engines…` 等其他引擎错误。
- 覆盖段里 yandex 等写 `disabled: false` 是显式放行，别顺手删。

**失败信号（未来命中即该想起本条）**：`docker logs` 里 `ERROR:searx.engines.google cse` 按小时成片出现；或改完 settings.yml 没重启容器就断言"已经关掉了"。
