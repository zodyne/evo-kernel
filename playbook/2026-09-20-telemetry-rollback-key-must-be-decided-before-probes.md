---
id: telemetry-rollback-key-must-be-decided-before-probes
type: lesson
status: validated
scope: global
domain: telemetry
tags: [telemetry, probes, rollback, jsonl, session-key, guard-hits]
triggers:
  - "要跑会经过真实 hook/遥测链路的自审探针（计时、行为观测），而不能用 fixture 隔离"
  - "清理 append-only 台账时发现只能按时间戳删（失败信号：清理脚本里写死一串 ts）"
  - "探针行与真实行形态相同，批量清理有误删风险（如真实命令行里含与探针相同的字面量）"
  - "给自记录系统做基准或审计，事后要回滚自己产生的遥测行"
  - "设计新日志/台账 schema，决定要不要带 session/请求 id 这类回滚键"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bc84-d38b-76aa-9257-83bbda1ace9a
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [benchmark-traffic-isolated-from-telemetry, entry-id-grep-hits-bench-labels]
---

# 探针遥测的回滚键要在跑之前定：没 session 字段的台账只能靠时间戳硬删

## 主张

当基准/审计探针**必须走真实 hook 链路**（要测的就是真实开销与真实行为，fixture 隔离会把被测对象换掉）时，
探针流量必然写进生产台账，只能事后回滚。
这时要先逐条确认**每条遥测流有没有可判定的回滚键**：
本次 `recall.jsonl` / `session-refs.jsonl` 带 `session` 字段，探针用 `bench-<rand>` 前缀
就能按键值批量精确删；而 `guard-hits.jsonl` 的 schema 是 `{ts, rule, mode, tool, target, quality}`——
**没有 session**，只能按探针各自的时间戳逐条硬编码删除，脆弱且不可复用。
清理后必须复查（`rg` 残留为空），并逐条保住真实命中行。

## 为什么

"事后清理"看起来是运维细节，实际是探针设计的约束：
回滚键决定了你能不能把"我造的流量"与"真实流量"在同一个 append-only 文件里分开。
没有键时，唯一可分的是时间戳/文本特征——两者都可能与真实行撞车
（本次真实行里就含与探针相同的 `rm -rf` 字面量），而按时间窗批量删会误伤真实记录。
所以更稳的顺序是：**先确认键 → 再造探针流量**；键不存在时，要么探针流量用可识别的
target/规则特征，要么给台账补一个 session 字段（本次都没做，属边界遗留）。

## 证据（本会话命令 ↔ 结果）

- 探针设计：计时探针调 `hook-recall` 时传 `session_id: "bench-$RANDOM"`；事前确认行数用
  `rg -c '"session":"bench' ops/log/recall.jsonl inbox/session-refs.jsonl` → 命中 3（recall）+ 1（session-refs）。
- 按键回滚（`String(j.session||"").startsWith("bench-")`）：
  `ops/log/recall.jsonl removed 3` / `inbox/session-refs.jsonl removed 1`；
  复查 `rg -n '"session":"bench' …` → 无输出（`(无输出=已清干净)`）。
- 无键台账：guard-hits 侧探针触发 4 行，行内只有 ts 可定位，例：
  `{"ts":"2026-09-20T01:54:56.578Z","rule":"dangerous-rm-rf","mode":"warn","tool":"bash","target":"rm -rf /tmp/x","quality":"exec"}`
  → 按 4 个精确 ts 删除：`removed 4 rows; 现在总行数: 514`。
- 真实行保留：同日 `01:54:56.314Z` 的 `quality:"mention"` 行（target 是探针命令自身文本，含引号内 `rm -rf` 字面量，属真实 bash 调用）未删；清理后统计 `总命中 514 / pi 期 280 / exec 275 / mention 5`。
- 源码佐证无 session 字段：`appendGuardHit({ ts, rule, mode, tool, target, quality })`（`bin/evo` guard 路径）。

## 边界 / 反例

- guard-hits 的按 ts 删除是一次性硬编码：两条探针 ts 相同、或探针由别的进程写入就删不干净；更稳的做法是给台账加 session 字段或让探针带可识别特征（本次未做）。
- 本条不反对 fixture 隔离（见 related）：能隔离就隔离；只有"必须测真实链路"时才走事后回滚。
- 复查只验"grep 无残留"，没有做行数守恒校验（事前行数 − 事后行数 = removed 数），也没检查下游是否已聚合过这些行。
- 记录型台账（本条的 recall/guard/session-refs）不参与执行判定，删错代价是统计失真；**执行判定用的数据（如 guard 的 deny 决定）不应事后回滚**，否则审计链就断了——本条不覆盖那种场景。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
命令（自包含，本机可当场重跑）：
cd /Users/zodyne/Dev/evo-kernel && node -e 'const fs=require("fs");for(const f of ["ops/log/guard-hits.jsonl","ops/log/recall.jsonl","inbox/session-refs.jsonl"]){const o=JSON.parse(fs.readFileSync(f,"utf8").trim().split("\n").pop());console.log(f.padEnd(28),"keys:",Object.keys(o).join(","))}'

2026-09-22 实测输出：
ops/log/guard-hits.jsonl     keys: ts,rule,mode,tool,target,quality
ops/log/recall.jsonl         keys: ts,session,task,ids,chars,backend
inbox/session-refs.jsonl     keys: ts,session,transcript,harness,distilled,ended

即：guard-hits 无 session（只有 ts 可当回滚键），recall/session-refs 有 session —— 条目核心主张复现成立。
源码佐证：bin/evo:779 `appendGuardHit({ ts: new Date().toISOString(), rule: r.id, mode: r.mode, tool: toolName, target: target.slice(0, 100), quality });`
```

**审核给出的修改意见（要点）**：换证据、收窄一般律，核心主张保留。(1) 证据节：删掉无法复跑的 2026-09-20 具体行（ts 578Z、514 行、4 行探针原文）与「事前 rg -c 命中 3+1」，换成下面 minimalRepro 那条三份台账键集对比 + bin/evo:779 的 appendGuardHit 字段集——后者才是「guard-hits 无回滚键」的可复跑证据。(2) 把「探针流量必然写进生产台账、只能事后回滚」收窄为「走真实 hook 链路的探针在本仓三份台账上确实都落盘（本次实测）」，并明确「先确认键→再造流量」是由这一次观测得出的顺序建议，非已验证的普遍律。(3) 该条仍在 playbook：真值是本机 schema 的稳定属性（guard-hits 无 session、recall/session-refs 有），不绑已消失的快照，且已给出自包含最小复现。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 探针流量必然写进生产台账，只能事后回滚（把单次会话里三份台账都曾落盘，升格为「必然」）

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
