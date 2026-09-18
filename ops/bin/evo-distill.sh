#!/usr/bin/env bash
# evo-distill —— 后台蒸馏驱动器（Hermes CLI 作为 Reflector 执行层，2026-08-14 起替代已退役的 pi）
#
# 定位：Claude Code 在前台干活 → session-refs.jsonl 登记 → 本脚本用 hermes 把会话蒸馏成提案。
#   产出只到 ops/proposals/ + ops/log/reconcile.jsonl；入库仍须人审 evo curate（I3）。
#   fail-open：任何一步失败都不标记 distilled，下次照常重试；绝不阻塞前台。
#
# 后端：hermes -z（--yolo 免审批，模型 pin deepseek-v4-pro，经现有 nanoradar 中转，不改路由）。
#
# 用法：
#   ops/bin/evo-distill.sh                 处理队列（默认最多 2 个会话）
#   ops/bin/evo-distill.sh --max 5         本轮最多处理 5 个
#   ops/bin/evo-distill.sh --session <sid> 只处理指定会话（忽略体量门槛）
#   ops/bin/evo-distill.sh --dry-run       只打印将处理什么，不调 pi
#
# 环境变量：EVO_DISTILL_TIMEOUT（基数秒数，默认 1800）、EVO_DISTILL_TIMEOUT_PER_100KB（每 100KB 增量，默认 100）、
#          EVO_DISTILL_TIMEOUT_CAP（上限秒数，默认 5400）、EVO_DISTILL_MIN_BYTES（默认 50000）
#          预算按体量放大：实测 214KB 需 ~2040s、1MB 需 ~2820s，固定预算会切掉正常会话。
#          EVO_DISTILL_JOBS（并发 worker 数，默认 1，`auto` 按队列长度分档见下）
#          EVO_HERMES_PY / EVO_HERMES_BIN（覆盖执行器路径，供沙箱回归用）

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# EVO 路径可被环境覆盖：沙箱回归时 ROOT 是个副本，副本里的 bin/evo 可能跑不起来
# （smoke 的 rsync 故意排除 node_modules → require('js-yaml') 直接 MODULE_NOT_FOUND）。
EVO="${EVO_DISTILL_EVO:-$ROOT/bin/evo}"
LOG="$ROOT/ops/log/distill.log"
LOCK="$ROOT/ops/log/.distill.lock"
TIMEOUT="${EVO_DISTILL_TIMEOUT:-1800}"
# 单会话超时预算 = 基数 + 体量增量，封顶 CAP —— 三条都有实测依据（2026-09-17/18，本机）：
#   ① 基数：旧默认 900s 会把**正常完成中**的会话当超时杀掉；214KB 会话实测需 2040s。
#   ② 斜率：两个实测点（219518B→2040s、1048613B→2820s）线性拟合得 94s/100KB，取整 100s/100KB；
#       用 MB 整除做单位是错的 —— 队列主体是 200–800KB，整除后恒为 0，等于没加预算。
#   ③ 封顶：队列里有 20–44MB 的巨型 transcript，不封顶时预算会胀到 6–13 小时，一条会话把队列堵死。
TIMEOUT_PER_100KB="${EVO_DISTILL_TIMEOUT_PER_100KB:-100}"
TIMEOUT_CAP="${EVO_DISTILL_TIMEOUT_CAP:-5400}"
POLL="${EVO_DISTILL_POLL:-5}"      # 看门狗轮询间隔（秒，可小数）
MIN_BYTES="${EVO_DISTILL_MIN_BYTES:-50000}"

MAX=2
ONLY=""
DRY=0
SLOT=""          # 并行 worker 的槽位号（0-based），空 = 跑单进程
SLOTS=1
while [ $# -gt 0 ]; do
  case "$1" in
    --max) MAX="$2"; shift 2 ;;
    --session) ONLY="$2"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --slot) SLOT="$2"; shift 2 ;;        # 仅供 runner 内部使用（worker 模式）
    --slots) SLOTS="$2"; shift 2 ;;
    *) echo "未知参数: $1" >&2; exit 0 ;;   # fail-open
  esac
done

