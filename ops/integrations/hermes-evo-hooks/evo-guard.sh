#!/usr/bin/env bash
# evo-guard.sh — Hermes pre_tool_call → evo hook-guard adapter
# Hermes stdin: {hook_event_name, tool_name, tool_input:{command|path}, ...}
# evo 期望:     {tool_name, tool_input}（字段同名透传）
# evo 输出:     Claude 格式 {hookSpecificOutput:{permissionDecision:'deny',...}}
#              或 {systemMessage:...}（warn）或空（allow）
# 输出转换:     deny → {"decision":"block","reason":...}
#              warn/allow → {} （Hermes 无 systemMessage 概念；fail-open I1）
set -uo pipefail
EVO="${EVO_BIN:-$HOME/Dev/evo-kernel/bin/evo}"
payload="$(cat -)"
tool="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"
tool_input="$(printf '%s' "$payload" | jq -c '.tool_input // {}' 2>/dev/null || printf '{}')"
cli_payload="$(jq -n --arg t "$tool" --argjson i "$tool_input" '{tool_name:$t, tool_input:$i}')"
out="$(printf '%s' "$cli_payload" | "$EVO" hook-guard 2>/dev/null || true)"
decision="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null || true)"
if [[ "$decision" == "deny" ]]; then
  reason="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason // "blocked by evo-guard"' 2>/dev/null || echo 'blocked by evo-guard')"
  jq -n --arg r "$reason" '{decision:"block", reason:$r}'
else
  printf '{}\n'
fi
