---
id: zz-base-image
type: lesson
status: validated
scope: global
domain: deploy
tags: [docker, image, deploy]
triggers:
  - 打包镜像时基础镜像怎么选
  - 选择 docker base image
created: 2026-03-01
evidence: {helpful: 2, harmful: 0}
verified_by: command
source: fixture
last_verified: 2026-03-01
superseded_by: null
schema_version: 1
---
# 基础镜像选 slim 而非 alpine
alpine 的 musl 会让 native 模块反复出问题。
