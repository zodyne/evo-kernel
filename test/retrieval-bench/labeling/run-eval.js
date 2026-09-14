#!/usr/bin/env node
/**
 * 穷举盲标评测器 —— 对**当前**系统算 precision 与 recall。
 *
 * 为什么必须今天重跑，而不能用 recall.jsonl 里的历史注入
 * ------------------------------------------------------
 * 首版评测踩过这个坑：拿历史记录的注入集去比**今天的**条目集与标注，得出
 * precision 22%/recall 22%；改成今天重跑后是 **53%/28%**。差这么多是因为历史记录跨了
 * 几个月，其间条目被退役、改名、固化进 skill —— 拿它比今天，比的不是同一个系统。
 * ⇒ **凡是"系统行为"两侧都要取自同一时刻**：条目集取当下、注入也必须是当下跑出来的。
 *
 * 为什么必须同时报两个数
 * ----------------------
 * 本库自己有一条 `injection-precision-must-split-recall-vs-adoption`：合成一个数会让指标
 * 对 harness-benefit 失效。而首版评测的实际教训是**只报一侧同样有害**：只报 precision 会
 * 让"少注入"看起来永远是改进（precision 升、recall 崩）。所以本工具**强制两个都打印**，
 * 且把「漏/误」比一并给出 —— 那个比值才是"该往哪边优化"的直接读数。
 *
 * 口径
 * ----
 * - precision = 命中 / (命中 + 误注入)      ← 注入了但标注为 I
 * - recall    = 命中 / (命中 + 漏)          ← 标注为 R 但没注入
 * - `irrelevant` 层（信息不足以判定相关性的 query，见 SPEC.md）**不进分子分母**
 * - 在临时 ROOT 副本里跑，不污染真实 recall.jsonl
 *
 * 用法
 * ----
 *   node test/retrieval-bench/labeling/run-eval.js            # 算当前默认评分的两数
 *   EVO_SCORING=v2 node test/retrieval-bench/labeling/run-eval.js   # 评估某个变体
 *   node test/retrieval-bench/labeling/run-eval.js --verbose  # 逐 query 明细
 */
'use strict';
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const HERE = __dirname;
// run-eval.js 在 test/retrieval-bench/labeling/ ⇒ 仓库根是上三级，不是两级。
// 曾经写成 '../..' 得到的是 <repo>/test ⇒ 临时 ROOT 为空 ⇒ 所有 query 都零注入、两数全 0。
const SRC = path.resolve(HERE, '../../..');
const VERBOSE = process.argv.includes('--verbose');

const { queries } = JSON.parse(fs.readFileSync(path.join(HERE, 'queries.json'), 'utf8'));
const { labels, meta } = JSON.parse(fs.readFileSync(path.join(HERE, 'labels.json'), 'utf8'));

// ── 临时 ROOT 副本 ──
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'evo-eval-'));
for (const d of ['bin', 'playbook', 'facts', 'episodes', 'principles', 'lessons', 'ops', 'index', 'inbox']) {
  const s = path.join(SRC, d);
  if (fs.existsSync(s)) fs.cpSync(s, path.join(tmp, d), { recursive: true, filter: (p) => !p.includes('/ops/log/') });
}
for (const f of ['SCHEMA.md', 'package.json']) {
  if (fs.existsSync(path.join(SRC, f))) fs.copyFileSync(path.join(SRC, f), path.join(tmp, f));
}
fs.mkdirSync(path.join(tmp, 'ops', 'log'), { recursive: true });
fs.symlinkSync(path.join(SRC, 'node_modules'), path.join(tmp, 'node_modules'), 'dir');

const injectedNow = (task) => {
  try {
    const out = execFileSync(path.join(tmp, 'bin/evo'), ['recall', '--task', task, '--budget', '1500'], {
      env: { ...process.env, EVO_ROOT: tmp }, encoding: 'utf8', timeout: 30000,
    });
    return (out.match(/^\[id:([^\]]+)\]/gm) || []).map((s) => s.slice(4, -1));
  } catch { return []; }
};

