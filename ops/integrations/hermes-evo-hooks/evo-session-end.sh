#!/usr/bin/env bash
# evo-session-end.sh — Hermes on_session_end → evo hook-session-end adapter
# Hermes stdin: {hook_event_name, session_id, extra:{completed,interrupted,...}}
# evo 期望:     {session_id, transcript_path?, harness}（ended=true 由 session-end 置位）
# 输出:         {} (Hermes 静默)
# I1 fail-open: 失败不阻断。
set -uo pipefail
EVO="${EVO_BIN:-$HOME/Dev/evo-kernel/bin/evo}"
payload="$(cat -)"
sid="$(printf '%s' "$payload" | jq -r '.session_id // empty')"
if [[ -z "$sid" ]]; then printf '{}\n'; exit 0; fi
cli_payload="$(jq -n --arg s "$sid" '{session_id:$s, transcript_path:"?", harness:"hermes"}')"
printf '%s' "$cli_payload" | "$EVO" hook-session-end >/dev/null 2>&1 || true
printf '{}\n'
