#!/usr/bin/env bash
# evo-drain —— 连续跑蒸馏轮，直到队列追平。
#
# 定位：`evo-distill.sh` 是「跑一轮」；本脚本是「一直跑到队列见底」。
#   2026-09-18 立：日流入 ~70 条（实测 09-15/16/17 = 70/64/71），而单轮产能是
#   `--max 48` + launchd 兜底 `--max 12` = 60 条/天 → 靠定时任务**永远追不上**，
#   队列只会单调增长。用户口径：「先不动日程，把队列追平」——所以需要一段连续处理，
#   而不是把定时任务改得更激进（后者是长期产能问题，另说）。
#
# 停止条件（任一命中即退出；**必须有**，见 lessons 里 open-ended-task-plus-tools-has-no-stop-condition）：
#   --until N         队列 ≤ N 条（默认 5）
#   --budget-hours H  总墙钟预算（默认 12 小时；防无人值守跑成通宵）
#   --max-empty N     连续 N 轮零进展就退出（默认 3；防死循环打空转）
#
# 与定时任务的关系：两者共用 `ops/log/.distill.lock`，谁先拿到谁跑、另一个 skip，
#   **不会并跑**。本脚本不持锁，只在开跑前等释放（且只等"新鲜"的锁——残留锁交给
#   evo-distill.sh 自己的 120 分钟残留判定去清，否则这里会等到天荒地老）。
#
# ⚠ 本文件所有「变量紧跟全角字符」之处一律写 ${VAR}。中文全角标点是多字节，`$Q1（`
#   会被 bash 吞进变量名（set -u 下报 unbound）。这个坑 2026-09-18 一天内踩了三次
#   （smoke 自己、evo-distill.sh、本文件），现在 test/smoke.sh 有静态 lint 兜住。
#
# 用法：
#   ops/bin/evo-drain.sh                    # 直到队列 ≤5 或 12 小时预算用尽
#   ops/bin/evo-drain.sh --until 20 --budget-hours 3
# 环境变量：EVO_DRAIN_ROUND_MAX（单轮 --max，默认 48）、EVO_DISTILL_MIN_BYTES（体量门槛）、
#           EVO_DISTILL_JOBS（并发度，透传给 evo-distill.sh，默认 auto）

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVO="${EVO_DRAIN_EVO:-$ROOT/bin/evo}"
DISTILL="$ROOT/ops/bin/evo-distill.sh"
LOG="$ROOT/ops/log/drain.log"
LOCK="$ROOT/ops/log/.distill.lock"
MIN_BYTES="${EVO_DISTILL_MIN_BYTES:-50000}"
ROUND_MAX="${EVO_DRAIN_ROUND_MAX:-48}"
JOBS="${EVO_DISTILL_JOBS:-auto}"

UNTIL=5
BUDGET_H=12
MAX_EMPTY=3
while [ $# -gt 0 ]; do
  case "$1" in
    --until) UNTIL="$2"; shift 2 ;;
    --budget-hours) BUDGET_H="$2"; shift 2 ;;
    --max-empty) MAX_EMPTY="$2"; shift 2 ;;
    --round-max) ROUND_MAX="$2"; shift 2 ;;
    *) echo "未知参数: $1" >&2; exit 0 ;;   # fail-open
  esac
done

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$LOG"; }

[ -x "$DISTILL" ] || { log "skip: ${DISTILL} 不可执行"; exit 0; }

qlen() { "$EVO" queue --min-bytes "$MIN_BYTES" 2>/dev/null | grep -c . || true; }

# 只在「锁存在且新鲜」时等：残留锁（>120min）由 evo-distill.sh 负责清理，
# 这里若也按残留处理就会两边都去清、反而制造竞态。
lock_held() {
  [ -d "$LOCK" ] || return 1
  [ -n "$(find "$LOCK" -maxdepth 0 -mmin -120 2>/dev/null)" ]
}

START=$(date +%s)
ROUND=0
EMPTY=0
log "=== drain 启动（until=${UNTIL} budget=${BUDGET_H}h round-max=${ROUND_MAX} jobs=${JOBS} 门槛=${MIN_BYTES}B）==="

while :; do
  ELAPSED_H=$(( ($(date +%s) - START) / 3600 ))
  if [ "$ELAPSED_H" -ge "$BUDGET_H" ]; then
    log "预算用尽（已 ${ELAPSED_H}h ≥ 上限 ${BUDGET_H}h），退出；队列 $(qlen) 条"
    break
  fi

  Q0=$(qlen)
  if [ "$Q0" -le "$UNTIL" ]; then
    log "队列已追平（余 ${Q0} 条 ≤ 阈值 ${UNTIL} 条），退出"
    break
  fi

  if lock_held; then
    log "等锁中（pid=$(cat "$LOCK/pid" 2>/dev/null || echo '?') 持有，队列仍 ${Q0} 条）"
    sleep 60
    continue
  fi

  ROUND=$((ROUND + 1))
  log "--- 第 ${ROUND} 轮开始：队列 ${Q0} 条，单轮上限 ${ROUND_MAX} ---"
  EVO_DISTILL_JOBS="$JOBS" "$DISTILL" --max "$ROUND_MAX" >> "$LOG" 2>&1

  Q1=$(qlen)
  GAIN=$((Q0 - Q1))
  log "--- 第 ${ROUND} 轮结束：队列 ${Q0} → ${Q1}，净减 ${GAIN} ---"

  if [ "$GAIN" -le 0 ]; then
    EMPTY=$((EMPTY + 1))
    [ "$EMPTY" -ge "$MAX_EMPTY" ] && { log "连续 ${EMPTY} 轮零进展，退出（队列 ${Q1} 条）"; break; }
  else
    EMPTY=0
  fi

  sleep 15   # 让锁与日志落定；也避免上一轮刚退出就被自己立刻重入
done
