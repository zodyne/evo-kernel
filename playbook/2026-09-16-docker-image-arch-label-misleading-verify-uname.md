---
id: 2026-09-16-docker-image-arch-label-misleading-verify-uname
type: lesson
status: validated
scope: global
domain: docker
tags: [docker, cross-compile, rosetta, architecture]
triggers:
  - "docker image inspect 报的架构和容器里实际跑出来的不一致"
  - "在 Apple Silicon 上跑交叉编译容器，拿不准它到底是 arm64 还是 x86_64"
  - "交叉编译产物 readelf/file 报的架构和预期不符"
  - "镜像清单/标签说 arm64，但容器内 uname -m 是 x86_64（失败信号）"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7f9-4ced-73b3-8cfc-3829cc92108c
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: []
---

镜像清单/标签声明的架构可能与容器内真实架构不符。本会话 `embedded-platform:unified` 镜像在 `docker image inspect` 清单里报 arm64，但 `docker run --rm --entrypoint bash embedded-platform:unified -c 'uname -m'` 实测是 x86_64（Ubuntu 20.04.6 LTS + x86_64 版 Linaro/TI 交叉编译器，靠 Docker Desktop 的 Rosetta 模拟在 Apple Silicon 上跑）。

为什么：Docker Desktop 对 x86_64 镜像做 Rosetta 透明模拟，「容器能跑」不等于「原生 arm64」；清单/标签字段（.Os/.Architecture）与 README/Dockerfile 声称值也可能互相矛盾（本会话 README 写 amd64、清单报 arm64、容器实为 x86_64，三处不一致）。

边界/反例：判断「某个交叉编译工具链产物是什么架构」时，唯一硬证据是容器内 `uname -m` + 编译产物 `readelf -h`/`file`，而不是镜像标签、README 或 `docker images` 列表。凡是要确认产物能否在目标板跑，都必须真编译一个 .o 再 readelf 验架构（本会话即用 Linaro GCC 5.2.1 编 aarch64 .o、tiarmclang 编 ARM EABI5 .o 各自 readelf 确认）。
