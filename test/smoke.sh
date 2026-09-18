#!/usr/bin/env bash
# evo-kernel 冒烟测试 — 建立不变量守护（A–K 组，build-spec-v1.md §8）
# 设计原则（§7.3 绿地重解释）：smoke 按「建立不变量守护」组织，I1–I7 每条至少一条断言。
# 组织：A=14 / B=4 / C=1 / D=3 / E=2(+1清理) / F=15 = 39（§8.1）
#        + G(YAML fixture) / H(不变量守护 I1–I7) / I(session-refs JSONL) / J(reconcile) / K(doctor)
#        + J 追加空转退役（库的唯一自动出口）
#        + L(后台飞轮：queue / mark-distilled / reconcile / hook-recall 噪声门槛)
# 全绿 exit 0。在临时 ROOT 副本中运行，零污染真实库。
set -u
SRC="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/kernel"
# rsync 仓库到临时 ROOT（排除 .git / node_modules；EVO 用 SRC 的 bin + node_modules）
rsync -a --exclude .git --exclude node_modules "$SRC/" "$TMP/kernel/" 2>/dev/null || cp -r "$SRC"/. "$TMP/kernel/"
export EVO_ROOT="$TMP/kernel"
EVO="$SRC/bin/evo"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '✓ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '✗ %s %s\n' "$1" "$2"; }
t() { # t <名称> <期望子串|__NOOUTPUT__|__NEG__X|空串(仅exit0)> <命令...>
  local name="$1" expect="$2"; shift 2
  local out; out="$("$@" 2>&1)"; local rc=$?
  if [ "$expect" = "__NOOUTPUT__" ]; then
    { [ -z "$out" ] && [ $rc -eq 0 ]; } && ok "$name" || bad "$name" "(期望无输出&exit0, rc=$rc out=${out:0:60})"
  elif [ "${expect#__NEG__}" != "$expect" ]; then   # __NEG__<子串>：断言输出不含该子串
    local neg="${expect#__NEG__}"
    { [ $rc -eq 0 ] && ! printf '%s' "$out" | grep -q -- "$neg"; } && ok "$name" || bad "$name" "(期望不含 '$neg', 实得: ${out:0:60})"
  elif [ $rc -ne 0 ]; then bad "$name" "(exit $rc: ${out:0:60})"
  elif [ -z "$expect" ] || printf '%s' "$out" | grep -q -- "$expect"; then ok "$name"   # 空串→仅验exit0
  else bad "$name" "(期望含 '$expect', 实得: ${out:0:60})"; fi
}

# ════════════ A. 全命令冒烟（14 = 13 t() + 1 独立） ════════════
echo "——— A. 全命令冒烟 ———"
t "capture 特殊字符"      "captured"        $EVO capture '引号" $变量 `反引号` 测试'
C1="$($EVO capture 同秒A | grep -o 'capture-[^ ]*')"; C2="$($EVO capture 同秒B | grep -o 'capture-[^ ]*')"
{ [ -n "$C1" ] && [ "$C1" != "$C2" ]; } && ok "capture 同秒不碰撞(R10)" || bad "capture 同秒不碰撞(R10)" "($C1 vs $C2)"
t "recall 正常"           "evo-recall"      $EVO recall --task "arxiv 论文下载"
t "recall 空任务"         "__NOOUTPUT__"    $EVO recall --task ""
t "candidates"            "evo-candidates"  $EVO candidates
t "get 多 id"             "verify-external-references" $EVO get --ids verify-external-references,arxiv-api-rate-limit
t "get 未知 id 容错"      "未找到"          $EVO get --ids not-exist-id
t "adopt"                 "adopt recorded"  $EVO adopt --ids x
t "index rebuild"         "manifest rebuilt" $EVO index rebuild
t "audit"                 "audit"           $EVO audit
t "inbox"                 "inbox:"          $EVO inbox
t "reflect 含梯度提案"     "梯度提案"        $EVO reflect
t "link 幂等"             ""                $EVO link
t "session-end 手动"      "session registered" $EVO session-end --session /tmp/fake.jsonl

# ════════════ B. 边界与注入安全（4） ════════════
echo "——— B. 边界与注入安全 ———"
t "hook-recall JSON 注入"  "__NOOUTPUT__" bash -c "echo '{\"session_id\":\"sec-x\",\"prompt\":\"测试 }{\\\" 拼接\"}' | $EVO hook-recall"
t "hook-recall 非JSON"     "__NOOUTPUT__" bash -c "echo '纯文本' | $EVO hook-recall"
t "hook-recall 空stdin"    "__NOOUTPUT__" bash -c "printf '' | $EVO hook-recall"
# 50KB 长 prompt：意图是「不崩不挂」，输出断言是附带的。空命中提示改动后它会吐一行提示
# （那是正确行为：'x'*50000 过噪声门），故改为验 exit 0 且不含裸错误。
t "hook-recall 50KB 不崩"   "evo-recall"      bash -c "python3 -c \"import json;print(json.dumps({'session_id':'sec-long','prompt':'x'*50000}))\" | $EVO hook-recall"

# ════════════ C. fail-open（1 独立断言，EVO_ROOT 缺失） ════════════
echo "——— C. fail-open ———"
out=$(echo '{"session_id":"s","prompt":"arxiv"}' | EVO_ROOT=/nonexistent-xyz $EVO hook-recall 2>/dev/null); rc=$?
{ [ $rc -eq 0 ] && [ -z "$out" ]; } && ok "EVO_ROOT 缺失静默(exit0+stdout空)" || bad "EVO_ROOT 缺失静默" "(rc=$rc out=$out)"

# ════════════ D. 端到端（注入/去重/空命中不占名额，3） ════════════
# ⚠ 本组固定 EVO_PRECISION_MIN=0，为的是**把机制与策略分开断言**（2026-09-18 踩到）：
#   这两条走 hook（auto）路径，而 auto 路径上有「逐条精度闸门」（bin/evo 的 lowPrecisionIds，
#   n≥10 且精度<20% 就不自动注入）。那个闸门读的是**活的** ops/log/reconcile.jsonl，
#   也就是一份会随蒸馏持续增长、由另一个后台进程写入的账本。实测：
#   `arxiv-download-proxy-truncation` 在 2026-09-18 01:07Z 之前是 2/10 = **恰好 20%**
#   （零余量、靠 < 而非 ≤ 过关），本轮并行蒸馏 30 分钟内又写了 12 条对账（11 irrelevant +
#   1 adopted）→ 4/22 = 18.2% → 被闸门排除 → 本组突然变红，而代码一行没改。
#   即：本组想守的是「hook 收到实义 prompt → 能注入命中条目」这条**管道**，不是
#   「某条特定条目当下是否过了精度闸门」这条**策略**。策略本身在文件末尾有确定性的守护
#   （合成条目 + 合成账本，不依赖活库）。所以这里把闸门阈值调成 0（= 不排除任何条目）
#   夹住变量；若将来想让本组也覆盖闸门，必须用**夹具**而不是活账本。
t "全新 session 命中避坑"  "arxiv-download-proxy-truncation" bash -c "echo '{\"session_id\":\"fresh-\$RANDOM\",\"prompt\":\"帮我批量下载 arXiv 论文 PDF\"}' | EVO_PRECISION_MIN=0 $EVO hook-recall"
SID="dedup-$RANDOM"
echo "{\"session_id\":\"$SID\",\"prompt\":\"arxiv 下载 pdf 损坏\"}" | EVO_PRECISION_MIN=0 $EVO hook-recall >/dev/null 2>&1
t "同 session 去重"        "__NOOUTPUT__" bash -c "echo '{\"session_id\":\"$SID\",\"prompt\":\"再问一次\"}' | EVO_PRECISION_MIN=0 $EVO hook-recall"
SID2="retry-$RANDOM"
echo "{\"session_id\":\"$SID2\",\"prompt\":\"今天天气如何\"}" | EVO_PRECISION_MIN=0 $EVO hook-recall >/dev/null 2>&1
t "空命中后仍重试"         "arxiv" bash -c "echo '{\"session_id\":\"$SID2\",\"prompt\":\"批量下载 arXiv 论文\"}' | EVO_PRECISION_MIN=0 $EVO hook-recall"

# ════════════ D2. 检索打分不变量（§5 治理权重 + tag 通道） ════════════
echo "——— D2. 检索打分不变量 ———"
# govWeight：harmful-helpful ≥ 2 时 log(负数)=NaN，Math.max(0.3,NaN)===NaN 会击穿下限。
# score 变 NaN 后排序比较器失效，最有害的条目落到任意位置而非末尾。
node -e "
const { govWeight } = require('$SRC/bin/evo');
let bad = 0;
for (const [h, hm] of [[0,0],[3,0],[0,1],[0,2],[1,3],[2,5],[0,9]]) {
  const w = govWeight({ verified_by: 'command', evidence: { helpful: h, harmful: hm } });
  if (!Number.isFinite(w) || w <= 0) { console.log('✗ D2: govWeight 非有限正数 h='+h+' hm='+hm+' → '+w); bad++; }
}
if (bad === 0) console.log('✓ D2: govWeight 对任意 helpful/harmful 恒为有限正数（NaN 击穿守护）');
process.exit(bad === 0 ? 0 : 1);
" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
# tag 通道：单词 tag 不得单独把无关条目顶进注入（cover 按短语长度归一 → 1 term 恒 1.0）。
# 探针条目只有单词 tag、triggers 与查询完全无关；查询命中该 tag 词但与条目主张无关。
cat > "$EVO_ROOT/playbook/zz-tagprobe.md" << 'MD'
---
id: zz-tagprobe
type: lesson
status: validated
verified_by: command
tags: [kubernetes, helm, istio, envoy]
triggers:
  - "完全无关的触发词 qqzz-unrelated-trigger"
evidence: {helpful: 0, harmful: 0}
---
探针正文与 kubernetes 无关
MD
{ ! $EVO recall --task "kubernetes 集群怎么扩容" 2>&1 | grep -q 'zz-tagprobe'; } \
  && ok "D2: 单词 tag 不足以单独注入（tag 并集归一）" || bad "D2: tag 过匹配" "(无关条目被顶进注入)"
rm -f "$EVO_ROOT/playbook/zz-tagprobe.md"

# ════════════ D3. 解析保真（M0「消除 R3 静默错解」） ════════════
echo "——— D3. 解析保真 ———"
# js-yaml 默认 schema 含 timestamp 类型，会把 `created: 2026-07-27` 静默转成 Date 对象，
# 而 SCHEMA.md 声明它是「ISO 日期（YYYY-MM-DD）」字符串。类型错了不报错、只在下游炸——
# 正是 design §7 Phase 0 的 M0 要消除的静默错解。这里守住 frontmatter 各字段的类型契约。
node -e "
const { parseFm } = require('$SRC/bin/evo');
const src = [
  '---',
  'id: zz-parse',
  'created: 2026-07-27',
  'last_verified: 2026-07-28',
  'review_after: 2026-09-25',
  'schema_version: 1',
  'status: candidate',
  'evidence: {helpful: 3, harmful: 1}',
  'tags: [a, b]',
  'superseded_by: null',
  '---',
  'body',
].join('\n');
const { data } = parseFm(src);
const chk = [
  ['created 是字符串', typeof data.created === 'string' && data.created === '2026-07-27'],
  ['last_verified 是字符串', typeof data.last_verified === 'string'],
  ['review_after 是字符串', typeof data.review_after === 'string'],
  ['schema_version 是数字', typeof data.schema_version === 'number'],
  ['evidence 是对象且值为数字', data.evidence && data.evidence.helpful === 3 && data.evidence.harmful === 1],
  ['tags 是数组', Array.isArray(data.tags) && data.tags.length === 2],
  ['superseded_by 显式 null', data.superseded_by === null],
];
const bad = chk.filter(([, ok]) => !ok);
bad.forEach(([n]) => console.log('✗ D3: ' + n));
if (!bad.length) console.log('✓ D3: frontmatter 类型契约（日期不被静默转 Date）');
process.exit(bad.length ? 1 : 0);
" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
# 全库回归：任何一条真实条目的日期字段都不得是 Date 对象
node -e "
const { loadEntries, SCAN_DIRS } = require('$SRC/bin/evo');
process.env.EVO_ROOT = '$EVO_ROOT';
const bad = [];
for (const e of loadEntries(SCAN_DIRS)) {
  for (const k of ['created', 'last_verified', 'review_after']) {
    if (e[k] !== undefined && typeof e[k] !== 'string') bad.push(e.id + '.' + k);
  }
}
if (bad.length) console.log('✗ D3: 全库日期字段类型异常 ' + bad.slice(0, 3).join(','));
else console.log('✓ D3: 全库日期字段均为字符串');
process.exit(bad.length ? 1 : 0);
" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

