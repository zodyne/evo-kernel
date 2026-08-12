---
id: package-deliverable-recipient-verify
type: lesson
status: candidate
scope: global
domain: packaging
tags: [packaging, tarball, delivery, python]
triggers:
  - "打包 Python 工具交付给别人"
  - "tar 包里混进 __pycache__"
  - "收件人跑不起来/输出看不到"
  - "打包后自检"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:40a7756a
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
---

**主张**：打包交付 Python 工具的三个已验证坑：① 自检（如在暂存目录跑 `--help`）会生成 `__pycache__`，不清理就被一起打进包——先自检后清理再打包，或打包时显式排除；② 模拟收件人验证时用 `python -u`，否则 stdout 被缓冲，你以为卡住其实在白等；③ 代码若按「相对自身位置」解析资产（如 `assets.py` 往上两级找 cal 文件），包内目录结构必须与仓库一致，不能拍平。

**为什么**：三个坑都在同一次打包会话中实踩：__pycache__ 漏进 tarball 被自检抓出；收件人测试因缓冲空等；目录结构是资产解析的硬性前提。

**边界**：交付物附 README（跑法、数据要求、依赖版本、cal 指纹）+ requirements.txt + run.sh；打包后按 README 在干净目录完整走一遍才算完。

**证据**：2026-07-29 ucm221 viewer_filtered.py 打包会话（ucm221-viewer-filtered-20260729.tar.gz，8 文件）。
