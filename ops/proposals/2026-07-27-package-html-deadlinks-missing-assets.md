---
id: package-html-deadlinks-missing-assets
type: lesson
status: candidate
scope: global
domain: doc-packaging
tags: [html, docs, packaging, deadlinks, assets, relative-path, git-untracked, handoff]
triggers:
  - "把 HTML / 带资源引用的文档搬进交付子目录，或打包成 port/handoff 包发给下游"
  - "交付/移动的文档打开后样式丢失变成裸文档，图片裂开或脚本不生效"
  - "文档引用的 CSS / 图片 / 字体 / JS 未被 git 跟踪，只存在于本地工作区"
  - "重组目录结构后 grep href/src 发现引用指向仓库根的静态资源"
  - "做交付包时只搬了文档没搬它依赖的静态资源"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:c0a7ecbd-7117-4c93-931a-53aca42b7fed
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
把 HTML / 带资源引用的文档搬进交付子目录或打包时，文档对静态资源（样式表、图片、字体、脚本）的**相对引用会因资源未随包一起搬而断成死链**——尤其当资源**未被 git 跟踪、只存在于本地工作区**时，单纯移动文档会把资源"丢下"，下游拿到的是无样式/缺图的裸文档。交付前必须扫描文档的 `href`/`src`，连同被引用资源一起打包并逐一校验可达。

**为什么**：相对路径（如 `../assets/style.css`）只在原始目录拓扑下成立；搬移文档改变拓扑后路径即失效。若资源本就未被 git 跟踪，`git mv`/移动文档无法带上它，下游 checkout 后引用落空。这个坑在"上一轮打包、下一轮才发现"时最隐蔽——本地一切正常（资源还在原地），交付出去才暴露。

**做法/验证**：
1. 打包前用 `grep -oE '(href|src)="[^"]*"' <docs>` 列出全部外部引用，筛出指向静态资源的相对路径。
2. 对每个被引用资源跑 `git ls-files <asset>`；返回空（未跟踪）的，必须显式拷进包 / 连同移动，不能指望 git 带上。
3. 交付后从干净检出（`git stash -u` + 验证）打开文档，确认样式/图片实际生效，而非依赖本地残留。

**反例/边界**：绝对 URL（`http(s)://` 外链）不受目录搬移影响，不用搬；但跨网交付时外链仍可能失效，属另一类问题。本条只管"仓库内相对引用的静态资源"。

**证据**：session `c0a7ecbd-7117-4c93-931a-53aca42b7fed`。commit `ced767a fix(port): 补齐 reference HTML 的样式表依赖`。切片佐证：`grep -oE '(href|src)="[^"]*"' port/provenance/reference/*.html` 输出 `href="../assets/style.css"`；`diff -q assets/style.css archive/...` 确认根 `assets/` 与包内副本逐字节一致但根那份从未被 git 跟踪。末条 assistant 自述缺陷："交付包里那三份 reference HTML 引用 `../assets/style.css`，而这个样式表在仓库根、且从未被 git 跟踪。我只搬了 HTML 没搬样式表"。