# ════════════ E. R3 守护：坏 frontmatter 跳过不崩（2 + 1 清理） ════════════
echo "——— E. R3 守护：坏 frontmatter 跳过不崩 ———"
printf -- '---\nbad: [unclosed\n---\nbody\n' > "$EVO_ROOT/inbox/bad-entry.md"
t "坏条目 rebuild 不崩"    "manifest rebuilt" $EVO index rebuild
t "坏条目 recall 不崩"     "__NOOUTPUT__" $EVO recall --task test
rm -f "$EVO_ROOT/inbox/bad-entry.md"

# ════════════ F. P3：固化梯度与约束（13） ════════════
echo "——— F. P3：固化梯度与约束 ———"
t "guard allow"           '"action":"allow"' $EVO guard --tool bash --input-json '{"command":"ls"}'
mkdir -p "$EVO_ROOT/ops/constraints"
cat > "$EVO_ROOT/ops/constraints/t-block.json" << 'JSON'
{"id":"t-block","matcher":"danger-cmd","match_on":"command","message":"测试阻断","mode":"block","criteria_confirmed":true,"created":"2026-07-23"}
JSON
t "guard deny"            '"action":"deny"'  $EVO guard --tool bash --input-json '{"command":"danger-cmd x"}'
t "hook-guard deny JSON"  "permissionDecision" bash -c "echo '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"danger-cmd x\"}}' | $EVO hook-guard"
t "hook-guard 放行静默"    "__NOOUTPUT__"    bash -c "echo '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\"}}' | $EVO hook-guard"
cat > "$EVO_ROOT/ops/constraints/t-warn.json" << 'JSON'
{"id":"t-warn","matcher":"warn-cmd","match_on":"command","message":"测试告警","mode":"warn","criteria_confirmed":true,"created":"2026-07-23"}
JSON
t "guard warn 不阻断"      '"action":"warn"'  $EVO guard --tool bash --input-json '{"command":"warn-cmd x"}'
t "hook-guard warn 浮现"   "systemMessage"    bash -c "echo '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"warn-cmd x\"}}' | $EVO hook-guard"
t "hook-guard warn 不 deny" "__NEG__permissionDecision" bash -c "echo '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"warn-cmd x\"}}' | $EVO hook-guard"
# ── warn 降噪：只对命令位命中浮现（68% 的裸命中是引号内提及，噪声淹没信号）──
# 提及不浮现，但必须仍落盘 quality:'mention'——准入④的取证材料一条都不能少。
GH="$EVO_ROOT/ops/log/guard-hits.jsonl"
GB=$(grep -c . "$GH" 2>/dev/null || echo 0)
t "guard warn 引号内提及不浮现" '"action":"allow"' $EVO guard --tool bash --input-json '{"command":"git commit -m \"fix warn-cmd handling\""}'
GA=$(grep -c . "$GH" 2>/dev/null || echo 0)
{ [ "$GA" = "$((GB+1))" ] && tail -1 "$GH" | grep -q '"quality":"mention"'; } \
  && ok "F: 提及仍落盘 quality:mention（准入④取证不丢）" || bad "F: 提及落盘" "(行数 ${GB}→${GA}, 末行: $(tail -1 "$GH" | cut -c1-90))"
$EVO guard --tool bash --input-json '{"command":"warn-cmd x"}' >/dev/null 2>&1
{ tail -1 "$GH" | grep -q '"quality":"exec"'; } && ok "F: 命令位命中落盘 quality:exec" || bad "F: exec 落盘" "(末行: $(tail -1 "$GH" | cut -c1-90))"
# block 一律按裸匹配判，**不看 quality**：危险命令本就常写在引号里（bash -c "rm -rf /"），
# 按 quality 放行就是漏杀。评估侧漏判少推荐一次升级，执行侧漏判是安全事故。
cat > "$EVO_ROOT/ops/constraints/t-block2.json" << 'JSON'
{"id":"t-block2","matcher":"danger-cmd","match_on":"command","message":"测试阻断","mode":"block","criteria_confirmed":true,"created":"2026-07-29"}
JSON
t "guard block 仍拦引号内危险命令" '"action":"deny"' $EVO guard --tool bash --input-json '{"command":"bash -c \"danger-cmd /\""}'
rm -f "$EVO_ROOT/ops/constraints/t-block.json" "$EVO_ROOT/ops/constraints/t-warn.json" "$EVO_ROOT/ops/constraints/t-block2.json"
# 升 block 判据必须看命令位命中，不看裸命中：引号内提及（git commit -m '…rm -rf…'、grep）
# 混进证据会让 §8 准入④ 拿被污染的数字通过，升 block 后阻断正常命令。
mkdir -p "$EVO_ROOT/ops/constraints"
cat > "$EVO_ROOT/ops/constraints/t-fp.json" << 'JSON'
{"id":"t-fp","matcher":"rm\\s+-rf","match_on":"command","message":"测试误报","mode":"warn","criteria_confirmed":true,"created":"2026-07-27"}
JSON
for i in 1 2 3 4 5 6; do $EVO guard --tool bash --input-json '{"command":"git commit -m '"'"'fix rm -rf handling'"'"'"}' >/dev/null 2>&1; done
{ $EVO reflect 2>&1 | grep -q "不宜升 block: 约束 \[t-fp\]"; } \
  && ok "F: 全引号内提及的约束不得进升 block 候选（且结论为保持 warn，非收窄 matcher）" || bad "F: 升 block 判据" "(裸命中被当证据)"
rm -f "$EVO_ROOT/ops/constraints/t-fp.json"
# I3 人审门必须由 guard 执行，不能只写在 SKILL.md 里：agent 能直调的命令等于没有人审
# （见 playbook/approval-gate-written-only-in-prompt-is-not-enforceable）。warn 档，不阻断。
{ $EVO guard --tool bash --input-json '{"command":"evo curate --file x.md --to playbook"}' 2>&1 | grep -q 'evo-curate-needs-human'; } \
  && ok "F: curate 人审门有 guard 执行（I3 可执行化）" || bad "F: curate 人审门" "(guard 未拦 evo curate)"
{ $EVO guard --tool bash --input-json '{"command":"evo recall --task t"}' 2>&1 | grep -q '"allow"'; } \
  && ok "F: 人审门不误伤其他 evo 命令" || bad "F: 人审门误伤" "(evo recall 被拦)"
# warn 路径必须只对**命令位**命中浮现：引号内提及一律 allow。
# block 路径则**刻意**用裸匹配（bash -c "rm -rf /" 的真危险命令本就在引号里，
# 按 quality 放行=漏杀）—— 两侧不同源是设计取舍，不是不一致。这两条断言钉住 warn 侧不退化。
{ $EVO guard --tool bash --input-json '{"command":"git commit -m \"docs: 避免 rm -rf 误删\""}' 2>&1 | grep -q '"allow"'; } \
  && ok "F: 引号内提及不触发 warn（warn 只对命令位浮现）" || bad "F: 提及误报" "(commit message 里的 rm -rf 触发了 warn)"
{ $EVO guard --tool bash --input-json '{"command":"rm -rf /tmp/zz-nonexistent"}' 2>&1 | grep -q 'dangerous-rm-rf'; } \
  && ok "F: 命令位真命中仍触发 warn" || bad "F: 命令位漏报" "(rm -rf 未触发)"
# SCHEMA ⑮：related 悬挂引用比没有链接更误导，加字段必须同时有治理出口
printf -- '---\nid: zz-dangling\ntype: lesson\nstatus: candidate\ntriggers: ["悬挂探针"]\nrelated: [no-such-entry-id]\n---\n正文\n' > "$EVO_ROOT/lessons/zz-dangling.md"
{ $EVO audit 2>&1 | grep -q 'related 指向不存在的 id'; } \
  && ok "F: audit 检出悬挂 related（建链治理出口）" || bad "F: 悬挂 related" "(audit 未检出)"
rm -f "$EVO_ROOT/lessons/zz-dangling.md"
# recall() 只按 superseded_by 过滤、**不看 status**（loadEntries(RECALL_DIRS).filter(e => !e.superseded_by)），
# 所以 status 说退役、却仍留在 RECALL_DIRS 且无 superseded_by 的条目照常进每一次会话。
# 这种「状态与行为脱钩」必须被检出，否则「已退役」只是一句文案。（2026-09-14 实测 12 条）
printf -- '---\nid: zz-retired-but-injected\ntype: fact\nstatus: archived\ntriggers: ["退役注入探针"]\n---\n正文\n' > "$EVO_ROOT/facts/zz-retired-but-injected.md"
{ $EVO audit 2>&1 | grep -q '但仍在注入集'; } \
  && ok "F: audit 检出 status 退役但仍在注入集" || bad "F: 退役但仍在注入集" "(audit 未检出)"
rm -f "$EVO_ROOT/facts/zz-retired-but-injected.md"
# frontmatter 损坏是「对所有检查隐身」的根源：parseFm 静默降级，id 回退为文件名，
# 于是 status/related/triggers 全丢——该条目对 audit 每一条规则都不存在。
printf -- 'id: zz-no-status\ntype: fact\n---\n正文\n' > "$EVO_ROOT/facts/zz-no-status.md"
{ $EVO audit 2>&1 | grep -q '缺 status'; } \
  && ok "F: audit 检出缺 status（坏 frontmatter 指纹）" || bad "F: 缺 status" "(audit 未检出)"
rm -f "$EVO_ROOT/facts/zz-no-status.md"
# 无 triggers 的条目 = recall 永不命中（relevance 的主匹配源就是它）。「缺 status」那条只覆盖
# frontmatter 全坏的档；这条覆盖「frontmatter 合法但字段缺失」—— 2026-09-17 实测 4 个被 walk()
# 递归吸进 ops/proposals 的嵌套报告 .md 就属此类，且在治理视图里完全隐形。
printf -- '---\nid: zz-no-triggers\ntype: fact\nstatus: validated\n---\n正文\n' > "$EVO_ROOT/facts/zz-no-triggers.md"
{ $EVO audit 2>&1 | grep -q '无 triggers'; } \
  && ok "F: audit 检出无 triggers 条目（永不命中的静默条目）" || bad "F: 无 triggers" "(audit 未检出)"
rm -f "$EVO_ROOT/facts/zz-no-triggers.md"
# 检索基准的契约：跑得起来、四阶段齐全、且**不写真实 ops/log**（recall.jsonl 是 §7.1 精度与
# §5.0 回放的数据源，基准查询混进去会污染判据）。此处不守护阈值——阈值要先有基线才能定。
BENCH_BEFORE=$(wc -l < "$SRC/ops/log/recall.jsonl" 2>/dev/null || echo 0)
BENCH_OUT=$(node "$SRC/test/retrieval-bench/bench.js" 2>&1)
BENCH_AFTER=$(wc -l < "$SRC/ops/log/recall.jsonl" 2>/dev/null || echo 0)
{ echo "$BENCH_OUT" | grep -q '| transfer |' && echo "$BENCH_OUT" | grep -q '| change |'; } \
  && ok "M: 检索基准四阶段可跑" || bad "M: 检索基准" "(实得: $(echo "$BENCH_OUT" | tail -1))"
{ [ "$BENCH_BEFORE" = "$BENCH_AFTER" ]; } \
  && ok "M: 基准不污染 recall.jsonl（测量与被测数据隔离）" || bad "M: 基准日志隔离" "($BENCH_BEFORE → $BENCH_AFTER 行)"
