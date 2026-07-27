#!/usr/bin/env bash
# SessionEnd 触发器：会话一结束就脱离 hook 起后台蒸馏，把「登记 → 蒸馏」之间的
# transcript 腐烂窗口压到接近零（哨兵率 52% 的根因）。
#
# 必须立刻返回：hook 超时 5s，pi 一跑就是几分钟，所以 detach 后马上 exit 0。
# 每次只处理 1 个会话（体量门槛之上的最新一条）；积压由 launchd 每日兜底清。
# 停用方式：删掉 ~/.claude/settings.json 里 SessionEnd 的这条 hook；或 touch 下面的开关文件。

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[ -f "$ROOT/ops/log/.distill-off" ] && exit 0
nohup "$ROOT/ops/bin/evo-distill.sh" --max 1 >/dev/null 2>&1 &
exit 0
