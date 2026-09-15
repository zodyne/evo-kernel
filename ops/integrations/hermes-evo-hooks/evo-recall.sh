#!/usr/bin/env bash
# evo-recall.sh — Hermes pre_llm_call → evo hook-recall adapter
# Hermes stdin: {hook_event_name, session_id, extra:{user_message,...}}
# evo 期望:     {session_id, transcript_path?, prompt|message, harness}
# 输出:         {"context": "<recall 结果>"}  (Hermes pre_llm_call 注入契约)
# I1 fail-open: 任何失败输出 {} 不阻断。
set -uo pipefail
EVO="${EVO_BIN:-$HOME/Dev/evo-kernel/bin/evo}"
payload="$(cat -)"
sid="$(printf '%s' "$payload" | jq -r '.session_id // empty')"
msg="$(printf '%s' "$payload" | jq -r '.extra.user_message // .extra.prompt // empty')"
if [[ -z "$sid" || -z "$msg" ]]; then printf '{}\n'; exit 0; fi
# 兜底（不依赖 env 传播）：蒸馏驱动器的 prompt 是固定哨兵 —— 不检索、不记 recall。
# 主防线是 EVO_DRIVER=1（由 evo-distill.sh 注入），这里防 env 传不到 hook 的场景。
case "$msg" in
  *"Evo-Kernel 的后台 Reflector"*) printf '{}\n'; exit 0 ;;
esac
# transcript_path: Hermes 会话存 SQLite 无文件路径 → 传 '?' 哨兵（evo 支持），
# 二期用 `hermes sessions export <id>` 落盘后填真实路径。
cli_payload="$(jq -n --arg s "$sid" --arg p "$msg" '{session_id:$s, transcript_path:"?", prompt:$p, harness:"hermes"}')"
out="$(printf '%s' "$cli_payload" | "$EVO" hook-recall 2>/dev/null || true)"
if [[ -n "$out" ]]; then
  jq -n --arg c "$out" '{context:$c}'
else
  printf '{}\n'
fi