# 并发度。默认 1（保持原单实例语义）；>1 时本进程只当 runner，播 N 个自身副本当 worker，
# 每个 worker 取队列的一个互不重叠切片（同余类，见下方切片处）。
# EVO_DISTILL_JOBS=auto —— 按**本轮窗口大小**（--max）分档，给无人值守的定时任务用：
#   --max <8 → 2；8–39 → 3；40–99 → 4；≥100 → 6。
#   口径是「这一轮打算做多少条」而不是「队列里积了多少条」：worker 数该跟本轮工作量走，
#   否则队列很长但只跑 2 条时也会开 6 路，白占 provider 与内存。
#   分档是**保守的工程选择**，不是实测最优：1 并发时也见过 provider 报错，
#   在没有 provider 侧并发实测前不往上冲（每倒退一次要重烧一整轮额度）。
# 上限 8 是保护：每个 worker 是一个 hermes 进程（+ mcp 子进程），共享同一 provider 与
# 同一份 session-refs.jsonl（写路径已加跨进程锁，见 bin/evo 的 withFileLock）。
JOBS="${EVO_DISTILL_JOBS:-1}"
if [ "$JOBS" = "auto" ]; then
  QN=$("$EVO" queue --min-bytes "$MIN_BYTES" 2>/dev/null | tail -n "$MAX" | grep -c . || true)
  if   [ "$QN" -ge 100 ]; then JOBS=6
  elif [ "$QN" -ge 40 ];  then JOBS=4
  elif [ "$QN" -ge 8 ];   then JOBS=3
  else JOBS=2
  fi
fi
case "$JOBS" in ''|*[!0-9]*) JOBS=1 ;; esac
[ "$JOBS" -lt 1 ] && JOBS=1
[ "$JOBS" -gt 8 ] && { echo "EVO_DISTILL_JOBS 上限 8，已夹到 8（要更高得先有 provider 侧实测）" >&2; JOBS=8; }

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$LOG"; }

# 单会话超时秒数（基数 + 体量×斜率，封顶）。依据见 TIMEOUT_PER_100KB 处注释。
budget_for() {
  local b=$(( TIMEOUT + ( ${1:-0} / 100000 ) * TIMEOUT_PER_100KB ))
  [ "$b" -gt "$TIMEOUT_CAP" ] && b="$TIMEOUT_CAP"
  echo "$b"
}

# 浮点比较（bash 3.2 无浮点算术）：$1 >= $2 为真时返 0。
ge() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>=b)}'; }

# 递归回收进程树。hermes 自己会派生 mcp_ 子进程（实测 PPID 链 hermes → tools/mcp_*），
# 只 kill 本体一样留孤儿。
kill_tree() {
  local p="$1" c
  for c in $(pgrep -P "$p" 2>/dev/null); do kill_tree "$c"; done
  kill -9 "$p" 2>/dev/null
}

HERMES_PY="${EVO_HERMES_PY:-/Users/zodyne/.hermes/hermes-agent/venv/bin/python}"
HERMES_BIN="${EVO_HERMES_BIN:-/Users/zodyne/.hermes/hermes-agent/hermes}"
# 可被环境覆盖（EVO_HERMES_PY / EVO_HERMES_BIN）：不覆盖就只能拿真 hermes 跑集成，
# 非并行切片/锁/哨兵判定这些**机制**没法在沙箱里回归（2026-09-18 加并发后补上）。
[ -x "$HERMES_PY" ] && [ -f "$HERMES_BIN" ] || { log "skip: hermes 不在"; exit 0; }

# 单实例：mkdir 是原子的。锁超过 2 小时视为残留（上次被 kill -9），清掉重来。
# worker 模式（--slot）**不抢锁**：锁已由 runner（它的父进程）持有，抢锁就等于把自己拒之门外。
# 锁的建立/心跳/释放全部由 runner 负责。
if [ -z "$SLOT" ]; then
# 锁路径必须是个**目录**：心跳用 `touch "$LOCK"`，一旦 LOCK 被 touch 成普通文件，
# mkdir 永远 EEXIST、而 `[ -d ]` 又不成立 → 每一轮都报「已有实例在跑」且**永不恢复**。
# 2026-09-18 实测到这个形状：外部 rm -rf 掉锁目录后，还活着的实例下一次心跳就用
# touch 造出一个同名空文件；随后新起的驱动器全部被挡，日志里只看得见「已有实例在跑」。
if [ -e "$LOCK" ] && [ ! -d "$LOCK" ]; then
  log "锁路径被非目录占用（异常残留，多为 touch 误造），清除：$LOCK"
  rm -f "$LOCK"
