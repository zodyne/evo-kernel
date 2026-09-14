#!/usr/bin/env bash
# evo-session-end.sh — Hermes on_session_end → evo hook-session-end adapter
# Hermes stdin: {hook_event_name, session_id, extra:{completed,interrupted,...}}
# evo 期望:     {session_id, transcript_path?, harness}（ended=true 由 session-end 置位）
# 输出:         {} (Hermes 静默)
# I1 fail-open: 失败不阻断。
#
# 二期（2026-09-14）：把 Hermes 会话导出为 JSONL 并回填真实 transcript 路径。
#
# 此前硬编码 transcript_path:"?"，后果不是"少一条记录"，而是 **hermes 的每一次注入
# 都永久落在「结构性不可对账」**：没有 transcript → `evo slice` 无输入 → 蒸馏器判不了
# 四态 → 对账覆盖率永远上不去，而 reflect 会把这件事归因成「先修蒸馏纪律」。
# evo 的 registerSession 本就有**哨兵单向升级**机制（'?' → 真实路径；首登记时文件
# 还没落盘、结束时才有），这里正是它的用武之地 —— 不必改动 evo-recall.sh（那个每轮
# 都跑，每轮导出会很贵）。
#
# 导出文件含 prompt 明文 → 落在仓库外且不进 git（同 §4.4 红线口径，见 .gitignore）。
# 2026-09-14 同时移除 gbrain 双写调用：gbrain 已退役（~/.gbrain、CLI、postgres 均已移除），
# 该脚本 `~/brain/gbrain-session-write.sh` 已不存在，是一次被 `|| true` 吞掉的死调用。
set -uo pipefail
EVO="${EVO_BIN:-$HOME/Dev/evo-kernel/bin/evo}"
HERMES_PY="${HERMES_PY:-$HOME/.hermes/hermes-agent/venv/bin/python}"
HERMES_BIN="${HERMES_BIN:-$HOME/.hermes/hermes-agent/hermes}"
EXPORT_DIR="${HERMES_SESSION_EXPORT_DIR:-$HOME/.hermes/sessions-export}"
payload="$(cat -)"
sid="$(printf '%s' "$payload" | jq -r '.session_id // empty')"
if [[ -z "$sid" ]]; then printf '{}\n'; exit 0; fi

# 导出会话为 JSONL。失败/空产物则退回 '?' 哨兵 —— 与改动前行为一致，绝不阻断。
transcript="?"
if [[ -x "$HERMES_PY" && -f "$HERMES_BIN" ]]; then
  mkdir -p "$EXPORT_DIR" 2>/dev/null || true
  out="$EXPORT_DIR/$sid.jsonl"
  "$HERMES_PY" "$HERMES_BIN" sessions export --format jsonl --session-id "$sid" "$out" >/dev/null 2>&1 || true
  [[ -s "$out" ]] && transcript="$out"
fi

cli_payload="$(jq -n --arg s "$sid" --arg t "$transcript" '{session_id:$s, transcript_path:$t, harness:"hermes"}')"
printf '%s' "$cli_payload" | "$EVO" hook-session-end >/dev/null 2>&1 || true
printf '{}\n'