let tp = 0, fp = 0, fn = 0, skipped = 0;
let tpHi = 0, fpHi = 0, fnHi = 0; // 区间上界（borderline 计入相关）
const rows = [];
for (const q of queries) {
  const L = labels[String(q.n)] || {};
  if (L.layer === 'nontask' || L.layer === 'indeterminate') { skipped++; continue; } // 这两层不进指标（理由见 SPEC.md）
  const rel = new Set(L.relevant || []);
  const bl = new Set(L.borderline || []); // 区间上界：把 borderline 也算作相关
  const inj = new Set(injectedNow(q.query));
  const hit = [...rel].filter((x) => inj.has(x)).length;
  const wrong = [...inj].filter((x) => !rel.has(x)).length;
  const miss = [...rel].filter((x) => !inj.has(x)).length;
  tp += hit; fp += wrong; fn += miss;
  const hitHi = [...rel, ...bl].filter((x) => inj.has(x)).length;
  const wrongHi = [...inj].filter((x) => !rel.has(x) && !bl.has(x)).length;
  const missHi = [...rel, ...bl].filter((x) => !inj.has(x)).length;
  tpHi += hitHi; fpHi += wrongHi; fnHi += missHi;
  rows.push({ n: q.n, kind: q.kind, rel: rel.size, bl: bl.size, inj: inj.size, hit, wrong, miss, hitHi, wrongHi, missHi });
}

const P = tp + fp ? tp / (tp + fp) : 0;
const R = tp + fn ? tp / (tp + fn) : 0;
console.log(`# 穷举盲标评测（scoring=${process.env.EVO_SCORING || 'v0(默认)'}）`);
console.log(`查询 ${queries.length} 个${skipped ? `（跳过不可判定层 ${skipped} 个）` : ''}　标注依据：${meta.rubric.split('：')[0]}\n`);
if (VERBOSE) {
  console.log('| n | 类型 | 真相关 | borderline | 实注入 | 命中 | 误 | 漏 |');
  console.log('|---|---|---|---|---|---|---|---|');
  for (const r of rows) console.log(`| ${r.n} | ${r.kind} | ${r.rel} | ${r.bl} | ${r.inj} | ${r.hit} | ${r.wrong} | ${r.miss} |`);
  console.log('');
}
const PHi = tpHi + fpHi ? tpHi / (tpHi + fpHi) : 0;
const RHi = tpHi + fnHi ? tpHi / (tpHi + fnHi) : 0;
console.log(`命中 ${tp} · 误注入 ${fp} · **漏 ${fn}**`);
// 区间按小到大排：把 borderline 计入「相关」时，precision 的分母缩小（升），而 recall 的
// 分母长大得比分子快（降）—— 两个方向的端点并不对应同一种待遇。曾经直接按「下界/上界」写，
// 把 recall 打成了 [33–16%]。
const rng = (a, b) => `[${(Math.min(a, b) * 100).toFixed(0)}%, ${(Math.max(a, b) * 100).toFixed(0)}%]`;
console.log(`**precision = ${tp}/${tp + fp} = ${(P * 100).toFixed(0)}%**　区间 ${rng(P, PHi)}（把 borderline 当相关则升）`);
console.log(`**recall    = ${tp}/${tp + fn} = ${(R * 100).toFixed(0)}%**　区间 ${rng(R, RHi)}（把 borderline 当相关则**降** —— 最坏情形是低端）`);
if (fp > 0 || fn > 0) {
  const ratio = fp ? (fn / fp).toFixed(2) : '∞';
  console.log(`漏/误 = ${ratio}　${Number(ratio) > 1.5 ? '⇒ 约束在**召回**侧：漏得比误得多，多注入的边际成本更低' : Number(ratio) < 0.67 ? '⇒ 约束在**精度**侧' : '⇒ 两侧均衡'}`);
}
console.log('\n> 只报一个数会误判方向：precision 升而 recall 崩，看起来像改进。两个都要看。');
fs.rmSync(tmp, { recursive: true, force: true });
