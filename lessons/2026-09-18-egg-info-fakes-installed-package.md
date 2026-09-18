---
id: egg-info-fakes-installed-package
type: lesson
status: candidate
scope: global
domain: python-packaging
tags: [egg-info, importlib-metadata, sys-path, cwd, install-verification]
triggers:
  - "要确认某个 python 包/命令到底装没装到解释器里（迁移、清理全局命令、排查 import 来源时）"
  - "仓库根目录里有 *.egg-info/ 或 *.dist-info/ 残留，担心它影响判断"
  - "importlib.metadata.version('<pkg>') / distribution() 能返回版本号，就以为包已安装"
  - "在仓库目录里 `import <pkg>` 成功、换到别的 cwd 就 ModuleNotFoundError（失败信号）"
  - "删掉项目里的 egg-info 前后结论相反，不知道该信哪次"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a964-e50e-77c1-a593-51a129dcb579
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [tmp-script-import-needs-explicit-pythonpath]
---

**主张**：判断「这个包是不是真的装到解释器里了」不能在仓库目录里跑 import——仓库里残留的 `*.egg-info/` 会在 cwd 上把源码包伪装成已安装：`import <pkg>` 成功、`importlib.metadata.version()` 返回 `0.1.0`、`distribution()` 的 dist path 指向仓库内的 `spc865.egg-info`，三样看起来都像已安装。**决定性证据是换到无关 cwd 再 import**（`cd /tmp && python3 -c "import <pkg>"` 报 ModuleNotFoundError 即未安装），并核对 site-packages 里有没有该包的 `.pth` / `dist-info` / `__editable__*` 记录。

**为什么**：cwd 在 `sys.path` 上，而 egg-info 又让 `importlib.metadata` 能解析到元数据，于是「cwd 里的源码包」和「真的 pip 装过的包」在仓库内无法区分；只有离开仓库目录，注入的 sys.path 项消失，两条路径才会分叉。本会话正是靠 `/tmp` 里的那次 import 失败 + site-packages 里没有 spc865 记录，才敢下「没有安装、`~/bin` 那两条命令靠软链活着」的结论，然后才去清理 egg-info 和软链。

**边界**：换 cwd 的 import 也会受 `PYTHONPATH`、`.pth`、`sitecustomize` 影响，所以要和 site-packages 实地核对一起用；反过来，`pip install -e .` 的 `__editable__*.pth` 会让任意 cwd 都能 import，那时「哪里都能导入」才是真安装了。

**证据**（session 01a0a964，evo slice「命令 ↔ 结果」）：
- 仓库内探测：`python3 -c "import spc865, importlib.metadata as md; print('import path:', spc865.__file__) ... "` → `import path: /Users/zodyne/Dev/spc865-adc/spc865/__init__.py`、`dist version: 0.1.0`、`dist path: spc865.egg-info`（元数据来自仓库内 egg-info，不是 site-packages）。
- site-packages 清点 → 只有无关的 `__editable___algommw_radar…`，没有 spc865 的 `.pth` / `dist-info`。
- 决定性测试：`cd /tmp && python3 -c "import spc865"` → `import 失败: ModuleNotFoundError No module named 'spc865'`。
- 处置后再核：`rm -rf spc865.egg-info` → `egg-info 已删：不存在 ✓`；随后 `ls -a | grep -i egg` → `spc865.egg-info：不存在 ✓`。
