#!/usr/bin/env node
/**
 * §5.0 回放仲裁 —— 评分/后端变更的**相对对账**（bench 是绝对质量，两者互补）。
 *
 * 背景与由来
 * -----------
 * 2026-07-28 否决过 v3（floor+idf）评分变体，理由是「§5.0 要求丢失清单逐条人审，
 * 189 条未审 → 不 cutover」。但那次回放是**临时做的、没留工具**，只有输出抄进了
 * BASELINE.md —— 于是每次要再评估一次评分改动，都无法复现同一口径。
 * 本脚本把它固定下来，并加一项当时没有的能力：**给每条丢失附上对账精度**。
 *
 * 为什么要附精度
 * --------------
 * 「丢失 N 条」本身不含判优信息：丢掉的可能是噪声（✅ 改进）也可能是正解（❌ 回归）。
 * 仓库里已有 reconcile.jsonl 的四态判定 ⇒ 丢失清单可以直接按 `相关/总` 折算成精度，
 * 把「逐条人审」里最费时、也最可机械化的那一半自动做掉。
 * （边界：精度只够判「这条被丢是否可惜」；样本数 <5 的条目按「样本不足」标出，
 *   仍需人judge —— 不要把它当自动裁决。）
 *
 * 用法
 * ----
 *   node test/retrieval-bench/replay.js                 # 默认 v0 vs v3
 *   node test/retrieval-bench/replay.js v0 v1           # 自定义对比
 *   node test/retrieval-bench/replay.js --limit 50      # 只跑前 N 条（快速冒烟）
 *
 * 口径（与 BASELINE.md 2026-07-28 那行一致，便于对照）
 * ----------------------------------------------------
 *   注入集完全一致 / 两侧均空 / 丢失（A 有 B 无）/ 新增（B 有 A 无）
 *   并按查询长度分组（长短查询的行为差异是本工具存在的理由之一）
 *
 * 实现注意
 * --------
 * - **在临时 ROOT 副本里跑**：`evo recall` 会写 ops/log/recall.jsonl，
 *   直接跑会污染真实日志（那正是 M1 精度的数据源）。
 * - 用 execFileSync 传参数组、不经 shell：中文任务文本里带引号/换行时不会被 shell 吃掉。
 */
'use strict';
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const SRC = path.resolve(__dirname, '../..');
// 只认形如 v0..v3 的位置参数 —— 否则 `--limit 20` 的 20 会被当成变体名（首次运行踩到）
const variants = process.argv.slice(2).filter((a) => /^v\d$/.test(a));
const A = variants[0] || 'v0';
const B = variants[1] || 'v3';
const LIMIT = (() => { const i = process.argv.indexOf('--limit'); return i > 0 ? Number(process.argv[i + 1]) : 0; })();

// ── 临时 ROOT：照抄仓库（排除 .git / node_modules / ops/log 的日志本体，避免带走巨量历史）──
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'evo-replay-'));
for (const d of ['bin', 'playbook', 'facts', 'episodes', 'principles', 'lessons', 'ops', 'index', 'inbox']) {
  const s = path.join(SRC, d);
  if (fs.existsSync(s)) fs.cpSync(s, path.join(tmp, d), { recursive: true });
}
for (const f of ['SCHEMA.md', 'package.json']) {
  if (fs.existsSync(path.join(SRC, f))) fs.copyFileSync(path.join(SRC, f), path.join(tmp, f));
}
fs.mkdirSync(path.join(tmp, 'ops', 'log'), { recursive: true });
// node_modules 走软链：cpSync 整份太慢，而 bin/evo 需要 js-yaml
fs.symlinkSync(path.join(SRC, 'node_modules'), path.join(tmp, 'node_modules'), 'dir');

// ── 查询集：recall.jsonl 去重 ──
const tasks = [];
const seen = new Set();
for (const l of fs.readFileSync(path.join(SRC, 'ops/log/recall.jsonl'), 'utf8').split('\n')) {
  if (!l.trim()) continue;
  try { const j = JSON.parse(l); const t = (j.task || '').trim(); if (t && !seen.has(t)) { seen.add(t); tasks.push(t); } } catch {}
}
const use = LIMIT ? tasks.slice(0, LIMIT) : tasks;
console.log(`# §5.0 回放仲裁：${A} vs ${B}`);
console.log(`查询 ${use.length} 条（recall.jsonl 去重 ${tasks.length} 条）  backend=${process.env.EVO_BACKEND || 'scan'}\n`);

