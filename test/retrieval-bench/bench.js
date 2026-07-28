#!/usr/bin/env node
/**
 * 检索层可证伪基准（四阶段：learning / transfer / change / noise）
 *
 * 结构借自《大模型与 Agent 开发实战》实验 8-6（chapter8/self-evolution-eval 的
 * LongitudinalEvaluator），把"评估 Agent 是否在持续进化"的纵向框架映射到召回层。
 *
 * 与 blueprint §5.0（检索后端 cutover 验收门）的分工：
 *   §5.0 = 新旧后端**相对**对账（回放历史查询、比重叠/丢失/新增，人审判优）——无绝对标尺。
 *   本基准 = **绝对**质量（带标注的 expect_ids），给 cutover 提供可自动化的那一半。
 *
 * 边界（必须先读）：本基准证伪的是**召回层**，不是价值主张。它回答"该找的找到了没、
 * triggers 泛化不泛化、取代关系排没排干净、无关任务被塞了多少噪声"；它**不回答**
 * "注入经验是否让任务做得更好"——那需要 LLM 实跑 + 结果标注，不在本文件范围内。
 *
 * 用法：node test/retrieval-bench/bench.js [--json] [--phase learning|transfer|change|noise]
 * 退出码恒为 0（这是测量不是闸门；阈值须先有基线数据才能定，见 §7.3 判据驱动）。
 */
'use strict';

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const HERE = __dirname;
const ROOT = path.resolve(HERE, '../..');
const EVO = path.join(ROOT, 'bin/evo');
const DATASET = path.join(HERE, 'dataset.json');
const LIB_DIRS = ['playbook', 'facts', 'episodes', 'principles']; // = RECALL_DIRS

// 在临时 ROOT 跑：recall 会 append ops/log/recall.jsonl，而那正是测量本身的数据源
// （§7.1 精度、§5.0 回放都读它）。直接打真实 ROOT 会把基准查询混进真实用量统计，
// 污染判据。复制库内容到 tmp，日志写 tmp，用完即弃。
function makeRoot(sourceDirs) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'evo-bench-'));
  fs.mkdirSync(path.join(tmp, 'ops/log'), { recursive: true });
  for (const [src, name] of sourceDirs) {
    const dest = path.join(tmp, name);
    fs.mkdirSync(dest, { recursive: true });
    if (!fs.existsSync(src)) continue;
    for (const f of fs.readdirSync(src)) {
      if (f.endsWith('.md')) fs.copyFileSync(path.join(src, f), path.join(dest, f));
    }
  }
  return tmp;
}

function recallIds(root, query) {
  let out = '';
  try {
    out = execFileSync(process.execPath, [EVO, 'recall', '--task', query], {
      env: { ...process.env, EVO_ROOT: root }, encoding: 'utf8', stdio: 'pipe',
    });
  } catch (e) { out = String((e.stdout || '') + (e.stderr || '')); }
  return [...out.matchAll(/\[id:([^\]]+)\]/g)].map((m) => m[1]);
}

function main() {
  const args = process.argv.slice(2);
  const asJson = args.includes('--json');
  const only = args.includes('--phase') ? args[args.indexOf('--phase') + 1] : null;
  const tasks = JSON.parse(fs.readFileSync(DATASET, 'utf8')).tasks
    .filter((t) => !only || t.phase === only);

  const liveRoot = makeRoot(LIB_DIRS.map((d) => [path.join(ROOT, d), d]));
  const fixRoot = makeRoot([[path.join(HERE, 'fixture/playbook'), 'playbook']]);

  const records = tasks.map((t) => {
    const got = recallIds(t.phase === 'change' ? fixRoot : liveRoot, t.query);
    const expect = t.expect_ids || [];
    const forbid = t.forbid_ids || [];
    const hit = expect.some((id) => got.includes(id));
    return {
      id: t.id, phase: t.phase, query: t.query, expect, got,
      hit_top1: expect.length ? got[0] === expect[0] : got.length === 0,
      hit,
      // 噪声 = 注入了但不在期望集里的条目数。expect 为空时，注入几条就是几条噪声。
      noise: got.filter((id) => !expect.includes(id)).length,
      leaked: forbid.filter((id) => got.includes(id)), // change 阶段：被取代的旧条目泄漏
      pass: expect.length ? hit && !forbid.some((id) => got.includes(id)) : got.length === 0,
    };
  });

  fs.rmSync(liveRoot, { recursive: true, force: true });
  fs.rmSync(fixRoot, { recursive: true, force: true });

  const byPhase = {};
  for (const r of records) (byPhase[r.phase] = byPhase[r.phase] || []).push(r);
  const pct = (n, d) => (d ? Math.round((n / d) * 100) : 0);
  const summary = {};
  for (const [p, rows] of Object.entries(byPhase)) {
    summary[p] = {
      n: rows.length,
      pass: rows.filter((r) => r.pass).length,
      pass_rate: pct(rows.filter((r) => r.pass).length, rows.length),
      hit_top1: pct(rows.filter((r) => r.hit_top1).length, rows.length),
      noise_total: rows.reduce((a, r) => a + r.noise, 0),
    };
  }

  if (asJson) { console.log(JSON.stringify({ summary, records }, null, 2)); return; }

  console.log('# 检索层基准（四阶段）\n');
  console.log(`date: ${new Date().toISOString().slice(0, 10)}   backend: ${process.env.EVO_BACKEND || 'scan'}\n`);
  console.log('| 阶段 | 用例 | 通过 | 通过率 | top1 命中 | 噪声条数 |');
  console.log('|---|---|---|---|---|---|');
  for (const p of ['learning', 'transfer', 'change', 'noise']) {
    const s = summary[p];
    if (s) console.log(`| ${p} | ${s.n} | ${s.pass} | ${s.pass_rate}% | ${s.hit_top1}% | ${s.noise_total} |`);
  }
  console.log('\n## 逐例');
  for (const r of records) {
    const mark = r.pass ? '✓' : '✗';
    const detail = r.expect.length
      ? `期望 ${r.expect.join(',')} → 实得 ${r.got.length ? r.got.slice(0, 3).join(',') : '(空)'}`
      : `期望空命中 → 实得 ${r.got.length ? r.got.join(',') : '(空)'}`;
    console.log(`${mark} [${r.phase}] ${r.id}  ${detail}${r.leaked.length ? `  ⚠ 泄漏已取代条目 ${r.leaked.join(',')}` : ''}`);
    if (!r.pass) console.log(`    query: ${r.query}`);
  }
  console.log('\n> 本基准只证伪召回层，不证伪价值主张（"注入是否让任务做得更好"需 LLM 实跑 + 结果标注）。');
  console.log('> transfer 是核心指标；learning 是下限，它不通过说明召回层坏了，通过不算成绩。');
}

main();
