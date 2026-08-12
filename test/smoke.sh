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
t "hook-recall 50KB"       "__NOOUTPUT__" bash -c "python3 -c \"import json;print(json.dumps({'session_id':'sec-long','prompt':'x'*50000}))\" | $EVO hook-recall"

# ════════════ C. fail-open（1 独立断言，EVO_ROOT 缺失） ════════════
echo "——— C. fail-open ———"
out=$(echo '{"session_id":"s","prompt":"arxiv"}' | EVO_ROOT=/nonexistent-xyz $EVO hook-recall 2>/dev/null); rc=$?
{ [ $rc -eq 0 ] && [ -z "$out" ]; } && ok "EVO_ROOT 缺失静默(exit0+stdout空)" || bad "EVO_ROOT 缺失静默" "(rc=$rc out=$out)"

# ════════════ D. 端到端（注入/去重/空命中不占名额，3） ════════════
echo "——— D. 端到端（注入/去重/空命中不占名额） ———"
t "全新 session 命中避坑"  "arxiv-download-proxy-truncation" bash -c "echo '{\"session_id\":\"fresh-\$RANDOM\",\"prompt\":\"帮我批量下载 arXiv 论文 PDF\"}' | $EVO hook-recall"
SID="dedup-$RANDOM"
echo "{\"session_id\":\"$SID\",\"prompt\":\"arxiv 下载 pdf 损坏\"}" | $EVO hook-recall >/dev/null 2>&1
t "同 session 去重"        "__NOOUTPUT__" bash -c "echo '{\"session_id\":\"$SID\",\"prompt\":\"再问一次\"}' | $EVO hook-recall"
SID2="retry-$RANDOM"
echo "{\"session_id\":\"$SID2\",\"prompt\":\"今天天气如何\"}" | $EVO hook-recall >/dev/null 2>&1
t "空命中后仍重试"         "arxiv" bash -c "echo '{\"session_id\":\"$SID2\",\"prompt\":\"批量下载 arXiv 论文\"}' | $EVO hook-recall"

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
  && ok "F: 提及仍落盘 quality:mention（准入④取证不丢）" || bad "F: 提及落盘" "(行数 $GB→$GA, 末行: $(tail -1 "$GH" | cut -c1-90))"
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
{ $EVO reflect 2>&1 | grep -q "不建议升 block: 约束 \[t-fp\]"; } \
  && ok "F: 全引号内提及的约束不得进升 block 候选" || bad "F: 升 block 判据" "(裸命中被当证据)"
rm -f "$EVO_ROOT/ops/constraints/t-fp.json"
# I3 人审门必须由 guard 执行，不能只写在 SKILL.md 里：agent 能直调的命令等于没有人审
# （见 playbook/approval-gate-written-only-in-prompt-is-not-enforceable）。warn 档，不阻断。
{ $EVO guard --tool bash --input-json '{"command":"evo curate --file x.md --to playbook"}' 2>&1 | grep -q 'evo-curate-needs-human'; } \
  && ok "F: curate 人审门有 guard 执行（I3 可执行化）" || bad "F: curate 人审门" "(guard 未拦 evo curate)"
{ $EVO guard --tool bash --input-json '{"command":"evo recall --task t"}' 2>&1 | grep -q '"allow"'; } \
  && ok "F: 人审门不误伤其他 evo 命令" || bad "F: 人审门误伤" "(evo recall 被拦)"
# SCHEMA ⑮：related 悬挂引用比没有链接更误导，加字段必须同时有治理出口
printf -- '---\nid: zz-dangling\ntype: lesson\nstatus: candidate\ntriggers: ["悬挂探针"]\nrelated: [no-such-entry-id]\n---\n正文\n' > "$EVO_ROOT/lessons/zz-dangling.md"
{ $EVO audit 2>&1 | grep -q 'related 指向不存在的 id'; } \
  && ok "F: audit 检出悬挂 related（建链治理出口）" || bad "F: 悬挂 related" "(audit 未检出)"
