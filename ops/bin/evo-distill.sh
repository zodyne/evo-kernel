#!/usr/bin/env bash
# evo-distill —— 后台蒸馏驱动器（pi 作为 Reflector 执行层）
#
# 定位：Claude Code 在前台干活 → session-refs.jsonl 登记 → 本脚本用 pi 把会话蒸馏成提案。
#   产出只到 ops/proposals/ + ops/log/reconcile.jsonl；入库仍须人审 evo curate（I3）。
#   fail-open：任何一步失败都不标记 distilled，下次照常重试；绝不阻塞前台。
#
# 用法：
#   ops/bin/evo-distill.sh                 处理队列（默认最多 2 个会话）
#   ops/bin/evo-distill.sh --max 5         本轮最多处理 5 个
#   ops/bin/evo-distill.sh --session <sid> 只处理指定会话（忽略体量门槛）
#   ops/bin/evo-distill.sh --dry-run       只打印将处理什么，不调 pi
#
# 环境变量：EVO_DISTILL_TIMEOUT（单会话秒数，默认 900）、EVO_DISTILL_MIN_BYTES（默认 50000）

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVO="$ROOT/bin/evo"
LOG="$ROOT/ops/log/distill.log"
LOCK="$ROOT/ops/log/.distill.lock"
TIMEOUT="${EVO_DISTILL_TIMEOUT:-900}"
MIN_BYTES="${EVO_DISTILL_MIN_BYTES:-50000}"

MAX=2
ONLY=""
DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --max) MAX="$2"; shift 2 ;;
    --session) ONLY="$2"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    *) echo "未知参数: $1" >&2; exit 0 ;;   # fail-open
  esac
done

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$LOG"; }

command -v pi >/dev/null 2>&1 || { log "skip: pi 不在 PATH"; exit 0; }

# 单实例：mkdir 是原子的。锁超过 2 小时视为残留（上次被 kill -9），清掉重来。
if ! mkdir "$LOCK" 2>/dev/null; then
  if [ -d "$LOCK" ] && [ -z "$(find "$LOCK" -maxdepth 0 -mmin -120 2>/dev/null)" ]; then
    log "清理残留锁"; rm -rf "$LOCK"; mkdir "$LOCK" 2>/dev/null || exit 0
  else
    log "skip: 已有实例在跑"; exit 0
  fi
fi
trap 'rm -rf "$LOCK"' EXIT

# ── 取待处理清单（TSV: session \t transcript \t harness \t bytes）──
if [ -n "$ONLY" ]; then
  QUEUE=$("$EVO" queue --min-bytes 0 2>/dev/null | awk -F'\t' -v s="$ONLY" '$1==s')
else
  QUEUE=$("$EVO" queue --min-bytes "$MIN_BYTES" 2>/dev/null | tail -n "$MAX")
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

2. 切片开头 \`injected:\` 行列出本次注入过的条目 id。逐个判四态并写入：
   \`${EVO} reconcile --ids <id> --state <adopted|relevant-unused|irrelevant|misleading> --session ${SID}\`
   判据：adopted=切片里有证据显示这条被遵循；relevant-unused=与任务相关但证据里没用上；irrelevant=与任务无关；misleading=导致返工或错误结论。
   \`injected: (无)\` 时跳过本步。

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
  # </dev/null 不能省：循环体的 stdin 是末尾的 here-string，pi 继承后会把剩余队列行全读走，
  # 导致无论 --max 多大都只转一圈（且退出码 0，看起来像"队列处理完了"）。
  ( cd "$ROOT" && pi -p --no-session "$PROMPT" > "$OUT" 2>&1 < /dev/null ) &
  PID=$!

  # 看门狗：超时 kill，避免 launchd 下无人值守的挂死
  WAITED=0
  while kill -0 "$PID" 2>/dev/null; do
    [ "$WAITED" -ge "$TIMEOUT" ] && { kill -9 "$PID" 2>/dev/null; log "timeout $SID (${TIMEOUT}s)"; break; }
    sleep 5; WAITED=$((WAITED + 5))
  done
  wait "$PID" 2>/dev/null; RC=$?

  if [ "$RC" = 0 ] && grep -q 'DISTILL_OK' "$OUT"; then
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

[ "$DRY" = 1 ] || log "本轮完成 $DONE 个；剩余队列 $("$EVO" queue --min-bytes "$MIN_BYTES" 2>/dev/null | grep -c . || echo 0)"
