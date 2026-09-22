---
id: algommw-plus-core-headers-ifndef-guard-convention
type: fact
status: candidate
scope: project:algommw-plus
domain: codebase-map
tags: [algommw-plus, cpp17, header, include-guard, ifndef, pragma-once]
triggers:
  - "给 algommw-plus 的 core 新增头文件，要决定守卫写 `#ifndef` 宏还是 `#pragma once`"
  - "在 algommw-plus core 里看到 `#pragma once` 或没有守卫的新 `.hpp`（失败信号：与仓库既有风格不一致）"
  - "C++17 移植卡要在 core 下建 fp.hpp 这类共享头文件，按什么风格写"
  - "审计 algommw-plus core 头文件的守卫覆盖率/风格一致性"
created: 2026-09-19
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b755-1ced-7475-af70-36d31f08cee8
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [inline-constexpr-header-still-needs-include-guard, algommw-plus-type-widths-for-offsetof]
---

# algommw-plus core 头文件守卫约定：`#ifndef` 宏 32/32，零 `#pragma once`

## 主张

`/Users/zodyne/Dev/algommw-plus` 的 `core/` 下头文件**一律用 `#ifndef` 宏守卫，没有一个用 `#pragma once`**：实测 `.hpp` 32 个、含 `#ifndef` 的 32 个、含 `#pragma once` 的 0 个。新增头文件（如 `fp.hpp`）应沿用 `#ifndef <大写宏>` 形式，别引入 `#pragma once`。

## 为什么

这是仓库既有风格，且是 32/32 的一致约定；混进 `#pragma once` 会制造第二种守卫风格，让"守卫存在性"的静态检查/评审（例如按 `#ifndef` 模式扫）出现假阴性。目录分布为 `core/include/{base,chain,dpu,math,types}`，其中 `core/include/base/` 现有 `compiler.hpp`、`types.hpp`。

## 证据（本会话切片，命令 ↔ 结果）

- `echo "== core .hpp count ==" && find core -name '*.hpp' | wc -l && … #pragma once … && … ifndef in core headers …`
  → `== core .hpp count == 32 == pragma once == 0 == ifndef in core headers == 32`。
- `head -20 core/include/base/types.hpp` → 首两行即 `#ifndef BASE_TYPES_H` / `#define BASE_TYPES_H`（文件内还配 `#include <stddef.h> <stdint.h> <stdbool.h>` 与 `#ifdef __cplusplus` 段）。

## 边界 / 反例

- 这是 **2026-09-19 快照**：只覆盖 `core/` 下的 `.hpp`（不含 `tests/`、`tools/`、生成物）；换 scope 要重数。
- 本条只主张**风格一致性**，不主张 `#pragma once` 会出错——它在语义上同样能防重复包含。
- 与"头文件需要守卫"是两件事：守卫**必须有**（`inline constexpr` 头文件也一样，见同批提案 `inline-constexpr-header-still-needs-include-guard`），用哪种写法才是本条。

## 2026-09-22 独立复核增补

下列是复核时在本机跑过的**自包含最小复现**：

```
cd /Users/zodyne/Dev/algommw-plus && H=$(find core -name '*.hpp'); echo "hpp=$(echo "$H" | wc -l) pragma_once=$(rg -l '#pragma once' $H | wc -l) ifndef=$(rg -l '#ifndef' $H | wc -l)"\n# 期望（2026-09-22 实测）: hpp=36 pragma_once=0 ifndef=36\n# 条目记录的 32/0/32 是 2026-09-19 快照；模式（零 pragma once、全 ifndef）不变，计数已随仓库推进漂到 36。
```


**审核给出的修改意见（要点）**：主张的核心（core 下 .hpp 一律 `#ifndef` 宏守卫、零 `#pragma once`）经本机复跑仍然成立，但把快照计数当成断言值会误导——3 天就漂了。改法：\n1) headline/主张句去数字化：改成「algommw-plus core 头文件守卫约定：全用 `#ifndef` 宏，零 `#pragma once`」，把 `32/32` 降为 as-of 快照（写「截至 2026-09-19 为 32/32；2026-09-22 复跑为 36/36，模式不变」）。\n2) §为什么里「目录分布…`core/include/base/` 现有 `compiler.hpp`、`types.hpp`」已过时：compiler.hpp 已不存在，base/ 现为 fp.hpp / libm.hpp / limits.hpp / types.hpp / units.hpp / visit.hpp。要么删掉具体文件名，要么改成不持久化的表述。\n3) 证据节第 2 条的 `#ifndef BASE_TYPES_H` 引例已改名（现 `BASE_TYPES_HPP`），标注为「当时的文件形态」即可，不必改数。\n4) 「#pragma once 会让按 `#ifndef` 扫的静态检查出现假阴性」是推得的机制、切片未证——降级为「可能/需自证」或删，别当作已证事实。\n（

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 混进 `#pragma once` 会制造第二种守卫风格，让"守卫存在性"的静态检查/评审（例如按 `#ifndef` 模式扫）出现假阴性。

**判定**：keep-with-fix · 拟 keep-lessons · 原证据快照风险=high · 复核时本机可复跑=true