rm -f "$EVO_ROOT/lessons/zz-dangling.md"
# 检索基准的契约：跑得起来、四阶段齐全、且**不写真实 ops/log**（recall.jsonl 是 §7.1 精度与
# §5.0 回放的数据源，基准查询混进去会污染判据）。此处不守护阈值——阈值要先有基线才能定。
BENCH_BEFORE=$(wc -l < "$SRC/ops/log/recall.jsonl" 2>/dev/null || echo 0)
BENCH_OUT=$(node "$SRC/test/retrieval-bench/bench.js" 2>&1)
BENCH_AFTER=$(wc -l < "$SRC/ops/log/recall.jsonl" 2>/dev/null || echo 0)
{ echo "$BENCH_OUT" | grep -q '| transfer |' && echo "$BENCH_OUT" | grep -q '| change |'; } \
  && ok "M: 检索基准四阶段可跑" || bad "M: 检索基准" "(实得: $(echo "$BENCH_OUT" | tail -1))"
{ [ "$BENCH_BEFORE" = "$BENCH_AFTER" ]; } \
  && ok "M: 基准不污染 recall.jsonl（测量与被测数据隔离）" || bad "M: 基准日志隔离" "($BENCH_BEFORE → $BENCH_AFTER 行)"
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
# inbox 渲染 refs 计数（= JSONL 行数，不硬编码）
REFSLINES=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl" 2>/dev/null || echo 0)
REFS_OUT=$($EVO inbox 2>&1)
{ echo "$REFS_OUT" | grep -q "$REFSLINES 条会话登记待蒸馏"; } && ok "I: inbox 渲染 refs 计数（= JSONL 行数）" || bad "I: inbox 渲染 refs 计数" "(期望 $REFSLINES 条, 实得: ${REFS_OUT:0:60})"

# ── 登记前移 + upsert（依据：51.7% 的注入实例落在从未登记的 session 上，SessionEnd 会漏）──
LIVE="$TMP/live-transcript.jsonl"; echo '{"role":"user"}' > "$LIVE"
B4=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
echo "{\"session_id\":\"sess-live\",\"prompt\":\"arxiv 论文下载\",\"transcript_path\":\"$LIVE\"}" | $EVO hook-recall >/dev/null 2>&1
A1=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
{ [ "$A1" = "$((B4+1))" ] && grep -q '"session":"sess-live"' "$EVO_ROOT/inbox/session-refs.jsonl"; } \
  && ok "I: 登记前移（首次 hook-recall 即登记，不等 SessionEnd）" || bad "I: 登记前移" "(行数 $B4→$A1)"
# 二次 hook-recall 不得新增行（upsert 幂等；append 会虚增哨兵率与蒸馏节律分母）
echo "{\"session_id\":\"sess-live\",\"prompt\":\"另一个问题\",\"transcript_path\":\"$LIVE\"}" | $EVO hook-recall >/dev/null 2>&1
A2=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
{ [ "$A2" = "$A1" ]; } && ok "I: 登记 upsert 幂等（同 session 不产生第二行）" || bad "I: 登记 upsert 幂等" "($A1→$A2)"
# 哨兵升级：先登记不存在的路径（'?'），再带真实路径登记 → 同一行升级，行数不变
$EVO session-end --session "/nonexistent/later.jsonl" --id sess-upgrade >/dev/null 2>&1
U1=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
$EVO session-end --session "$LIVE" --id sess-upgrade >/dev/null 2>&1
U2=$(grep -c . "$EVO_ROOT/inbox/session-refs.jsonl")
{ [ "$U2" = "$U1" ] && grep '"session":"sess-upgrade"' "$EVO_ROOT/inbox/session-refs.jsonl" | grep -q "$LIVE"; } \
  && ok "I: 哨兵行可被真实路径升级（单向，行数不变）" || bad "I: 哨兵升级" "(行数 $U1→$U2)"
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
{"ts":"2026-07-24T10:00:01.000Z","session":"s1","id":"arxiv-api-rate-limit","task":"","state":"misleading","helpful_delta":0,"harmful_delta":1,"judged_by":"reflector"}
{"ts":"2026-07-24T10:00:02.000Z","session":"s1","id":"arxiv-api-rate-limit","task":"","state":"relevant-unused","helpful_delta":0,"harmful_delta":0,"judged_by":"reflector"}
JSONL
# rebuild 聚合 delta（base helpful=3+1=4, harmful=0+1=1）
$EVO index rebuild >/dev/null 2>&1
{ grep -A10 'id: arxiv-api-rate-limit' "$EVO_ROOT/index/manifest.yaml" | grep -q 'helpful: 4' && grep -A10 'id: arxiv-api-rate-limit' "$EVO_ROOT/index/manifest.yaml" | grep -q 'harmful: 1'; } && ok "J: rebuild 聚合 reconcile delta（helpful+1/harmful+1）" || bad "J: rebuild 聚合 delta" "(manifest 未反映累计)"
# 精度计算（reflect 判据对照表）：断言算出来的**数**，不是断言表格标题在不在。
# 只 grep 标题的旧断言会在分子分母算错时照样通过（见 lessons/test-may-pass-for-the-wrong-reason）。
REFL_OUT=$($EVO reflect 2>&1)
RECN=$(grep -c . "$EVO_ROOT/ops/log/reconcile.jsonl" 2>/dev/null || echo 0)
RELN=$(grep -c '"state":"\(adopted\|relevant-unused\)"' "$EVO_ROOT/ops/log/reconcile.jsonl" 2>/dev/null || echo 0)
PREC=$(node -e "console.log(Math.round($RELN/$RECN*100))")
{ echo "$REFL_OUT" | grep -q "M1 召回精度（检索层） | ${PREC}%（${RELN}/${RECN}）"; } \
  && ok "J: 精度计算（召回精度 = ${PREC}%（${RELN}/${RECN}），按实际四态算）" \
  || bad "J: 精度计算" "(期望 ${PREC}%（${RELN}/${RECN}）, 实得: $(echo "$REFL_OUT" | grep 'M1 召回精度'))"