fi
if ! mkdir "$LOCK" 2>/dev/null; then
  if [ -d "$LOCK" ] && [ -z "$(find "$LOCK" -maxdepth 0 -mmin -120 2>/dev/null)" ]; then
    log "清理残留锁"; rm -rf "$LOCK"; mkdir "$LOCK" 2>/dev/null || exit 0
  else
    log "skip: 已有实例在跑"; exit 0
  fi
fi
echo $$ > "$LOCK/pid" 2>/dev/null || true
# 只删自己持有的锁：残留锁被别的实例清理重建后，无条件 rm -rf 会删掉**对方**的锁。
# 2026-09-15 实测：本实例跑到 5.5h（休眠把墙钟拉长）→ launchd 按 120min 判残留、清锁并发起
# 第二个实例 → 先退出的一方无条件删锁 → 出现「无锁并跑」。判定凭据写进 $LOCK/pid。
trap 'if [ "$(cat "$LOCK/pid" 2>/dev/null)" = "$$" ]; then rm -rf "$LOCK"; fi' EXIT
fi

# ── runner 模式（JOBS>1）：拿完锁就直接播 worker，**不自己跑队列** ────────
# 位置很关键：这段必须在「取队列 + 主循环」**之前**。放后面的话 runner 会先用全量队列
# 跑一遍单会话逻辑，再播 worker 把同一批再跑一遍（同一份队列被处理两次）。
if [ -z "$SLOT" ] && [ "$JOBS" -gt 1 ]; then
  SELF="$ROOT/ops/bin/evo-distill.sh"
  if [ "$DRY" = 1 ]; then
    echo "would run $JOBS parallel workers (max $MAX each slice of the queue)"
    exit 0
  fi
  log "并行启动 $JOBS 个 worker（本轮至多 $MAX 条，体量门槛 ${MIN_BYTES}B）"
  child_pids=""
  i=0
  while [ "$i" -lt "$JOBS" ]; do
    EVO_DISTILL_JOBS=1 "$SELF" --slot "$i" --slots "$JOBS" --max "$MAX" >> "$LOG" 2>&1 &
    child_pids="$child_pids $!"
    i=$((i + 1))
  done
  # 等全部 worker，同时拿心跳把锁按活（worker 卡住时别让锁被另一个实例判成残留）。
  for p in $child_pids; do
    while kill -0 "$p" 2>/dev/null; do touch "$LOCK" 2>/dev/null || true; sleep 5; done
  done
  log "并行轮结束（$JOBS 个 worker，至多 $MAX 条）"
  exit 0
fi

# ── 取待处理清单（TSV: session \t transcript \t harness \t bytes）──
# 失败**不能**静默成「队列为空」：2026-09-18 实测过这个形状 —— 沙箱里 evo 因缺 node_modules
# 直接崩，而这里当时是 `2>/dev/null`，于是驱动器一本正经地报「队列为空」（真实队列有 140 条），
# 与「distill.log 停在 8-25 而 20 天无人发现」是同一类故障：坏的那一侧不吭声。
if [ -n "$ONLY" ]; then
  QUEUE=$("$EVO" queue --min-bytes 0 2>/dev/null | awk -F'\t' -v s="$ONLY" '$1==s')
else
  QERR="$ROOT/ops/log/.distill-queue.err"
  QOUT=$("$EVO" queue --min-bytes "$MIN_BYTES" 2>"$QERR"); QRC=$?
  [ "$QRC" = 0 ] || log "queue 取列表失败 rc=$QRC: $(head -c 200 "$QERR" 2>/dev/null | tr '\n' ' ')"
  QUEUE=$(printf '%s\n' "$QOUT" | tail -n "$MAX")
fi

# 并行切片：slot i 取第 i 个同余类（i, i+N, i+2N, ...）。
# 同余类而不是连续块 —— 队列是按体量排序的，连续块会让一个 worker 全拿巨型会话、
# 另一些全拿小会话，整轮时长被最慢那个决定。取模能交叉大小会话。
if [ "$SLOTS" -gt 1 ] && [ -n "$SLOT" ] && [ -n "$QUEUE" ]; then
  QUEUE=$(printf '%s\n' "$QUEUE" | awk -v i="$SLOT" -v n="$SLOTS" 'NR % n == i')
fi
[ -n "$QUEUE" ] || { log "队列为空"; exit 0; }

