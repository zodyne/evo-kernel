---
id: commit-reproducible-artifacts-verify-determinism
type: lesson
status: candidate
scope: global
domain: git
tags: [git, reproducibility, determinism, large-files, gitignore]
triggers:
  - "仓库里有 .bin / 点云 / 图等大体积可再生产物，想提交又不想把几百 MB 塞进 git"
  - "决定用 .gitignore 排除生成数据，但不确定排除后别人 clone 能否复现"
  - "仿真/生成类仓库首次 git init，拿不准该提交哪些文件"
  - "提交完才发现 .gitignore 没盖住，大二进制混进首次 commit（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a8cc-ab3f-76f9-ae0a-8c02d450cbc9
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

主张：提交包含大体积可再生产物（.bin/点云/图）的仓库前，先验证生成确定性、重生成逐字节比对、干净克隆后重跑，证明「大文件不入库」不影响可复现性，而不是只写 .gitignore 就入库。

证据（session 01a0a8cc）：bpm_2t8r_sim 有 234MB 可再生产物（adc.py 生成的 .bin、.pyc、fig），入库流程是——① grep seed/np.random 确认生成确定性；② rm -rf /tmp/repro_demo 后重生成 demo 单场景，逐字节一致（"demo 也逐字节一致"）；③ 生成 SHA256SUMS 14 条校验和清单；④ git clone -q . /tmp/clone_test2 干净克隆后跑 run_demo.py → [PASS]；⑤ 重生成的图 vs 入库的图逐字节 "一致"。这条闭环把「232 MB 不入库」从一句承诺变成可验证事实。

反例/边界：若生成非确定性（无固定 seed、依赖时间戳/随机数），排除生成物会破坏可复现性——此时要么先固定 seed、要么把数据纳入版本控制或另存，不能照抄本流程。

related: [git-add-a-verify-staged-catches-gitignore-gaps]