# §7.1 对账覆盖率的分母是**注入实例数**（Σ|ids|），不是 recall 调用数——用调用数当分母会虚高数倍，
# 而这个数决定「精度可不可解读」。分母从 recall.jsonl 现算，不硬编码。
INST=$(node -e "
const fs=require('fs');let n=0;
for(const l of fs.readFileSync('$EVO_ROOT/ops/log/recall.jsonl','utf8').split('\n')){
  if(!l.trim())continue; try{const j=JSON.parse(l); n+=(j.ids||[]).length;}catch{}
}
console.log(n);")
{ echo "$REFL_OUT" | grep -q "M1 对账覆盖率 | .*（${RECN}/${INST}）"; } \
  && ok "J: 对账覆盖率分母 = 注入实例数 Σ|ids|（${RECN}/${INST}）" \
  || bad "J: 对账覆盖率分母" "(期望分母 ${INST} 个实例, 实得: $(echo "$REFL_OUT" | grep '对账覆盖率'))"
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
{ echo "$RF" | grep -q "退役候选（空转）: \[$DEADID\]"; } \
  && ok "J: 空转条目进退役候选（adopted=0 且注入≥5）" || bad "J: 空转退役" "(reflect 无该候选)"
# 有采用记录的条目不能被误判退役：同 id 补一条 adopted 后应立即移出候选
$EVO reconcile --ids $DEADID --state adopted >/dev/null 2>&1
{ ! $EVO reflect 2>&1 | grep -q "退役候选（空转）: \[$DEADID\]"; } \
  && ok "J: adopted≥1 即豁免空转退役（不误杀活条目）" || bad "J: 空转退役误杀" "(adopted 后仍在候选)"

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
cat > "$KHOME/.claude/settings.json" << JSON
{"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"$KROOT/bin/evo hook-recall","timeout":8}]}],"SessionEnd":[{"hooks":[{"type":"command","command":"$KROOT/bin/evo hook-session-end","timeout":5}]}],"PreToolUse":[{"matcher":"Bash|Write|Edit","hooks":[{"type":"command","command":"$KROOT/bin/evo hook-guard","timeout":5}]}]}}
JSON
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
# K4: Hermes hooks adapter 副本漂移检测（§4.2 存续）——留副本不够，副本会悄悄过期，必须比对内容
{ echo "$DOC" | grep -q '16. Hermes hooks adapter 副本'; } \
  && ok "K: doctor 含 hermes adapter 副本检查" || bad "K: 副本检查缺失" "(doctor 无第 16 项)"
printf '#!/usr/bin/env bash\n# 实装侧漂移\n' > "$KHOME/.hermes/agent-hooks/evo-recall.sh"
DOC4=$(HOME="$KHOME" EVO_ROOT="$KROOT" "$SRC/bin/evo" doctor 2>&1)
{ echo "$DOC4" | grep -q '副本漂移'; } \
  && ok "K: 实装与副本不一致时报漂移" || bad "K: 漂移检测失效" "(改了实装仍报一致)"
cp "$SRC/ops/integrations/hermes-evo-hooks/evo-recall.sh" "$KHOME/.hermes/agent-hooks/evo-recall.sh"
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
  && ok "L: mark-distilled 回写出队（原地重写不增行）" || bad "L: mark-distilled" "(行数 $LBEFORE→$LAFTER; 队列: ${Q2:0:60})"
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
  && ok "L: hook-recall 噪声门槛（噪声不记账，实义 prompt 照常）" || bad "L: 噪声门槛" "(计数 $RBEFORE→$RMID→$RAFTER)"

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

echo
echo "================ PASS=$PASS FAIL=$FAIL ================"
[ $FAIL -eq 0 ]
