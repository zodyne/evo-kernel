---
id: js-yaml-silently-parses-iso-date-to-object
type: lesson
status: validated
scope: global
domain: config-parsing
tags: [js-yaml, yaml, date, type-coercion, silent-failure]
triggers:
  - "用 js-yaml 解析含日期字段的 frontmatter / YAML 配置，下游假设字段是字符串"
  - "YAML load 后 typeof 字段 === 'object' 但写的是日期字符串"
  - "日期字段做字符串比较/拼接/format 报错或恒不等"
  - "schema 声明某字段是 ISO 日期字符串，运行时却拿到 Date 对象"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# js-yaml 默认把 `YYYY-MM-DD` 字符串静默解析成 Date 对象

**主张**：`yaml.load(text)`（默认 `DEFAULT_FULL_SCHEMA`）会识别 `2026-07-27` 这类裸 ISO 日期并转成 JS `Date` 对象，不报错也不留痕。下游代码若按"日期是字符串"做 `===` 比较、序列化、或 `Date.parse`，结果静默错（类型不符 → 比较恒 false、JSON 序列化变成 ISO 时间戳带 T）。

**根因**：YAML 1.1 规范定义了 `timestamp` 类型，js-yaml 默认 schema 开启了 `yaml.types.timestamp`，裸日期无需引号即触发类型转换。

**修法**：二选一——
1. 解析时限定 schema：`yaml.load(text, { schema: yaml.DEFAULT_SAFE_SCHEMA })` 不够（safe 仍含 timestamp），需自定义去掉 timestamp tag 的 schema；
2. 加载后对已知日期字段强制 `String()` 化（最简单可靠，本次就是这么修的）。

**反例/边界**：给日期加引号（`created: "2026-07-27"`）在源文件层面可避开，但解析器层仍会转——所以不能依赖"我都加引号了"，必须在解析出口兜底。

**证据**（commit ed0c80e）：
- 复现：`e.created === "2026-07-27"` 为 `false`，`typeof e.created` 为 `object`（Date 实例），全库 created/last_verified 字段全部失真。
- 修复后：`抽查 created: "2026-07-27" | ==="2026-07-27": true`，`修复后非字符串日期字段: 0`。
- smoke 新增 `D3: frontmatter 类型契约（日期不被静默转 Date）` + `D3: 全库日期字段均为字符串` 守护。
