---
id: algommw-profile-single-config-source
type: fact
status: candidate
scope: project:algommw
domain: codebase-map
tags: [config, profile, adr-0007, load_profile]
triggers:
  - "改 algommw 的波形/通道/扫描配置，拿不准权威来源在哪"
  - "想在源码里找硬编码的配置值，怀疑存在副本"
  - "加新雷达 profile 或新配置项，需要知道载入器入口"
  - "发现某配置两处值不一致，要判断哪处是权威"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad51-f327-77c1-a593-51b9e8bdab94
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
---

algommw 的配置权威来源是 `profiles/<name>/profile.toml`（ADR 0007 起废弃硬编码副本），载入器为 `python/core_bind/config.py` 的 `load_profile()`。

为什么：改配置前要确定权威来源在哪，避免去源码里翻硬编码副本；ADR 0007 已明确废除副本，profile.toml 是唯一入口。

证据：会话 `cat profiles/sr61_tdm/profile.toml` 命中头注释原文："# SR61 TDM 默认 profile —— 项目唯一的配置来源(ADR 0007 起,不再有硬编码副本)。 # 载入器:python/core_bind/config.py 的 load_profile()。"
