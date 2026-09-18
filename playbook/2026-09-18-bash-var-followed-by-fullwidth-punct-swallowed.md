---
id: bash-var-followed-by-fullwidth-punct-swallowed
type: lesson
status: validated
scope: global
domain: shell
tags: [bash, set-u, unbound-variable, multibyte, fullwidth, cjk, macos]
triggers:
  - "写含中文提示语的 bash 脚本：`echo \"值=$VAR（…\"` 这种变量紧跟全角标点的拼接"
  - "set -u 下脚本报 unbound variable，但报错里的变量名是断字节/乱码，grep 不到自己写过的变量（失败信号）"
  - "脚本 rc=127 且 stderr 只有一行 unbound variable，翻遍脚本找不到哪个变量没赋值"
  - "中文文本插值后的输出里变量值凭空消失、旁边多出乱码字节，脚本却是 rc=0（失败信号）"
  - "在 macOS 自带 bash（/bin/bash 3.2）上写 printf/echo 中文提示"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b35a-0deb-73b1-bdd8-c2e05c5d556f
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

**主张**：在 bash（本机 `/bin/bash` 3.2.57，UTF-8 locale）里，`$VAR` **紧跟全角（多字节）标点**时，全角字符的字节会被并进变量名——`set -u` 下直接 `unbound variable` 中止（rc=127，报错里的变量名是断字节，照字面 grep 不到）；不带 `set -u` 时更隐蔽：变量被当"未赋值"展开为空、变量名的残余字节被原样打进输出，**rc=0 静默产出错内容**。变量紧跟中文/全角字符时一律写成 `${VAR}`。

**为什么**：bash 的标识符解析是**按字节**走的，不认 UTF-8 多字节边界；在 UTF-8 locale 下 `isalpha()` 把全角标点的首字节也判成字母，于是 `$Q（` 被解析成变量 `Q\xef\xbc\x88` 而不是 `$Q`。脚本里中文成句时（提示语、注释里的示例、printf 拼接）这个形态到处都是，而报错只给一个断字节名字，人眼根本对不上。

**证据（本次蒸馏当场复现，macOS bash 3.2.57，LANG/LC_CTYPE=en_US.UTF-8）**：
- `set -u` 档：`/bin/bash -c 'set -u; Q=5; echo "val=$Q（x）"'` → `/bin/bash: Q<乱码字节>: unbound variable`，`rc=127`（全角冒号同形：`"val=$Q：done"` 同样 unbound）。
- 无 `set -u` 档：`/bin/bash -c 'Q=5; echo "val=$Q（x）"'` → `val=��x）`，`rc=0`——变量值 5 消失、多出乱码字节，**不报错**。
- 对照（都不触发）：`${Q}（x）` → `val=5（x）`；ASCII 标点 `$Q(x)` / `$Q-done` → `val=5(x)` / `val=5-done`；`/bin/zsh -c 'set -u; Q=5; echo "val=$Q（x）"'` → `val=5（x）`。
- 会话内出处（session 01a0b35a 切片，`sed -n '1,30p' ops/bin/evo-drain.sh`）：该文件头部注释第 19–20 行自己写明这个坑——「本文件所有「变量紧跟全角字符」之处一律写 ${VAR}。中文全角标点是多字节，`$Q1（` 会被 bash 吞进变量名（set -u 下报 unbound）。这个坑 2026-09-18 一天内踩了三次（smoke 自己、evo-distill.sh、本文件），现在 test/smoke.sh 有静态 lint 兜住」；仓库侧防线是 `test/smoke.sh:927` 的 `L: shell 脚本无 $VAR 紧跟多字节字符（应为 ${VAR}）`。

**反例 / 边界**：
- 触发条件是「`$` 紧贴多字节字符」：`${VAR}（`、`$VAR (x)`（留空格）、ASCII 标点都正常。
- **locale 相关**：`LC_ALL=C /bin/bash -c 'set -u; Q=5; echo "val=$Q（x）"'` → `val=5（x）`（正常）。同一台机器的日常环境是 `en_US.UTF-8`，所以按直觉写就会踩；别把它当成"bash 一律如此"。
- 只在本机 `/bin/bash` 3.2.57 上验证；换 bash 5 / 别的平台未验证。
- 排查方法：不要拿报错里的变量名去 grep 变量定义（那是断字节），改搜「`$` 后面紧跟非 ASCII」的片段。
- 仓库内 shell 脚本已被 `test/smoke.sh` 的 lint 兜住，但一次性命令行、别的项目脚本没有这层保护——新写脚本时可以照抄同一道 lint。