DONE=0
while IFS=$'\t' read -r SID FILE HARNESS BYTES; do
  [ -n "${SID:-}" ] && [ -f "${FILE:-}" ] || continue

  if [ "$DRY" = 1 ]; then
    echo "would distill: $SID  ($HARNESS, $BYTES bytes)  $FILE"
    continue
  fi

  log "start $SID ($HARNESS, $BYTES bytes)"

  # 注意：变量一律写 ${X}。中文全角标点是多字节，紧跟 $X 会被 bash 吞进变量名（set -u 下直接报 unbound）。
  PROMPT="你是 Evo-Kernel 的后台 Reflector。对一个已结束的会话做蒸馏，产出提案，不入库。

内核根目录：${ROOT}
evo CLI（不在 PATH，必须用绝对路径）：${EVO}
会话文件：${FILE}
session_id：${SID}

按顺序做：

1. 跑 \`${EVO} slice --session ${FILE} --ids ${SID}\`。**只基于它的输出工作**，禁止凭记忆、猜测或常识补写经验。

2. 切片开头 \`injected:\` 行列出本次**词法自动注入**过的条目 id。逐个判四态并写入：
   \`${EVO} reconcile --ids <id> --state <adopted|relevant-unused|irrelevant|misleading> --session ${SID}\`
   判据：adopted=切片里有证据显示这条被遵循；relevant-unused=与任务相关但证据里没用上；irrelevant=与任务无关；misleading=导致返工或错误结论。
   \`injected: (无)\` 时跳过本步。

2b. 切片开头 \`agentic-picked:\` 行列出**你自己用 \`evo get\` 拉取过**的条目 id（2026-09-14 起记录）。
   这批要**单独对账** —— 它走的是另一条通道，必须分开统计精度：
   \`${EVO} reconcile --ids <id> --state <四态> --session ${SID} --channel agentic\`
   判据名词同上，但**问的问题不同**：自动注入是你没选就被塞进来的；这批是你**主动挑的** —— 要问「我挑得对不对」，并拿切片里的证据说清它有没有真派上用场。
   \`agentic-picked: (无)\` 时跳过本步。
   ⚠️ **别把两批混进同一句 reconcile**：混了就把两条通道合成一个数，
   而实测它们 precision 差 18pp（词法 53% vs agent 自选 71%）—— 合成后无法判断该优化哪条。

3. 先定主张，再查重。把切片里**有硬证据支撑**的经验各归纳成一句话主张，然后对每条主张查重：
   \`${EVO} catalog | grep -i -E '<主张里的关键词1|关键词2>'\`
   catalog 是 TSV（id / 区 / triggers），一条一行，涵盖**已入库条目和 ops/proposals 里待审的提案**。
   **不要整份读它**——只 grep 你要查的关键词；库会长到几百条，全读会挤爆上下文。
   多试几个词：技术名（pandoc / gsub / launchd）、失败现象（乱码 / 挂死 / 静默）、领域（nvim / latex）。
   - 命中且**主张相同** → 不写提案。已有条目更全面就直接跳过；你的证据更硬或edge case 更明确，
     也不要另起一条，在输出里写一行 \`DUP <已有id> <你本来想写的slug>\` 让人去决定要不要补强原条目。
   - 命中但**主张不同**（同工具不同坑）→ 照写，这不是重复。
   - 没命中 → 照写。

4. 写提案。每条一个文件：${ROOT}/ops/proposals/<YYYY-MM-DD>-<slug>.md
   - frontmatter 严格按 ${ROOT}/SCHEMA.md 的 14 字段；**triggers 必填 3-5 条**（面向未来任务的措辞 + 失败信号）；
   - status: candidate；evidence: {helpful: 0, harmful: 0}；source: session:${SID}；
   - verified_by 如实标：切片里有命令+结果佐证 → command；只有人的判断 → human；都没有 → 不要写这条提案；
   - 一条提案一个原子主张，禁止把多条揉进一个文件；失败教训与成功经验同等蒸馏。
   **没有够硬的证据就不写提案——宁可零产出，不要编造。**

5. 最后一行输出：\`DISTILL_OK <实际写出的提案数>\`（被查重跳过的不计入）

禁止：运行 \`${EVO} curate\`（入库必须人审）；修改 ops/proposals/ 与 ops/log/ 以外的任何文件；git commit / git push。"

  OUT="${ROOT}/ops/log/.distill-${SID}.out"
  # </dev/null 不能省：循环体的 stdin 是末尾的 here-string，hermes 继承后会把剩余队列行全读走，
  # 导致无论 --max 多大都只转一圈（且退出码 0，看起来像"队列处理完了"）。
  # --yolo 免审批（launchd 无人值守）；-m pin deepseek-v4-pro，--provider 必须显式（裸 -m 不报 provider 会 No LLM provider configured）。
  # EVO_DRIVER=1：告诉 evo 的 hook/CLI「这不是真实会话」——否则驱动器会把自己登记进待蒸馏队列、
  # 还会把自己的 get/candidates 记成 agentic 使用量（自污染反馈环，2026-09-15 实测 6 条/1.5 天）。
  # exec 不能省：不 exec 时 "$!" 是**包装子 shell** 的 pid，看门狗的 kill -9 只杀壳，
  # hermes 变成无超时保护的孤儿继续跑（2026-09-18 实证：01a099a8 被杀于 13:44:03Z，
  # 孤儿 16 min 后才写完 6 条提案 + DISTILL_OK）。exec 后子 shell **变成** hermes，$! 即本体。
  ( cd "$ROOT" && exec env EVO_DRIVER=1 "$HERMES_PY" "$HERMES_BIN" -z "$PROMPT" -m deepseek-v4-pro --provider deepseek-internal --yolo > "$OUT" 2>&1 < /dev/null ) &
  PID=$!
  LIMIT=$(budget_for "${BYTES:-0}")

  # 看门狗：超时整树回收，避免 launchd 下无人值守的挂死。
# 预算按**醒着的秒数**累加（不是墙钟）：机器休眠时 hermes 也停摆，
# 拿墙钟计会把「睡前起、醒来收」的正常会话当成超时（实测有过 5.5h 的假超时）。
# 轮询间隔可调（EVO_DISTILL_POLL，默认 5s）—— 测试里给小数，否则一条会话光轮询就等 5s。
  WAITED=0
  while kill -0 "$PID" 2>/dev/null; do
    touch "$LOCK" 2>/dev/null || true   # 心跳：活着的长会话不该被别的实例按 mtime 误判为残留锁
    ge "$WAITED" "$LIMIT" && { kill_tree "$PID"; log "timeout $SID (${LIMIT}s)"; break; }
    sleep "$POLL"; WAITED=$(awk -v w="$WAITED" -v p="$POLL" 'BEGIN{printf "%.1f", w+p}')
  done
  wait "$PID" 2>/dev/null; RC=$?

  # 成功判据以 .out 里的 DISTILL_OK 哨兵为准，rc 只进日志。
  # 哨兵是提示词里约定的完成契约（最后一行 `DISTILL_OK <n>`），而 rc 会被看门狗的超时 kill
  # 打脏：01a099a8 被杀成 rc=137，同一份 .out 里却有完整的 `DISTILL_OK 6` —— 只按 rc 判会把
  # 一份**已经做完**的蒸馏丢回队列重跑（catalog 的 DUP 只挡重复入库，挡不住重算的额度）。
  # 匹配 "^DISTILL_OK <n>" 而非裸词：提示词自身含该词，避免回显类输出造成假阳性。
  if grep -qE '^DISTILL_OK [0-9]+' "$OUT" 2>/dev/null; then
    "$EVO" mark-distilled --ids "$SID" >/dev/null 2>&1
    # DUP 行留档：查重跳过的主张也是信息（可能该去补强已有条目），别随 .out 一起删掉
    DUPS=$(grep -o '^DUP .*' "$OUT" | sed 's/^/  /')
    log "done $SID — $(grep -o 'DISTILL_OK.*' "$OUT" | tail -1)${DUPS:+ | 查重跳过 $(printf '%s' "$DUPS" | grep -c .) 条}"
    [ -n "$DUPS" ] && printf '%s\n' "$DUPS" >> "$LOG"
    rm -f "$OUT"
    DONE=$((DONE + 1))
  else
    # 不标记 → 下轮重试。输出留档供排查。
    log "fail ${SID} rc=${RC}（未标记，将重试）见 ${OUT##*/}"
  fi
done <<< "$QUEUE"

# grep -c . 在零命中时自己会打印 "0" 并以 1 退出，再接 `|| echo 0` 会多打一行 "0"（日志里挂个孤零的 0）。
[ "$DRY" = 1 ] || log "本轮完成 $DONE 个；剩余队列 $("$EVO" queue --min-bytes "$MIN_BYTES" 2>/dev/null | grep -c . || true)"
