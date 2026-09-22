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
