---
id: frontmatter-edit-must-use-setfmfield
type: lesson
status: validated
scope: global
domain: knowledge-base
tags: [frontmatter, setfmfield, parsefm, audit, silent-corruption, evo-kernel]
triggers:
  - "手写正则或 python 重写 markdown frontmatter 字段"
  - "条目改过 frontmatter 后对 audit/recall 全部隐身（失败信号）"
  - "audit 总数下降但看不出异常，manifest 多出一个 ? 桶"
  - "需要给 frontmatter 增删字段（related / status / triggers）"
  - "修复后只验证原问题消失，没验证被修对象仍对检查可见"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-14-08-02-00-372-422r
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: [string-replace-outside-block-corrupts-body]
---

# 改 frontmatter 必须用内核自己的 setFmField，不要手写正则拼字符串

## 主张

改 frontmatter 必须用内核自己的 setFmField，不要手写正则拼字符串。

## 实例

我用 python 重写 related 字段时把闭合 `---` 粘进了行尾（`related: [x]---`），该 md 不再匹配 FM_RE → parseFm 静默降级为 `{schema_version:1}`、id 回退文件名 → 条目对【全部】检查隐身（无 status → 状态类规则失效；无 related → 建链规则读不到它；无 triggers → recall 永不命中）。audit 总数从 111 下降却看不出任何异常，直到 manifest 多出一个 `?` 桶才暴露。

## 为什么

内核 `bin/evo:498` 的 setFmField 正是为此存在：注释明写「不能对全文用 `/^key:.*$/m`——正文里出现 `status:` 会被误改」，且 curate/demote/moveToArchive 三处共用、无 frontmatter 时原样返回不猜位置。我重造了它并造出了它专门要防的 bug。

## 规则

①改 frontmatter 一律走 setFmField 或专用接口，不手写正则拼字符串；②修完必须验证被修对象【仍对检查可见】，而不是只验证「原问题消失了」——坏检查器与坏修复器都生产假阴性，而假阴性看起来像成果；③可观测指纹：SCAN_DIRS 内「缺 status」（2026-09-14 已作为 MID 检查入 audit + smoke 守护）。