# §5.0 回放仲裁工具必须可跑，且必须同样不污染真实日志 —— 它把「丢失清单逐条人审」里
# 最可机械化的那一半（给每条丢失附对账精度）自动化了，是评分变更的前置依据。
RPL_BEFORE=$(wc -l < "$SRC/ops/log/recall.jsonl" 2>/dev/null || echo 0)
RPL_OUT=$(node "$SRC/test/retrieval-bench/replay.js" v0 v3 --limit 5 2>&1)
RPL_AFTER=$(wc -l < "$SRC/ops/log/recall.jsonl" 2>/dev/null || echo 0)
{ echo "$RPL_OUT" | grep -q '注入集完全一致' && echo "$RPL_OUT" | grep -q '丢失 Top'; } \
  && ok "M: §5.0 回放工具可跑（--limit 5 冒烟）" || bad "M: 回放工具" "(实得: $(echo "$RPL_OUT" | tail -1))"
{ [ "$RPL_BEFORE" = "$RPL_AFTER" ]; } \
  && ok "M: 回放不污染 recall.jsonl（在临时 ROOT 副本里跑）" || bad "M: 回放日志隔离" "($RPL_BEFORE → $RPL_AFTER 行)"
# 穷举盲标评测器必须能跑出**非零**的两数。曾经的失败模式：根目录路径算错 ⇒ 临时 ROOT 为空
# ⇒ 所有 query 零注入 ⇒ 两数全 0，而输出看起来"正常"。所以这里不只查"能跑"，还查"有注入"。
EV_BEFORE=$(wc -l < "$SRC/ops/log/recall.jsonl" 2>/dev/null || echo 0)
EV_OUT=$(node "$SRC/test/retrieval-bench/labeling/run-eval.js" 2>&1)
EV_AFTER=$(wc -l < "$SRC/ops/log/recall.jsonl" 2>/dev/null || echo 0)
{ echo "$EV_OUT" | grep -q 'precision' && echo "$EV_OUT" | grep -q 'recall'; } \
  && ok "M: 盲标评测器可跑（同时报 precision 与 recall）" || bad "M: 盲标评测器" "(实得: $(echo "$EV_OUT" | tail -1))"
{ echo "$EV_OUT" | grep -qE '命中 [1-9][0-9]* ·'; } \
  && ok "M: 评测器环境正确（有非零注入，非空 ROOT 假象）" || bad "M: 评测器环境" "(命中 0 ⇒ 先查临时 ROOT 是否搭起来了，别先怀疑被测系统)"
{ [ "$EV_BEFORE" = "$EV_AFTER" ]; } \
  && ok "M: 评测器不污染 recall.jsonl" || bad "M: 评测器日志隔离" "($EV_BEFORE → $EV_AFTER 行)"
# K0a primer：安装是替换标记块而非覆盖用户配置——必须保住目标文件里的原有内容。
# 这两个文件是用户自己的全局配置，写坏了影响每一次会话。
PT="$TMP/primer-target.md"
printf '# 我自己的配置\n\n## 重要章节\n不能被覆盖\n' > "$PT"
node -e "
const fs=require('fs');
const pm=fs.readFileSync('$SRC/primer.md','utf8');
const blk=pm.match(/<!-- PRIMER:BEGIN -->\n[\s\S]*?<!-- PRIMER:END -->/)[0];
let cur=fs.readFileSync('$PT','utf8');
// 复刻 primer --install 的拼接语义：无标记则追加
const next=/<!-- PRIMER:BEGIN -->/.test(cur)?cur.replace(/<!-- PRIMER:BEGIN -->\n[\s\S]*?<!-- PRIMER:END -->/,blk):(cur.trimEnd()+'\n\n'+blk+'\n');
fs.writeFileSync('$PT',next);
// 二次安装应幂等
let c2=fs.readFileSync('$PT','utf8');
const n2=c2.replace(/<!-- PRIMER:BEGIN -->\n[\s\S]*?<!-- PRIMER:END -->/,blk);
fs.writeFileSync('$PT',n2);
"
{ grep -q '不能被覆盖' "$PT" && grep -q '用户画像与活跃领域' "$PT" \
  && [ "$(grep -c 'PRIMER:BEGIN' "$PT")" = "1" ]; } \
  && ok "primer 安装保留原有内容且幂等（不重复插块）" || bad "primer 安装" "(覆盖了用户配置或重复插块)"
t "primer 输出含标记块"    "PRIMER:BEGIN" $EVO primer
t "solidify 缺参数提示"    "usage" $EVO solidify
t "solidify 无matcher拒绝" "matcher" $EVO solidify --id arxiv-api-rate-limit --to hook
t "demote 未知条目"        "✗" $EVO demote --id not-exist --to archive
t "curate 缺字段拒绝"      "✗" bash -c "printf -- '---\nid: bad\n---\nx\n' > $TMP/bad.md && $EVO curate --file $TMP/bad.md --to lessons"
# 状态机：curate 到 validated 区必须置 status: validated（SCHEMA 状态机节）。
# 不改写的话 status 与所在区脱节，reflect 的 by-status 统计与 audit 状态规则读到假数据。
printf -- '---\nid: zz-status-probe\ntype: lesson\nstatus: candidate\ntriggers: ["状态机探针"]\n---\n正文\n' > "$TMP/statusprobe.md"
$EVO curate --file "$TMP/statusprobe.md" --to playbook >/dev/null 2>&1
{ grep -q '^status: validated' "$EVO_ROOT/playbook/statusprobe.md"; } \
  && ok "curate 入 validated 区改写 status" || bad "curate status 改写" "(实得: $(grep -m1 '^status:' "$EVO_ROOT/playbook/statusprobe.md" 2>&1))"
printf -- '---\nid: zz-status-probe2\ntype: lesson\nstatus: candidate\ntriggers: ["状态机探针2"]\n---\n正文\n' > "$TMP/statusprobe2.md"
$EVO curate --file "$TMP/statusprobe2.md" --to lessons >/dev/null 2>&1
{ grep -q '^status: candidate' "$EVO_ROOT/lessons/statusprobe2.md"; } \
  && ok "curate 入 lessons 保持 candidate（不误升级）" || bad "curate lessons status" "(实得: $(grep -m1 '^status:' "$EVO_ROOT/lessons/statusprobe2.md" 2>&1))"
rm -f "$EVO_ROOT/playbook/statusprobe.md" "$EVO_ROOT/lessons/statusprobe2.md"
# 提交边界：curate 只能暂存自己动过的文件。原先 git add -A 会把工作区里一切无关改动
# （后台蒸馏刚写的提案、别人在改的代码、临时探针）一并提交并 push。
( cd "$EVO_ROOT" && git init -q 2>/dev/null; git add -A >/dev/null 2>&1; git -c user.email=t@t -c user.name=t commit -qm base >/dev/null 2>&1 ) || true
echo "无关的脏文件" > "$EVO_ROOT/UNRELATED-DIRTY.txt"
printf -- '---\nid: zz-scope-probe\ntype: lesson\nstatus: candidate\ntriggers: ["提交边界探针"]\n---\n正文\n' > "$TMP/scopeprobe.md"
( cd "$EVO_ROOT" && $EVO curate --file "$TMP/scopeprobe.md" --to playbook >/dev/null 2>&1 )
{ ( cd "$EVO_ROOT" && git status --porcelain UNRELATED-DIRTY.txt 2>/dev/null | grep -q '??' ); } \
  && ok "curate 不卷入无关文件（提交边界）" || bad "curate 提交边界" "(无关脏文件被一起提交)"
rm -f "$EVO_ROOT/UNRELATED-DIRTY.txt" "$EVO_ROOT/playbook/scopeprobe.md"
# curate 的 commit 必须**真的成功**。提案文件从未被 git 跟踪，被 curate 移走后其路径既不存在
# 也无历史，若仍传给 git add 会让整批 add fatal(128) → 一个都暂存不上 → commit 失败 → gitPush()
# 够不着 → 部署门① 的自动 push 静默失效。实盘发生过：连续 4 次 curate 全部未提交、ahead 4 未推送。
# 上面的「提交边界」用例抓不到它：那个探针提案写在 $TMP（ROOT 之外），add 本就 fatal，
# 于是"无关文件没被卷入"因整批提交失败而平凡成立——它通过了，但是为错误的原因通过的。
printf -- '---\nid: zz-commit-probe\ntype: lesson\nstatus: candidate\ntriggers: ["提交成功探针"]\n---\n正文\n' > "$EVO_ROOT/ops/proposals/zz-commit-probe.md"
( cd "$EVO_ROOT" && $EVO curate --file ops/proposals/zz-commit-probe.md --to playbook >/dev/null 2>&1 )
{ ( cd "$EVO_ROOT" && git log -1 --pretty=%s 2>/dev/null | grep -q 'zz-commit-probe' ); } \
  && ok "curate 未跟踪提案仍能成功 commit" || bad "curate commit（未跟踪提案）" "(实得 HEAD: $( cd "$EVO_ROOT" && git log -1 --pretty=%s 2>&1 ))"