const idsOf = (variant, task) => {
  try {
    const out = execFileSync(path.join(tmp, 'bin/evo'), ['recall', '--task', task, '--budget', '1500'], {
      env: { ...process.env, EVO_ROOT: tmp, EVO_SCORING: variant }, encoding: 'utf8', timeout: 30000,
    });
    return (out.match(/^\[id:([^\]]+)\]/gm) || []).map((s) => s.slice(4, -1))  // '[id:' 是 4 字符;
  } catch { return []; }
};

const rows = [];
for (const t of use) {
  const a = idsOf(A, t), b = idsOf(B, t);
  rows.push({ task: t, len: t.length, a, b, lost: a.filter((x) => !b.includes(x)), added: b.filter((x) => !a.includes(x)) });
}

const sameN = rows.filter((r) => r.a.join() === r.b.join()).length;
const bothEmpty = rows.filter((r) => !r.a.length && !r.b.length).length;
const withLost = rows.filter((r) => r.lost.length);
const withAdded = rows.filter((r) => r.added.length);
const lostAll = withLost.flatMap((r) => r.lost);
const addedAll = withAdded.flatMap((r) => r.added);

// ── 丢失/新增逐条附对账精度 ──
const rec = {};
for (const l of fs.readFileSync(path.join(SRC, 'ops/log/reconcile.jsonl'), 'utf8').split('\n')) {
  if (!l.trim()) continue;
  try { const j = JSON.parse(l); if (j.id) { const t = rec[j.id] = rec[j.id] || { n: 0, rel: 0 }; t.n++; if (j.state === 'adopted' || j.state === 'relevant-unused') t.rel++; } } catch {}
}
const tally = (arr) => {
  const c = {};
  for (const id of arr) c[id] = (c[id] || 0) + 1;
  return Object.entries(c).sort((x, y) => y[1] - x[1]);
};
const verdict = (id) => {
  const t = rec[id];
  if (!t || !t.n) return '样本不足（无对账）';
  if (t.n < 5) return `样本不足（${t.rel}/${t.n}）`;
  return t.rel / t.n >= 0.5 ? `❌ 丢=回归（精度 ${Math.round(t.rel / t.n * 100)}%，${t.rel}/${t.n}）` : `✅ 丢=改进（精度 ${Math.round(t.rel / t.n * 100)}%，${t.rel}/${t.n}）`;
};

console.log('| 项 | 数 |');
console.log('|---|---|');
console.log(`| 注入集完全一致 | ${sameN} |`);
console.log(`| 两侧均空 | ${bothEmpty} |`);
console.log(`| 有丢失的查询 | ${withLost.length}（丢失实例 ${lostAll.length}）|`);
console.log(`| 有新增的查询 | ${withAdded.length}（新增实例 ${addedAll.length}）|`);

const byLen = (rs) => {
  const g = { '短(<30)': [0, 0], '中(30-100)': [0, 0], '长(>100)': [0, 0] };
  for (const r of rs) { const k = r.len < 30 ? '短(<30)' : r.len < 100 ? '中(30-100)' : '长(>100)'; g[k][0] += r.lost.length; g[k][1] += r.b.length; }
  return g;
};
console.log('\n按查询长度（丢失实例 / B 侧注入实例）：');
for (const [k, [l, kept]] of Object.entries(byLen(rows))) console.log(`  ${k.padEnd(12)} 丢失 ${String(l).padStart(4)} / 保留 ${String(kept).padStart(5)}`);

console.log(`\n**丢失 Top（附对账精度）**`);
for (const [id, n] of tally(lostAll).slice(0, 20)) console.log(`  ${String(n).padStart(3)}× ${id}\n       → ${verdict(id)}`);
console.log(`\n**新增 Top**`);
for (const [id, n] of tally(addedAll).slice(0, 10)) console.log(`  ${String(n).padStart(3)}× ${id}`);

console.log('\n> 丢失/新增的**判定**仍需人 review：「样本不足」的那些本工具代替不了；');
console.log('> 精度只回答「这条被丢是否可惜」，不回答「这条当时是否该被注入」。');
fs.rmSync(tmp, { recursive: true, force: true });