rm -f "$EVO_ROOT/playbook/zz-commit-probe.md"
# 空提交容错分支：git commit 把 "no changes added to commit" 写到 **stdout**，而 execSync 抛出的
# e.message 只含 stderr——原先只查 e.message，该容错从未生效过（此分支原先无用例，pi 独立评审指出）。
#
# 必须用 solidify --to hook 构造，不能用 curate：curate 每次都 rebuild，而 manifest 头部带
# `# rebuilt: <ISO 时间戳>`，**每次重建必产生 diff** → 经 curate 永远到不了"无可提交"。
# （这也解释了为何这条容错坏了很久却无可见伤害：它守的场景在主路径上根本不发生。）
# solidify --to hook 只提交 constraint json、不带 manifest，同 id 同日重跑内容字节一致 → 空提交。
# 观测点用降级事件而非命令输出：solidify 不检查 gitCommitWithRetry 返回值，输出分不出成败。
SOL_ARGS=(--id macos-no-timeout-command --to hook --matcher zz-probe-matcher --criteria-confirmed)
( cd "$EVO_ROOT" && $EVO solidify "${SOL_ARGS[@]}" >/dev/null 2>&1 )
( cd "$EVO_ROOT" && $EVO solidify "${SOL_ARGS[@]}" >/dev/null 2>&1 )
# 断言须锚到本用例的 commit message：degrade.jsonl 里还有更早的无关事件——第 222 行的
# zz-status-probe2 curate 跑在 git init 之前，当时无仓库，记降级是 fail-open 的正常行为。
{ ! grep -q 'solidify: macos-no-timeout-command' "$EVO_ROOT/ops/log/degrade.jsonl" 2>/dev/null; } \
  && ok "空提交（无实际变更）判成功，不记降级" || bad "空提交容错" "(实得降级: $(grep 'solidify: macos-no-timeout-command' "$EVO_ROOT/ops/log/degrade.jsonl" 2>/dev/null | grep -o '"reason":"[^"]*' | tail -1))"
rm -f "$EVO_ROOT/ops/constraints/macos-no-timeout-command.json"
t "curate 文件缺失"        "✗ 提案不存在" $EVO curate --file /nonexistent.md --to lessons
t "slice 命令↔结果对齐"    "↳ total 42" $EVO slice --session "$SRC/test/fixtures/sample-session.jsonl"
t "slice Claude 命令↔结果"  "↳ total 42" $EVO slice --session "$SRC/test/fixtures/sample-session-claude.jsonl"
t "slice Claude 写文件"     "/tmp/evo-slice-demo.txt" $EVO slice --session "$SRC/test/fixtures/sample-session-claude.jsonl"
# 工具名与字段名是 per-harness 的，不能只测一两套（见 playbook/…-evo-slice-normalize-
# toolname-case-and-path-field）。Hermes 是第三套：单行 JSON + messages[] 嵌套，
# 工具调用为 OpenAI 形态 tool_calls[].function.{name,arguments(JSON 字符串)}，
# 工具名为 terminal / write_file，结果在 role:'tool' 里。不测它就无法发现它整段不可读——
# 而二期接 Hermes hooks 的先决条件正是 slice 能读它的 transcript。
# 注意期望值：Pi/Claude 的 toolResult content 是裸文本（`↳ total 42`），
# 而 Hermes 的 role:'tool' content 是**结果 JSON 本体**（`↳ {"output":"total 42",...}`），
# 所以这里只能断言结果里的关键串，不能照搬 Pi 那条的形态。
t "slice Hermes 命令↔结果"  "total 42" $EVO slice --session "$SRC/test/fixtures/sample-session-hermes.jsonl"
t "slice Hermes 写文件"     "/tmp/evo-slice-demo.txt" $EVO slice --session "$SRC/test/fixtures/sample-session-hermes.jsonl"

# ════════════ G. YAML 边界 fixture（M0.1，R3 盲区 round-trip） ════════════
echo "——— G. YAML 边界 fixture（parseFm round-trip） ———"
node -e "
const { parseFm } = require('$SRC/bin/evo');
const cases = [
  ['多行块标量', '---\nid: a\ndesc: |\n  line1\n  line2\n---\nx', (d) => (d.desc||'').includes('line1') && (d.desc||'').includes('line2')],
  ['含冒号引号值', '---\nid: b\nnote: \"a: b\"\n---\nx', (d) => d.note === 'a: b'],
  ['嵌套对象', '---\nid: c\nevidence: {helpful: 3, harmful: 0}\n---\nx', (d) => d.evidence && d.evidence.helpful===3 && d.evidence.harmful===0],
  ['null/~ 显式空值', '---\nid: d\na: null\nb: ~\n---\nx', (d) => d.a===null && d.b===null],
  ['数组单行', '---\nid: e\ntags: [rest, versioning]\n---\nx', (d) => Array.isArray(d.tags) && d.tags.length===2 && d.tags[0]==='rest'],
  ['数组多行', '---\nid: f\ntags:\n  - x\n  - y\n---\nbody', (d) => Array.isArray(d.tags) && d.tags.length===2 && d.tags[1]==='y'],
  ['schema_version 缺省=1', '---\nid: g\n---\nx', (d) => d.schema_version===1],
  ['schema_version 显式=1', '---\nid: h\nschema_version: 1\n---\nx', (d) => d.schema_version===1],
];
let bad=0;
for (const [name,src,check] of cases) {
  try { const { data } = parseFm(src); if (check(data)) { console.log('✓ G: '+name); } else { console.log('✗ G: '+name+' (check failed: '+JSON.stringify(data)+')'); bad++; } }
  catch (e) { console.log('✗ G: '+name+' (threw: '+e.message+')'); bad++; }
}
process.exit(bad===0?0:1);
" && PASS=$((PASS+8)) || { echo "✗ G: YAML fixture 组有失败（见上）"; FAIL=$((FAIL+1)); }

# ════════════ H. 不变量守护（I1–I7 + §5.0 权重恒等） ════════════
echo "——— H. 不变量守护（I1–I7） ———"
# I2: inbox 条目不注入
printf -- '---\nid: i2-inbox-trap\ntype: note\nstatus: inbox\ntriggers:\n  - "arxiv 下载陷阱"\n---\nI should never be injected\n' > "$EVO_ROOT/inbox/i2-inbox-trap.md"
t "I2 inbox 不注入" "__NEG__i2-inbox-trap" $EVO recall --task "arxiv 下载"
rm -f "$EVO_ROOT/inbox/i2-inbox-trap.md"
# I2: lessons candidate 不注入
printf -- '---\nid: i2-lessons-trap\ntype: lesson\nstatus: candidate\ntriggers:\n  - "arxiv 下载陷阱"\n---\nI should never be injected from lessons\n' > "$EVO_ROOT/lessons/i2-lessons-trap.md"
t "I2 lessons 不注入" "__NEG__i2-lessons-trap" $EVO recall --task "arxiv 下载"
# I2: candidate 即使住在 RECALL_DIRS 内也不注入 —— I2 的声明是「inbox/ 与 candidate
# 永不进自动注入通道」，是按 **status** 而非仅按 zone。2026-09-14 实测本机有 10 条
# candidate 住在 facts/playbook/episodes 里并被实际注入，是声明与实现脱钩；
# 原实现只读 RECALL_DIRS + 排 superseded_by，没有 status 过滤。
printf -- '---\nid: i2-candidate-in-recall-dir\ntype: fact\nstatus: candidate\ntriggers:\n  - "候选态在注入区内也不应注入"\n---\nI should never be injected despite living in a RECALL_DIR\n' > "$EVO_ROOT/facts/i2-candidate-in-recall-dir.md"
t "I2 candidate 在 RECALL_DIR 内不注入" "__NEG__i2-candidate-in-recall-dir" $EVO recall --task "候选态在注入区内"
rm -f "$EVO_ROOT/facts/i2-candidate-in-recall-dir.md"
# I2: superseded 排除（设 superseded_by 后不再命中）
printf -- '---\nid: i2-superseded\ntype: bullet\nstatus: validated\ntriggers:\n  - "superseded 不应注入"\nsuperseded_by: skill:fake\n---\nretired\n' > "$EVO_ROOT/playbook/i2-superseded.md"
t "I2 superseded 排除" "__NEG__i2-superseded" $EVO recall --task "superseded"
rm -f "$EVO_ROOT/playbook/i2-superseded.md"
# I5: 派生索引可重建（删 manifest → rebuild → count 一致）
rm -f "$EVO_ROOT/index/manifest.yaml"
$EVO index rebuild >/dev/null 2>&1
{ [ -f "$EVO_ROOT/index/manifest.yaml" ] && grep -q '^count:' "$EVO_ROOT/index/manifest.yaml"; } && ok "I5 索引可重建（manifest 再生）" || bad "I5 索引可重建" "(manifest 未再生)"
# §5.0 权重恒等：治理权重三因子与后端无关（govWeight 不取 backend 参数 → 升级只换召回层）
node -e "
const { govWeight, VERIFIED_W } = require('$SRC/bin/evo');
const e = { type:'bullet', verified_by:'command', evidence:{helpful:3,harmful:0} };
const w = govWeight(e);
// 手算期望：verified_w(command=0.8) × max(0.3, ln(1+3)) × typeW(1.0)
const exp = VERIFIED_W.command * Math.max(0.3, Math.log(4)) * 1.0;
const ok = Math.abs(w-exp) < 1e-9;
console.log(ok ? '✓ §5.0 权重恒等（治理权重=verified_w×evW×typeW，与后端无关）' : '✗ §5.0 权重恒等 ('+w+' vs '+exp+')');
process.exit(ok?0:1);
" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
# I1: fail-open 全命令（EVO_ROOT 缺失各命令均 exit 0）— 扩展 C 组到全命令
I1OK=1
for c in "capture x" "recall --task y" "candidates" "index rebuild" "audit" "inbox" "get --ids z" "reflect"; do
  EVO_ROOT=/nonexistent-xyz $EVO $c >/dev/null 2>&1 || { I1OK=0; break; }
done
{ [ $I1OK -eq 1 ]; } && ok "I1 fail-open 全命令（EVO_ROOT 缺失均 exit0）" || bad "I1 fail-open 全命令" "(某命令非零退出)"
# ROOT 自定位（不设 EVO_ROOT，CLI 用 bin/evo 父目录）
unset EVO_ROOT
OUT=$("$SRC/bin/evo" recall --task "arxiv 论文下载" 2>&1)
{ echo "$OUT" | grep -q "evo-recall"; } && ok "ROOT 自定位（EVO_ROOT 未设时 CLI 自定位仓库根）" || bad "ROOT 自定位" "(recall 无输出: ${OUT:0:50})"
export EVO_ROOT="$TMP/kernel"
# I7: git 写序列化——在 git-enabled ROOT 跑一次 solidify 成功路径，验证 commit+retry 包装不崩
HROOT="$TMP/i7root"; mkdir -p "$HROOT"
rsync -a --exclude .git --exclude node_modules "$SRC/" "$HROOT/" 2>/dev/null
ln -s "$SRC/node_modules" "$HROOT/node_modules" 2>/dev/null
( cd "$HROOT" && git init -q && git add -A && git commit -qm init >/dev/null 2>&1 )
I7OUT=$(EVO_ROOT="$HROOT" "$SRC/bin/evo" solidify --id arxiv-api-rate-limit --to skill 2>&1)
{ echo "$I7OUT" | grep -q "skills/arxiv-api-rate-limit"; } && ok "I7 git 写序列化（solidify commit+retry 路径成功）" || bad "I7 git 写序列化" "(实得: ${I7OUT:0:80})"

# ════════════ I. session-refs JSONL（M0.2 结构化） ════════════
echo "——— I. session-refs JSONL（M0.2） ———"
# 写 JSONL（存在的 transcript 路径 → 真实路径）
REALF="$TMP/real-session.jsonl"; printf 'hello\n' > "$REALF"
$EVO session-end --session "$REALF" --id sess-real >/dev/null 2>&1
# 哨兵保留（不存在的路径 → transcript:'?'）
$EVO session-end --session "/nonexistent/xyz.jsonl" --id sess-sentinel >/dev/null 2>&1
node -e "
const fs=require('fs');
const lines=fs.readFileSync('$EVO_ROOT/inbox/session-refs.jsonl','utf8').trim().split('\n').map(JSON.parse);
const real=lines.find(l=>l.session==='sess-real');
const sent=lines.find(l=>l.session==='sess-sentinel');
let bad=0;
if(!real||real.transcript!=='$REALF'){console.log('✗ I: 写JSONL 真实路径缺失/错误');bad++;}
if(!sent||sent.transcript!=='?'){console.log('✗ I: 哨兵保留（transcript=?）失败');bad++;}
// 只校刚写的两行：distilled 是可变字段（mark-distilled 回写 true），不能拿全文件断言
if(![real,sent].every(l=>l&&l.harness&&l.distilled===false)){console.log('✗ I: schema 字段不全');bad++;}
if(bad===0) console.log('✓ I: session-refs.jsonl 写入/哨兵/schema 全部正确');
process.exit(bad===0?0:1);
" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
# inbox 渲染 refs 计数（= JSONL 行数，不硬编码）。2026-09-17 起总数后附「可蒸馏/已失」拆分——
# 只报总数的旧形态会让人以为队列比实际大 3–4 倍（559 里有 366 条 transcript 已失）。
REFSLINES=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl" 2>/dev/null || echo 0)
REFS_OUT=$($EVO inbox 2>&1)
{ echo "$REFS_OUT" | grep -q "$REFSLINES 条会话登记"; } && ok "I: inbox 渲染 refs 计数（= JSONL 行数）" || bad "I: inbox 渲染 refs 计数" "(期望 $REFSLINES 条, 实得: ${REFS_OUT:0:60})"

# ── 登记前移 + upsert（依据：51.7% 的注入实例落在从未登记的 session 上，SessionEnd 会漏）──
LIVE="$TMP/live-transcript.jsonl"; echo '{"role":"user"}' > "$LIVE"
B4=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
echo "{\"session_id\":\"sess-live\",\"prompt\":\"arxiv 论文下载\",\"transcript_path\":\"$LIVE\"}" | $EVO hook-recall >/dev/null 2>&1
A1=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
{ [ "$A1" = "$((B4+1))" ] && grep -q '"session":"sess-live"' "$EVO_ROOT/inbox/session-refs.jsonl"; } \
  && ok "I: 登记前移（首次 hook-recall 即登记，不等 SessionEnd）" || bad "I: 登记前移" "(行数 ${B4}→${A1})"
# 二次 hook-recall 不得新增行（upsert 幂等；append 会虚增哨兵率与蒸馏节律分母）
echo "{\"session_id\":\"sess-live\",\"prompt\":\"另一个问题\",\"transcript_path\":\"$LIVE\"}" | $EVO hook-recall >/dev/null 2>&1
A2=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
{ [ "$A2" = "$A1" ]; } && ok "I: 登记 upsert 幂等（同 session 不产生第二行）" || bad "I: 登记 upsert 幂等" "(${A1}→${A2})"
# 哨兵升级：先登记不存在的路径（'?'），再带真实路径登记 → 同一行升级，行数不变
$EVO session-end --session "/nonexistent/later.jsonl" --id sess-upgrade >/dev/null 2>&1
U1=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
$EVO session-end --session "$LIVE" --id sess-upgrade >/dev/null 2>&1
U2=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
{ [ "$U2" = "$U1" ] && grep '"session":"sess-upgrade"' "$EVO_ROOT/inbox/session-refs.jsonl" | grep -q "$LIVE"; } \
  && ok "I: 哨兵行可被真实路径升级（单向，行数不变）" || bad "I: 哨兵升级" "(行数 ${U1}→${U2})"
# queue 静默期：未见 SessionEnd 且 transcript 刚写过 → 不入队（防蒸馏半截会话）
Q_LIVE=$($EVO queue --min-bytes 0 | grep -c "sess-live" || true)
Q_ENDED=$($EVO queue --min-bytes 0 --quiet-min 0 | grep -c "sess-live" || true)
{ [ "$Q_LIVE" = "0" ] && [ "$Q_ENDED" = "1" ]; } \
  && ok "I: queue 静默期挡住在跑会话（ended=false 且 mtime 新）" || bad "I: queue 静默期" "(静默期内 $Q_LIVE 条, 关闭静默期 $Q_ENDED 条)"
# ended=true（SessionEnd 到过）应立刻入队——否则 SessionEnd 触发器压缩腐烂窗口的效果就没了
{ [ "$($EVO queue --min-bytes 0 | grep -c 'sess-upgrade' || true)" = "1" ]; } \
  && ok "I: ended=true 绕过静默期立刻入队（保住 SessionEnd 触发器）" || bad "I: ended 立刻入队" "(未入队)"

# ════════════ J. reconcile（M0.4 对账通道·I4 单点写） ════════════
echo "——— J. reconcile（M0.4 对账通道·I4） ———"
# 模拟 Reflector 写四态行（adopted + misleading）
mkdir -p "$EVO_ROOT/ops/log"
cat >> "$EVO_ROOT/ops/log/reconcile.jsonl" << JSONL
{"ts":"2026-07-24T10:00:00.000Z","session":"s1","id":"arxiv-api-rate-limit","task":"","state":"adopted","helpful_delta":1,"harmful_delta":0,"judged_by":"reflector"}
{"ts":"2026-07-24T10:00:01.000Z","session":"s2","id":"arxiv-api-rate-limit","task":"","state":"misleading","helpful_delta":0,"harmful_delta":1,"judged_by":"reflector"}
{"ts":"2026-07-24T10:00:02.000Z","session":"s3","id":"arxiv-api-rate-limit","task":"","state":"relevant-unused","helpful_delta":0,"harmful_delta":0,"judged_by":"reflector"}
JSONL
# 三个 session 必须不同：同 session 同 id 的三条会被去重读法折成最后一条（留最后一次），
# 那是精度侧的正确语义；本组验的是 **delta 累加**，所以用三个独立 session 各记一笔。
# rebuild 聚合 delta（base helpful=3+1=4, harmful=0+1=1）
$EVO index rebuild >/dev/null 2>&1
{ grep -A10 'id: arxiv-api-rate-limit' "$EVO_ROOT/index/manifest.yaml" | grep -q 'helpful: 4' && grep -A10 'id: arxiv-api-rate-limit' "$EVO_ROOT/index/manifest.yaml" | grep -q 'harmful: 1'; } && ok "J: rebuild 聚合 reconcile delta（helpful+1/harmful+1）" || bad "J: rebuild 聚合 delta" "(manifest 未反映累计)"
# 精度计算（reflect 判据对照表）：断言算出来的**数**，不是断言表格标题在不在。
# 只 grep 标题的旧断言会在分子分母算错时照样通过（见 lessons/test-may-pass-for-the-wrong-reason）。
REFL_OUT=$($EVO reflect 2>&1)
# 期望值必须与 CLI **同口径**：① 扣掉 agentic 通道行（reflect 的 M1 行是词法通道专有，两条通道分开算，
# 见 playbook/injection-precision-must-split-recall-vs-adoption）；② 同 (session,id,channel) 去重留最后一条
# （重试重写不得双计，2026-09-16 加）。直算原始行数会在有重复或 agentic 行时系统性偏高——
# 两种偏差各自都实测过：259/103 vs 257/102（agentic 2 行，2026-09-15）、368/123 vs 297/101（重复 69 条，2026-09-16）。
DEDUP_NUM=$(node -e "
const fs=require('fs');const seen=new Map();const nullRows=[];
for(const l of fs.readFileSync('$EVO_ROOT/ops/log/reconcile.jsonl','utf8').split('\n')){
  if(!l.trim())continue;let j;try{j=JSON.parse(l)}catch{continue}
  if((j.channel||'recall')==='agentic')continue;
  if(j.session)seen.set(j.session+'\u0000'+(j.id||'')+'\u0000'+(j.channel||'recall'),j);else nullRows.push(j);
}
let n=0,rel=0;for(const j of nullRows.concat([...seen.values()])){n++;if(j.state==='adopted'||j.state==='relevant-unused')rel++}
console.log(rel+' '+n);")
RELN=${DEDUP_NUM%% *}; RECN=${DEDUP_NUM##* }
PREC=$(node -e "console.log(Math.round($RELN/$RECN*100))")
{ echo "$REFL_OUT" | grep -q "M1 召回精度（检索层） | ${PREC}%（${RELN}/${RECN}）"; } \
  && ok "J: 精度计算（召回精度 = ${PREC}%（${RELN}/${RECN}），按实际四态算）" \
  || bad "J: 精度计算" "(期望 ${PREC}%（${RELN}/${RECN}）, 实得: $(echo "$REFL_OUT" | grep 'M1 召回精度'))"
# §7.1 对账覆盖率的分母是**注入实例数**（Σ|ids|），不是 recall 调用数——用调用数当分母会虚高数倍。
# 2026-09-14 起拆为两行：可对账域（真·纪律指标）+ 结构性不可对账（transcript 被保留期清掉的永久损失）。
# 后者必须用全量实例数当分母，否则那些永远拿不到证据的实例会被算成「纪律没做」。分母从 recall.jsonl 现算，不硬编码。
INST=$(node -e "
const fs=require('fs');let n=0;
for(const l of fs.readFileSync('$EVO_ROOT/ops/log/recall.jsonl','utf8').split('\n')){
  if(!l.trim())continue; try{const j=JSON.parse(l); n+=(j.ids||[]).length;}catch{}
}
console.log(n);")
{ echo "$REFL_OUT" | grep -q "M1 结构性不可对账 | [0-9]*/${INST}（[0-9]*%）"; } \
  && ok "J: 结构性不可对账以全量实例数为分母（${INST}）" \
  || bad "J: 结构性不可对账分母" "(期望分母 ${INST}，实得: $(echo "$REFL_OUT" | grep '结构性不可对账'))"
{ echo "$REFL_OUT" | grep -q "M1 对账覆盖率（可对账域） | .*（${RECN}/[0-9]*）"; } \
  && ok "J: 对账覆盖率按可对账域计算（分子 ${RECN}）" \
  || bad "J: 对账覆盖率（可对账域）" "(实得: $(echo "$REFL_OUT" | grep '对账覆盖率'))"
# 旧口径单行必须消失：残留即意味着结构性损失又回到了纪律分母里
{ echo "$REFL_OUT" | grep -q "| M1 对账覆盖率 | "; } \
  && bad "J: 旧对账覆盖率口径残留" "(仍是单行全量分母)" || ok "J: 旧对账覆盖率口径已无残留"
# J: 对账去重 —— 重试重写的同一 (session,id,channel) 只算最后一条。
# 2026-09-16 实例：蒸馏被 kill/网络失败后重跑会重写同一批对账（068d 一例 18 条；
# 全库实测重复 69/364 —— 不去重时精度 99/364=27%，去重后 99/295=34%）—— 不设守护就会静默回来。
cat >> "$EVO_ROOT/ops/log/reconcile.jsonl" << JSONL
{"ts":"2026-09-16T00:00:00.000Z","session":"sDUP","id":"dup-fixture-nonexistent","state":"adopted","helpful_delta":1,"harmful_delta":0,"judged_by":"reflector"}
{"ts":"2026-09-16T00:00:01.000Z","session":"sDUP","id":"dup-fixture-nonexistent","state":"irrelevant","helpful_delta":0,"harmful_delta":0,"judged_by":"reflector"}
JSONL
DEDUP=$(node -e "
const fs=require('fs');const seen=new Map();const nullRows=[];
for(const l of fs.readFileSync('$EVO_ROOT/ops/log/reconcile.jsonl','utf8').split('\n')){
  if(!l.trim())continue;let j;try{j=JSON.parse(l)}catch{continue}
  if((j.channel||'recall')==='agentic')continue;
  if(j.session)seen.set(j.session+'\u0000'+(j.id||'')+'\u0000'+(j.channel||'recall'),j);else nullRows.push(j);
}
let n=0,rel=0;for(const j of nullRows.concat([...seen.values()])){n++;if(j.state==='adopted'||j.state==='relevant-unused')rel++}
console.log(rel+'/'+n);")
{ $EVO reflect 2>&1 | grep -q "M1 召回精度（检索层） | .*%（${DEDUP}）"; } \
  && ok "J: 对账去重（同 (session,id,channel) 只算最后一条，${DEDUP}）" \
  || bad "J: 对账去重" "(期望 ${DEDUP}，实得: $($EVO reflect 2>&1 | grep 'M1 召回精度'))"
# §7.1 精度必须拆两个数：relevant-unused 计入召回精度分子、但不计入采纳率分子。
# 合成一个数会让指标对 harness-benefit（召回对了却没被用上）完全不敏感。
{ echo "$REFL_OUT" | grep -q "采纳率（应用层"; } \
  && ok "J: 采纳率与召回精度拆开呈报（harness-benefit 可见）" || bad "J: 采纳率拆分" "(判据表无采纳率行)"
# reconcile 写入校验（schema 合法）
node -e "
const fs=require('fs');
const lines=fs.readFileSync('$EVO_ROOT/ops/log/reconcile.jsonl','utf8').trim().split('\n');
let bad=0;
for(const l of lines){const j=JSON.parse(l);if(!j.id||!(j.helpful_delta>=0)||!(j.harmful_delta>=0)||!j.judged_by){console.log('✗ J: reconcile schema 非法');bad++;break;}}
if(bad===0) console.log('✓ J: reconcile.jsonl schema 合法（I4 单点写）');
process.exit(bad===0?0:1);
" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

# 空转退役（§7.2）：注入够多次却 adopted=0 → reflect 列退役候选。
# 这是库的唯一自动出口——irrelevant/relevant-unused 的 delta 都是 (0,0)，在 evidence
# 汇总里惰性，够不着 harmful>0 那条线，所以判据必须直接读 reconcile.jsonl 原始四态。
# 必须挑 J 组上面没 seed 过 adopted 的 id，否则第一条断言恒假、第二条恒真（空过）
DEADID=seed-failure-lessons-as-templates
for i in 1 2 3 4 5; do $EVO reconcile --ids $DEADID --state irrelevant >/dev/null 2>&1; done
RF=$($EVO reflect 2>&1)
{ echo "$RF" | grep -q "退役候选（低精度）: \[$DEADID\]"; } \
  && ok "J: 低精度条目进退役候选（adopted=0 且 precision<50% 且 n≥5）" || bad "J: 低精度退役" "(reflect 无该候选)"
# 有采用记录的条目不能被误判退役：同 id 补一条 adopted 后应立即移出候选
$EVO reconcile --ids $DEADID --state adopted >/dev/null 2>&1
{ ! $EVO reflect 2>&1 | grep -q "退役候选（低精度）: \[$DEADID\]"; } \
  && ok "J: adopted≥1 即豁免低精度退役（不误杀活条目）" || bad "J: 低精度退役误杀" "(adopted 后仍在候选)"
# 提案幂等：demote 之后条目落到 lessons/（**仍在 SCAN_DIRS 内**），判据若不限定
# 「当前在注入集内」，下一轮 reflect 会把同一条原样再提一遍——提案永久重复。
# 指纹：同批 solidify 落 ops/archive（不在 SCAN_DIRS）而正确地消失；这个不对称即判据缺 zone 检查。
mv "$EVO_ROOT/playbook/seed-failure-lessons-as-templates.md" "$EVO_ROOT/lessons/"
{ ! $EVO reflect 2>&1 | grep -q "退役候选（低精度）: \[$DEADID\]"; } \
  && ok "J: 已出注入集的条目不进退役候选（demote 幂等）" || bad "J: 提案幂等" "(已移入 lessons 仍被提议)"
# 判定者校准结果必须可持久化并被读回：此前该判据行写死「待人工抽≥10例复核 ⚠ 见下方校准」，
# 而报告里从来没有校准段 —— 提示指向不存在的目标。
{ $EVO reflect 2>&1 | grep -q '## 判定者校准'; } \
  && ok "J: reflect 渲染判定者校准段（读 ops/judge-calibration.json）" || bad "J: 校准段缺失" "(未渲染校准结果)"
# 空命中必须提示第二条通道。原先 `if (!picked.length) return ''` 静默返回 —— 而空命中混着
# 「本就不该注入」与「词法够不着」两种形态，后者占真相关的 37%（1292 对盲标：阈值降到 0.10
# 也只有 63% recall）。对后者静默，等于让 agent 永远不知道还有 candidates 这条通道。
{ $EVO recall --task "zz-smoke-绝不可能命中的词-zqxw" 2>&1 | grep -q 'evo candidates'; } \
  && ok "J: 空命中提示第二条通道（candidates/get）" || bad "J: 空命中提示" "(静默返回，agent 无从知道可深入检索)"
# agentic 通道必须有使用日志 —— 它是唯一能做语义匹配的通道，原先完全不可观测，
# 于是「路由修好了」只能是断言而非测量。
ALOG="$EVO_ROOT/ops/log/agentic.jsonl"  # smoke 跑在临时 ROOT 里，日志写在这里
rm -f "$ALOG"
$EVO candidates >/dev/null 2>&1
$EVO get --ids macos-no-timeout-command >/dev/null 2>&1
{ [ -f "$ALOG" ] && grep -q '"cmd":"candidates"' "$ALOG" && grep -q '"cmd":"get"' "$ALOG"; } \
  && ok "J: agentic 通道写使用日志（candidates/get 可观测）" || bad "J: agentic 日志" "(未落盘 ⇒ 通道不可观测)"
# 观测闭环的最后一环：仪器 → 报告。只写日志而没人读，等于没测。
{ $EVO reflect 2>&1 | grep -q 'L3b agentic 通道使用'; } \
  && ok "J: reflect 报 agentic 通道使用量（仪器→报告闭环）" || bad "J: agentic 统计行" "(reflect 未读 agentic.jsonl)"
# session 必须被回填 —— 否则 agent 选了哪些 id 无法与当时的 query 关联，
# 也就永远比不了「形态 B 命中率 vs 自动注入 P1」。
AL="$EVO_ROOT/ops/log/agentic.jsonl"
{ [ -f "$AL" ] && grep -q '"session"' "$AL"; } \
  && ok "J: agentic 日志带 session（可与 query 关联）" || bad "J: agentic session" "(缺 session ⇒ 无法归因到具体任务)"
# 通道分离：agentic 对账**不得**污染 recall 通道的精度统计。
# 这条守护是针对一个实际发生过的静默故障：achan 变量声明在 if 块内、用在块外，
# 抛 ReferenceError 被空 catch 吞掉 ⇒ 每条对账记录都被跳过 ⇒ 召回精度静默变成 0%（0/225），
# 而报告照常排版。所以这里不只查"能跑"，而是查**数值没被改动**。
RB=$($EVO reflect 2>/dev/null | grep 'M1 召回精度' | head -1)
$EVO reconcile --ids verify-external-references --state irrelevant --channel agentic >/dev/null 2>&1
RA=$($EVO reflect 2>/dev/null | grep 'M1 召回精度' | head -1)
{ [ -n "$RB" ] && [ "$RB" = "$RA" ]; } \
  && ok "J: agentic 对账不污染 recall 精度统计（通道分离生效）" || bad "J: 通道分离" "($RB → $RA)"
{ ! echo "$RA" | grep -q '(0/'; } \
  && ok "J: 召回精度非全零（防 catch 吞错导致的静默归零）" || bad "J: 精度静默归零" "(全部对账记录被跳过)"
# slice 必须分行报两条通道 —— 混成一行，Reflector 就会把两条的精度合成一个数
{ $EVO slice --session /dev/null --ids zz-nonexistent 2>&1 | grep -q 'agentic-picked:'; } \
  && ok "J: slice 分行报 injected 与 agentic-picked（通道不混）" || bad "J: slice 通道分行" "(缺 agentic-picked 行)"
mv "$EVO_ROOT/lessons/seed-failure-lessons-as-templates.md" "$EVO_ROOT/playbook/"
# 梯度提案的判据必须读 reconcile 日志，**不读 frontmatter 的 evidence 字段**。
# SCHEMA ⑨ 说 evidence「由 distill 对账单点回填（reconcile.jsonl）」，但搜遍 bin/evo
# **没有任何代码实现该回填** → 它会漂移。实测被它误导：3 条固化候选里 3 条的日志
# adopted 都是 0。这里用**负向 + 正向对照**一对断言钉死来源。
printf -- '---\nid: zz-drift-field\ntype: bullet\nstatus: validated\ntriggers: ["漂移字段探针"]\nevidence: {helpful: 9, harmful: 0}\n---\n正文\n' > "$EVO_ROOT/playbook/zz-drift-field.md"
{ ! $EVO reflect 2>&1 | grep -q "固化候选: \[zz-drift-field\]"; } \
  && ok "J: 固化判据读日志不读 evidence（声称 helpful=9 但无日志 → 不提议）" \
  || bad "J: 固化判据来源" "(仍读会漂移的 evidence 字段)"
rm -f "$EVO_ROOT/playbook/zz-drift-field.md"
printf -- '---\nid: zz-log-backed\ntype: bullet\nstatus: validated\ntriggers: ["日志支撑探针"]\nevidence: {helpful: 0, harmful: 0}\n---\n正文\n' > "$EVO_ROOT/playbook/zz-log-backed.md"
for i in 1 2 3; do $EVO reconcile --ids zz-log-backed --state adopted >/dev/null 2>&1; done
{ $EVO reflect 2>&1 | grep -q "固化候选: \[zz-log-backed\]"; } \
  && ok "J: 有日志支撑（adopted=3、evidence.helpful=0）才进固化候选" \
  || bad "J: 固化正向对照" "(有日志仍未提议)"
rm -f "$EVO_ROOT/playbook/zz-log-backed.md"
# 逐条精度闸门（M1 精度修复）：对账样本够且精度低的条目**不进自动注入**，
# 但直调 recall 照常可取。机制缺口：irrelevant 的 delta 是 (0,0)、govWeight 的 evW
# 又有 0.3 下限 → 被反复判无关的条目权重不降、无限期被继续注入（实测 182 次注入 12 例全无关）。
#
# **参数 2026-09-14 由 n≥5/<50% 收窄为 n≥10/<20%**，依据穷举盲标实测：按条目聚合的精度
# 分不出「窄但准」与「通常不准」—— 相关性是 (条目, query) 对的属性。实例
# `macos-no-timeout-command` 精度仅 20%（1/5），但盲标确认它在「macOS 上 timeout 命令用不了」
# 这条 query 上**确实相关**，而那是整晚唯一命中的短 query；旧参数把它连同 6 条一起砍了。
# 故本测试造 **10** 条无关记录（旧门槛下只需 5 条，会测不到新参数）。
printf -- '---\nid: zz-lowprec\ntype: bullet\nstatus: validated\ntriggers: ["低精度闸门探针"]\n---\n正文\n' > "$EVO_ROOT/playbook/zz-lowprec.md"
for i in 1 2 3 4 5 6 7 8 9 10; do $EVO reconcile --ids zz-lowprec --state irrelevant >/dev/null 2>&1; done
{ ! printf '{"session_id":"zz-gate-%s","prompt":"低精度闸门探针是什么"}' $RANDOM | $EVO hook-recall 2>&1 | grep -q 'zz-lowprec'; } \
  && ok "J: 低精度条目不进自动注入（无关 10/10 → 闸门排除）" || bad "J: 精度闸门" "(无关 10/10 仍被自动注入)"
{ $EVO recall --task "低精度闸门探针是什么" --budget 600 2>&1 | grep -q 'zz-lowprec'; } \
  && ok "J: 直调 recall 不受精度闸门限制（人明确要检索时照做）" || bad "J: 直调不受限" "(被闸门误伤)"
rm -f "$EVO_ROOT/playbook/zz-lowprec.md"

# ════════════ K. doctor（M0.4，唯一非零退出命令） ════════════
echo "——— K. doctor（部署自检） ———"
# 隔离 ROOT + HOME（hermetic：不依赖真实机器接线）
KROOT="$TMP/kroot"; KHOME="$TMP/khome"; REMOTE="$TMP/remote.git"
mkdir -p "$KROOT" "$KHOME"
rsync -a --exclude .git --exclude node_modules "$SRC/" "$KROOT/" 2>/dev/null
ln -s "$SRC/node_modules" "$KROOT/node_modules" 2>/dev/null
# git + 本地 bare remote（门①：remote 可达）
git init -q --bare "$REMOTE" 2>/dev/null
( cd "$KROOT" && git init -q && git remote add origin "$REMOTE" && git add -A && git commit -qm init >/dev/null 2>&1 && git push -q origin HEAD >/dev/null 2>&1 )
# 刷新 manifest（check 11 新鲜度）
EVO_ROOT="$KROOT" "$SRC/bin/evo" index rebuild >/dev/null 2>&1
# 接线文件指向 KROOT（决策③：路径匹配）
mkdir -p "$KHOME/.claude" "$KHOME/.hermes/agent-hooks" "$KHOME/.hermes"
# Claude hooks 已退役（pi 退役，挂载迁移至 Hermes hooks）：预期无挂载
printf '{}' > "$KHOME/.claude/settings.json"
# Hermes hooks 接线（config.yaml hooks 段 → agent-hooks adapter）
cat > "$KHOME/.hermes/config.yaml" << YAML
hooks:
  pre_llm_call:
    - command: "$KROOT/ops/integrations/hermes-evo-hooks/evo-recall.sh"
      timeout: 8
  on_session_end:
    - command: "$KROOT/ops/integrations/hermes-evo-hooks/evo-session-end.sh"
      timeout: 5
  pre_tool_call:
    - matcher: "terminal|write_file|patch"
      command: "$KROOT/ops/integrations/hermes-evo-hooks/evo-guard.sh"
      timeout: 5
YAML
# skills 软链（evo link with HOME=KHOME）
HOME="$KHOME" EVO_ROOT="$KROOT" "$SRC/bin/evo" link >/dev/null 2>&1
# K1: 全绿 → exit 0 + 无 [FAIL]
DOC=$(HOME="$KHOME" EVO_ROOT="$KROOT" "$SRC/bin/evo" doctor 2>&1); DRC=$?
{ [ $DRC -eq 0 ] && ! echo "$DOC" | grep -q '\[FAIL\]'; } && ok "K: doctor 全绿（exit0 + 无 FAIL）" || bad "K: doctor 全绿" "(rc=$DRC; $(echo "$DOC" | grep '\[FAIL\]' | tr '\n' ';'))"
# K5: Claude hooks 已退役确认（无挂载 → PASS；check 6 语义反转后不再误 FAIL）
{ echo "$DOC" | grep -q '6. Claude hooks 已退役确认' && echo "$DOC" | grep -q '预期无挂载'; } \
  && ok "K: doctor 含 Claude hooks 退役确认" || bad "K: 退役确认缺失" "(doctor 第 6 项语义未反转)"
# K6: 残留旧挂载 → WARN（不 FAIL，但须报残留，防退役后悄悄残留）
cat > "$KHOME/.claude/settings.json" << JSON
{"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"$KROOT/bin/evo hook-recall","timeout":8}]}],"SessionEnd":[{"hooks":[{"type":"command","command":"$KROOT/bin/evo hook-session-end","timeout":5}]}],"PreToolUse":[{"matcher":"Bash|Write|Edit","hooks":[{"type":"command","command":"$KROOT/bin/evo hook-guard","timeout":5}]}]}}
JSON
DOC5=$(HOME="$KHOME" EVO_ROOT="$KROOT" "$SRC/bin/evo" doctor 2>&1)
{ echo "$DOC5" | grep -q '残留旧挂载'; } \
  && ok "K: 残留 Claude 挂载报 WARN" || bad "K: 残留检测失效" "(有残留未报)"
printf '{}' > "$KHOME/.claude/settings.json"
# K4: Hermes hooks adapter 副本漂移检测（§4.2 存续）——留副本不够，副本会悄悄过期，必须比对内容
{ echo "$DOC" | grep -q '16. Hermes hooks adapter 副本'; } \
  && ok "K: doctor 含 hermes adapter 副本检查" || bad "K: 副本检查缺失" "(doctor 无第 16 项)"
printf '#!/usr/bin/env bash\n# 实装侧漂移\n' > "$KHOME/.hermes/agent-hooks/evo-recall.sh"
DOC4=$(HOME="$KHOME" EVO_ROOT="$KROOT" "$SRC/bin/evo" doctor 2>&1)
{ echo "$DOC4" | grep -q '副本漂移'; } \
  && ok "K: 实装与副本不一致时报漂移" || bad "K: 漂移检测失效" "(改了实装仍报一致)"
cp "$SRC/ops/integrations/hermes-evo-hooks/evo-recall.sh" "$KHOME/.hermes/agent-hooks/evo-recall.sh"
# K7: 蒸馏驱动器装载检查 —— 未装载时覆盖率不再增长，而此前没有任何信号：
# 2026-09 实测停了 20 天无人发现，覆盖率冻在 8% 还被归因为「纪律问题」。
# 必须能在隔离 HOME 下判定，否则 smoke 会读真实机器、变成环境依赖。
{ echo "$DOC" | grep -q '18. 后台蒸馏驱动器'; } \
  && ok "K: doctor 含蒸馏驱动器装载检查" || bad "K: 驱动器检查缺失" "(doctor 无第 18 项)"
{ echo "$DOC" | grep -q '18. 后台蒸馏驱动器.*未装载'; } \
  && ok "K: 隔离 HOME 下未装载报 WARN" || bad "K: 隔离 HOME 判定" "(未按 HOME 作用域判定: $(echo "$DOC" | grep '18.'))"
mkdir -p "$KHOME/Library/LaunchAgents"
cp "$KROOT/ops/bin/com.evo.distill.plist" "$KHOME/Library/LaunchAgents/"
DOC7=$(HOME="$KHOME" EVO_ROOT="$KROOT" "$SRC/bin/evo" doctor 2>&1)
{ echo "$DOC7" | grep -q '18. 后台蒸馏驱动器.*已装载且与副本一致'; } \
  && ok "K: 装载后报 PASS" || bad "K: 装载后判定" "(实得: $(echo "$DOC7" | grep '18.'))"
printf 'x' >> "$KHOME/Library/LaunchAgents/com.evo.distill.plist"
DOC8=$(HOME="$KHOME" EVO_ROOT="$KROOT" "$SRC/bin/evo" doctor 2>&1)
{ echo "$DOC8" | grep -q '18. 后台蒸馏驱动器.*漂移'; } \
  && ok "K: 副本漂移报 WARN" || bad "K: 漂移检测" "(改了 plist 仍报一致)"
rm -f "$KHOME/Library/LaunchAgents/com.evo.distill.plist"
# K2: 删 remote → exit≠0 + 含 FAIL 行
( cd "$KROOT" && git remote remove origin )
DOC2=$(HOME="$KHOME" EVO_ROOT="$KROOT" "$SRC/bin/evo" doctor 2>&1); DRC2=$?
{ [ $DRC2 -ne 0 ] && echo "$DOC2" | grep -q '\[FAIL\]'; } && ok "K: doctor FAIL（删 remote → exit≠0 + FAIL 行）" || bad "K: doctor FAIL" "(rc=$DRC2)"
# K3: --full 附跑 smoke（恢复 remote 后）；嵌套运行（EVO_DOCTOR_FULL 已设）时跳过以断递归
if [ -z "${EVO_DOCTOR_FULL:-}" ]; then
  ( cd "$KROOT" && git remote add origin "$REMOTE" )
  DOC3=$(HOME="$KHOME" EVO_ROOT="$KROOT" "$SRC/bin/evo" doctor --full 2>&1); DRC3=$?
  { [ $DRC3 -eq 0 ] && echo "$DOC3" | grep -q '结果: OK'; } && ok "K: doctor --full（附跑 smoke，结果并入）" || bad "K: doctor --full" "(rc=$DRC3; $(echo "$DOC3" | grep -E 'smoke 全量|结果' | tail -1))"
else
  ok "K: doctor --full（嵌套运行跳过，防递归）"
fi

# ════════════ L. 后台飞轮（queue / mark-distilled / reconcile / 噪声门槛） ════════════
echo "——— L. 后台飞轮驱动（后台蒸馏输入输出） ———"
# 大 transcript（过体量门槛）+ 小 transcript（组 I 的 sess-real，6 bytes）+ 哨兵（sess-sentinel）
BIGF="$TMP/big-session.jsonl"; head -c 60000 /dev/zero | tr '\0' 'x' > "$BIGF"
$EVO session-end --session "$BIGF" --id sess-big >/dev/null 2>&1
Q=$($EVO queue --min-bytes 50000 2>&1)
{ echo "$Q" | grep -q '^sess-big	' && ! echo "$Q" | grep -q 'sess-real' && ! echo "$Q" | grep -q 'sess-sentinel'; } \
  && ok "L: queue 体量门槛 + 哨兵/小会话排除" || bad "L: queue 过滤" "(实得: ${Q:0:100})"
# mark-distilled 回写 → 出队，且不新增行（原地重写，一会话一行）
LBEFORE=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
$EVO mark-distilled --ids sess-big >/dev/null 2>&1
LAFTER=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
Q2=$($EVO queue --min-bytes 50000 2>&1)
{ [ "$LBEFORE" = "$LAFTER" ] && ! echo "$Q2" | grep -q 'sess-big'; } \
  && ok "L: mark-distilled 回写出队（原地重写不增行）" || bad "L: mark-distilled" "(行数 ${LBEFORE}→${LAFTER}; 队列: ${Q2:0:60})"
# reconcile 四态：judged_by 必须是 reflector（与 adopt/reject 的 human 区分）
$EVO reconcile --ids arxiv-api-rate-limit --state relevant-unused --session sess-big >/dev/null 2>&1
{ tail -1 "$EVO_ROOT/ops/log/reconcile.jsonl" | grep -q '"judged_by":"reflector"' \
  && tail -1 "$EVO_ROOT/ops/log/reconcile.jsonl" | grep -q '"state":"relevant-unused"'; } \
  && ok "L: reconcile 写四态（judged_by=reflector）" || bad "L: reconcile" "(实得: $(tail -1 "$EVO_ROOT/ops/log/reconcile.jsonl" | head -c 80))"
t "L: reconcile 非法 state 拒绝" "usage: evo reconcile" $EVO reconcile --ids x --state bogus
# 噪声门槛：斜杠命令/超短 prompt 不进 recall.jsonl（护住 M1 分母），实义 prompt 照常进
RBEFORE=$(grep -c . "$EVO_ROOT/ops/log/recall.jsonl" 2>/dev/null || echo 0)
printf '{"session_id":"noise-1","prompt":"提交"}' | $EVO hook-recall >/dev/null 2>&1
printf '{"session_id":"noise-2","prompt":"/grill-me"}' | $EVO hook-recall >/dev/null 2>&1
RMID=$(grep -c . "$EVO_ROOT/ops/log/recall.jsonl" 2>/dev/null || echo 0)
printf '{"session_id":"real-1","prompt":"arxiv API 批量下载被限流该怎么处理"}' | $EVO hook-recall >/dev/null 2>&1
RAFTER=$(grep -c . "$EVO_ROOT/ops/log/recall.jsonl" 2>/dev/null || echo 0)
{ [ "$RBEFORE" = "$RMID" ] && [ "$RAFTER" -gt "$RMID" ]; } \
  && ok "L: hook-recall 噪声门槛（噪声不记账，实义 prompt 照常）" || bad "L: 噪声门槛" "(计数 ${RBEFORE}→${RMID}→${RAFTER})"
# 驱动器隔离的完整性：EVO_DRIVER=1 下**直调** recall 也不得记账（2026-09-17 实测的漏网点）。
# 未堵时驱动器/一次性探针会以 session:null 落进 recall.jsonl，被 reflect 的注入统计计入；
# slice/覆盖率按 session 过滤不受影响 —— 所以这是只有靠断言才守得住的静默污染。
DBEFORE=$(grep -c . "$EVO_ROOT/ops/log/recall.jsonl" 2>/dev/null || echo 0)
EVO_DRIVER=1 $EVO recall --task "驱动器隔离探针 xyzzy-driver" >/dev/null 2>&1
DDRIVER=$(grep -c . "$EVO_ROOT/ops/log/recall.jsonl" 2>/dev/null || echo 0)
{ [ "$DBEFORE" = "$DDRIVER" ]; } \
  && ok "L: EVO_DRIVER=1 直调 recall 不记账（驱动器隔离）" || bad "L: 驱动器隔离" "($DBEFORE → $DDRIVER 行)"
# 对照：同一命令不带标记必须照常记账，否则上面那条会被「压根不写日志」白嫖通过。
$EVO recall --task "驱动器隔离探针对照 xyzzy-driver" >/dev/null 2>&1
DCONTROL=$(grep -c . "$EVO_ROOT/ops/log/recall.jsonl" 2>/dev/null || echo 0)
{ [ "$DCONTROL" -gt "$DDRIVER" ]; } \
  && ok "L: 直调 recall 无标记时照常记账（隔离对照）" || bad "L: 驱动器隔离对照" "($DDRIVER → $DCONTROL 行)"

# catalog：蒸馏端查重清单。必须盖住 candidates 看不见的两处——lessons/inbox 与 ops/proposals，
# 后者是当前最大重复源（未 curate 的提案彼此也会撞）。格式必须一条一行、无内嵌换行，
# 否则 Reflector 只能整份读进上下文，库一大就爆。
cat > "$EVO_ROOT/ops/proposals/zz-dedup-probe.md" << 'MD'
---
id: zz-dedup-probe
type: lesson
status: candidate
triggers: ["查重探针唯一词 xyzzy-probe"]
---
探针正文
MD
cat > "$EVO_ROOT/lessons/zz-superseded-probe.md" << 'MD'
---
id: zz-superseded-probe
type: lesson
status: candidate
triggers: ["已取代探针 plugh-probe"]
superseded_by: some-newer-entry
---
探针正文
MD
CAT=$($EVO catalog 2>&1)
{ printf '%s' "$CAT" | grep -q $'zz-dedup-probe	ops/proposals	' \
  && printf '%s' "$CAT" | grep -q 'xyzzy-probe'; } \
  && ok "L: catalog 覆盖 ops/proposals 待审提案（candidates 盲区）" || bad "L: catalog 漏 proposals" "(未见探针)"
{ ! printf '%s' "$CAT" | grep -q 'zz-superseded-probe'; } \
  && ok "L: catalog 排除 superseded_by 条目（已取代不算覆盖）" || bad "L: catalog superseded" "(不该出现却出现)"
# 一条一行：行数 == 非空条目数，且每行恰好 2 个 tab（id/zone/triggers）
BADLINES=$(printf '%s\n' "$CAT" | awk -F'\t' 'NF!=3' | grep -c . || true)
{ [ "$BADLINES" = "0" ]; } \
  && ok "L: catalog 每条一行 3 字段（可 grep，不必整份读）" || bad "L: catalog 行格式" "($BADLINES 行字段数≠3)"
rm -f "$EVO_ROOT/ops/proposals/zz-dedup-probe.md" "$EVO_ROOT/lessons/zz-superseded-probe.md"

# ── 2026-09-18 加：并发写入锁 + 并行蒸馏驱动器 ──────────────────────────
# 背景：驱动器改并发（EVO_DISTILL_JOBS）后，收工回写 session-refs.jsonl 的会是 N 个进程。
# 那是「读-改-写」，rename 原子只保证不读到半截文件、**挡不住丢更新**。
# 实测对照：16 进程同时 mark-distilled，无锁 0/16 存活，加锁 16/16。
RACE_IDS=""; RACE_N=8; i=0
while [ $i -lt "$RACE_N" ]; do RACE_IDS="$RACE_IDS zz-race-$i"; i=$((i+1)); done
for id in $RACE_IDS; do
  printf '{"ts":"2026-09-18T00:00:00.000Z","session":"%s","transcript":"?","harness":"pi","distilled":false,"ended":true}\n' "$id" >> "$EVO_ROOT/inbox/session-refs.jsonl"
done
# 同时起 N 个进程，每个只标记自己那一条（并发窗口极小但存在：旧实现下全丢）
for id in $RACE_IDS; do "$EVO" mark-distilled --ids "$id" >/dev/null 2>&1 & done
wait
RACE_OK=$(python3 - "$EVO_ROOT/inbox/session-refs.jsonl" $RACE_IDS <<'PY'
import json, sys
path, want = sys.argv[1], set(sys.argv[2:])
n = 0
for line in open(path, encoding='utf-8', errors='replace'):
    if not line.strip(): continue
    try:
        j = json.loads(line)
        if j.get('session') in want and j.get('distilled'): n += 1
    except Exception: pass
print(n)
PY
)
{ [ "$RACE_OK" = "$RACE_N" ]; } \
  && ok "L: mark-distilled 并发不丢更新（${RACE_N} 进程 ${RACE_OK}/${RACE_N} 存活）" \
  || bad "L: mark-distilled 并发丢更新" "(${RACE_OK}/${RACE_N} 存活)"
# 清场：把竞态用的行去掉，别影响后续断言
python3 - "$EVO_ROOT/inbox/session-refs.jsonl" $RACE_IDS <<'PY'
import json, sys
path, drop = sys.argv[1], set(sys.argv[2:])
keep = []
for line in open(path, encoding='utf-8', errors='replace'):
    if not line.strip(): continue
    try:
        if json.loads(line).get('session') in drop: continue
    except Exception: pass
    keep.append(line.rstrip('\n'))
open(path, 'w').write('\n'.join(keep) + '\n')
PY

# 并行驱动器：JOBS=2 跑 6 条，断言「三个契约」——切片无重叠无遗漏（全标 distilled）、
# 日志有并行边界、锁在跑完后释放。假 hermes 让这组不碰网络、秒级完成。
# ⚠ 跑之前必须清掉拷进来的锁：实体 rsync 会把**真仓库正在跑的** ops/log/.distill.lock 一并拷来，
#   而它的 mtime 是刚拷的→看着很新鲜→驱动器正确地报「已有实例在跑」并跳过（测试假红）。
#   同理清掉 .distill-*.out 残留，避免上一轮诊断文件混入断言。
rm -rf "$EVO_ROOT/ops/log/.distill.lock"; rm -f "$EVO_ROOT"/ops/log/.distill-*.out
# 锁路径被非目录占用也必须能自愈（实测形状：还活着的旧实例心跳用 touch 把锁目录变成了同名空文件，
# 于是 mkdir 永远 EEXIST、[ -d ] 又不成立 → 每轮都报「已有实例在跑」且永不恢复）。
: > "$EVO_ROOT/ops/log/.distill.lock"
# 注：macOS 没有 /bin/true（是 /usr/bin/true）—— 写错会让驱动在 hermes 检查处就退出，
# 于是这条断言假红，看起来像「自愈没生效」。
EVO_DISTILL_JOBS=2 EVO_HERMES_PY=/bin/bash EVO_HERMES_BIN="/usr/bin/true" EVO_DISTILL_EVO="$EVO" \
EVO_DISTILL_MIN_BYTES=999999999 "$EVO_ROOT/ops/bin/evo-distill.sh" --max 1 >/dev/null 2>&1
grep -q '锁路径被非目录占用' "$EVO_ROOT/ops/log/distill.log" \
  && ok "L: 锁路径被非目录占用时自愈" || bad "L: 锁路径非目录" "(未自愈→驱动会被永久挡住)"
rm -rf "$EVO_ROOT/ops/log/.distill.lock"; rm -f "$EVO_ROOT"/ops/log/.distill-*.out
FAKE_HERMES="$TMP/fake-hermes.sh"
printf '#!/usr/bin/env bash\necho "DISTILL_OK 0"\n' > "$FAKE_HERMES"; chmod +x "$FAKE_HERMES"
PAR_N=6; p=0
while [ $p -lt "$PAR_N" ]; do
  pf="$TMP/par-$p.jsonl"; head -c 3000 /dev/zero | tr '\0' 'x' > "$pf"
  "$EVO" session-end --session "$pf" --id "zz-par-$p" >/dev/null 2>&1
  p=$((p+1))
done
EVO_DISTILL_JOBS=2 EVO_HERMES_PY=/bin/bash EVO_HERMES_BIN="$FAKE_HERMES" EVO_DISTILL_EVO="$EVO" \
EVO_DISTILL_MIN_BYTES=10 EVO_DISTILL_TIMEOUT=60 EVO_DISTILL_TIMEOUT_PER_100KB=0 EVO_DISTILL_POLL=0.2 \
  "$EVO_ROOT/ops/bin/evo-distill.sh" --max "$PAR_N" >/dev/null 2>&1
PAR_DONE=$(python3 - "$EVO_ROOT/inbox/session-refs.jsonl" "$PAR_N" <<'PY'
import json, sys
path, n = sys.argv[1], int(sys.argv[2])
want = {f'zz-par-{i}' for i in range(n)}
c = 0
for line in open(path, encoding='utf-8', errors='replace'):
    if not line.strip(): continue
    try:
        j = json.loads(line)
        if j.get('session') in want and j.get('distilled'): c += 1
    except Exception: pass
print(c)
PY
)
{ [ "$PAR_DONE" = "$PAR_N" ]; } \
  && ok "L: 并行驱动器切片无重叠无遗漏（${PAR_DONE}/${PAR_N} 全标）" \
  || bad "L: 并行驱动器切片" "(标上 ${PAR_DONE}/${PAR_N}；切片重叠或漏登？)"
{ grep -q '并行启动' "$EVO_ROOT/ops/log/distill.log" && ! [ -d "$EVO_ROOT/ops/log/.distill.lock" ]; } \
  && ok "L: 并行轮记边且锁已释放" || bad "L: 并行轮边界/锁" "(缺『并行启动』或有锁残留)"

# 源码卫生：`$VAR` 紧跟多字节字符会被 bash **吞进变量名**（set -u 下报 unbound，
# 且报错里的变量名是断字节、连 python 都解不出来）。本仓库到处是中文，全角标点紧跟在变量
# 后面是高频写法 —— 2026-09-18 一天内踩了三次（本文件自己的 bad 分支、evo-distill.sh、
# evo-drain.sh），而其中 smoke 这六处**藏在失败分支里**：平时不报，一旦某条断言失败就抛出
# 第二条莫名其妙的 unbound，把真正的失败信息盖掉。
# 这里做静态扫：非注释行里出现 `$name` + 非 ASCII 字节即判违规（写法应为 ${name}）。
BADV=$(python3 - "$SRC" <<'PY'
import re, pathlib, sys
root = pathlib.Path(sys.argv[1])
pat = re.compile(rb'\$[A-Za-z_][A-Za-z0-9_]*[\x80-\xff]')
hits = []
for p in sorted(list((root / 'ops/bin').glob('*.sh')) + [root / 'test/smoke.sh']):
    if not p.exists(): continue
    for i, line in enumerate(p.read_bytes().split(b'\n'), 1):
        if line.lstrip().startswith(b'#'): continue
        if pat.search(line): hits.append(f"{p.name}:{i}")
print(','.join(hits))
PY
)
{ [ -z "$BADV" ]; } \
  && ok "L: shell 脚本无 \$VAR 紧跟多字节字符（应为 \${VAR}）" \
  || bad "L: \$VAR 紧跟多字节字符" "(会被吞进变量名: $BADV)"

# ── 逐条精度闸门的**确定性**守护（合成条目 + 合成账本，不依赖活库）───────────────
# 为何在这里补（2026-09-18）：D 组那两条 hook 断言曾经隐式地依赖「某条真实条目当下没被闸门
# 排掉」，而闸门读的是活的 reconcile.jsonl（另一个后台进程在写）→ 代码没改、测试变红。
# 闸门本身的契约是三条：
#   ① n ≥ 10 且精度 < 20% 的条目，**automatic 注入路径**（hook）不再列它；
#   ② 同一条目**直调** `evo recall` 仍拿得到（文档承诺的逃生通道，人手要检索时必须照做）；
#   ③ n 不足 10 条时闸门不生效（避开小样本）。
# 用夹具把这三条钉住，就不再看活库脸色。
GATE_ENTRY="$EVO_ROOT/playbook/zz-gate-probe.md"
cat > "$GATE_ENTRY" <<'EOF'
---
id: zz-gate-probe
type: lesson
status: validated
scope: global
domain: testing
tags: [zzgateprobe]
triggers:
  - "zzgateprobe 专项排查"
  - "验证 zzgateprobe 的行为一致性"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:smoke-fixture
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---
合成夹具：只用于验证逐条精度闸门，不表达任何经验内容。
EOF
GATE_TASK="zzgateprobe 专项排查"
# 先确认夹具本身可被命中（否则后面的断言假绿）
if "$EVO" recall --task "$GATE_TASK" 2>/dev/null | grep -q 'zz-gate-probe'; then
  ok "L: 闸门夹具可命中（前置）"
  # 写 10 条 irrelevant（n=10、精度 0% → 应触发闸门）
  i=0
  while [ $i -lt 10 ]; do
    printf '{"ts":"2026-09-18T00:00:00.000Z","session":"zz-gate-s%d","id":"zz-gate-probe","task":"","state":"irrelevant","channel":"recall","helpful_delta":0,"harmful_delta":0,"judged_by":"reflector"}\n' "$i" >> "$EVO_ROOT/ops/log/reconcile.jsonl"
    i=$((i+1))
  done
  "$EVO" recall --task "$GATE_TASK" 2>/dev/null | grep -q 'zz-gate-probe' \
    && ok "L: 闸门只作用于自动路径（直调 recall 仍取得到）" \
    || bad "L: 闸门淹了直调 recall" "(逃生通道被打断)"
  printf '{"session_id":"zzgate-%s","prompt":"zzgateprobe 专项排查"}\n' "$RANDOM" | "$EVO" hook-recall 2>/dev/null | grep -q 'zz-gate-probe' \
    && bad "L: 精度闸门未生效" "(n=10 全 irrelevant 仍被自动注入)" \
    || ok "L: 精度闸门确实拦住了自动注入（n=10 全 irrelevant）"
else
  bad "L: 闸门夹具不可命中" "(前置失败，后续闸门断言无意义)"
fi
rm -f "$GATE_ENTRY"
# 清掉夹具账本行，免污染后面可能新增的断言
python3 - "$EVO_ROOT/ops/log/reconcile.jsonl" <<'PY'
import json, sys
path = sys.argv[1]
keep = []
for line in open(path, encoding='utf-8', errors='replace'):
    if not line.strip(): continue
    try:
        if json.loads(line).get('id') == 'zz-gate-probe': continue
    except Exception: pass
    keep.append(line.rstrip('\n'))
open(path, 'w').write('\n'.join(keep) + '\n')
PY

echo
echo "================ PASS=$PASS FAIL=$FAIL ================"
[ $FAIL -eq 0 ]
