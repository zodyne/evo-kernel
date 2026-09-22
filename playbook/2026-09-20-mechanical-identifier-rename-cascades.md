---
id: mechanical-identifier-rename-cascades
type: lesson
status: validated
scope: global
domain: refactoring
tags: [cpp, rename, bulk-edit, compile-rounds, string-literals]
triggers:
  - "用脚本对全树做短标识符改名（i→ulI、k→lK、a→ulA 或数组前缀调整）"
  - "改名后编译报 use of undeclared identifier 'i' / 'a' 之类，声明和使用点对不上（失败信号）"
  - "机械替换疑似改到了字符串字面量或注释（如 printf 串里被塞进真实换行）"
  - "需要决定一次批量改名后怎么验证收敛，而不是手工逐个文件看"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4a3-ae96-7475-af70-36ad39adaba4
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [scripted-tree-transform-explodes-revert-first]
---

**主张**：全树机械改名（单字母/短前缀标识符）不是一次脚本能收敛的，应当按**编译轮次**推进：每轮编译 → 把 `use of undeclared identifier` 按标识符聚合（`sort | uniq -c`）→ 修下一批 → 再编译，直到 `err=0`。同时对脚本误伤字符串字面量保持警惕（本会话修过 printf 串里被替换成真实换行的问题）。

**为什么**：改名脚本通常按词边界替换，但同一短名在不同作用域/不同文件里含义不同（局部变量、宏参数、结构体字段、字符串里的文本）；一轮替换后，编译错误恰好是「哪些点没跟上」的清单。逐条看错误太慢，按标识符聚合成 `标识符 → 出现次数` 才能批量定位。

**证据（本会话切片，命令 ↔ 结果）**：

- 改名后多轮收敛（P2d-b）：
  - `C2 回改 OK err=22 tools/check/main.cpp:516:36: error: use of undeclared identifier 'i' ...`
  - `argv 循环剩余 i → lI OK err=14 tools/check/main.cpp:57:29: error: use of undeclared identifier 'i' ...`
  - 另一轮脚本中途抛异常仍报 `err=7`；继续修后 `剩余 i 修 6 build err=0 warn=0`。
- 聚合手段：`grep 'error:' <build.log> | sed ... | grep 'undeclared identifier' | sed ... | sort | uniq -c` 输出如 `2 tools/check/main.cpp:57 i`、`2 tools/check/main.cpp:59 i`、`2 tools/check/main.cpp:76 i`，据此按文件+标识符批量修。
- 字面量误伤：脚本注释写明 `main.cpp:printf 字符串里的真实换行 → \n 转义`，修复记录 `三处修 OK`。

**边界 / 反例**：

- 词边界替换对「同一名字在另一处是别的含义」无能为力，必须靠编译/测试兜底；纯文本改名越到小项目越安全，大项目会级联。
- 如果项目规范允许不同作用域用同一个短名，机械改名的目标本身就模糊，应先在闸门/规范里定死命名规则再改。

**失败信号（未来命中即该想起本条）**：批量改名后报错数只降不收敛、每轮都是 `use of undeclared identifier`；或 diff 里出现被改动的字符串/注释文本。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
$ d=$(mktemp -d); cd "$d"; printf 'int sum(void){\n    int i, s = 0;\n    for( i = 0; i < 3; i++ ) s += i;\n    return s + i;\n}\n' > a.c
$ sed -i '' 's/int i,/int ulI,/' a.c   # 只改声明、漏掉使用点（模拟一轮词边界替换没收全）
$ clang -fsyntax-only a.c 2>&1 | grep -c 'use of undeclared identifier'
5
$ clang -fsyntax-only a.c 2>&1 | grep 'error:' | grep 'undeclared identifier' | sed -E "s/.*undeclared identifier '([^']+)'.*/\1/" | sort | uniq -c
   5 i
$ rm -rf "$d"
# 结论：一轮机械替换漏点后，编译错误恰是「哪些点没跟上」的清单；按标识符聚合（uniq -c）即可批量定位。复跑通过（本机 clang，2026-09-22）。
```

**审核给出的修改意见（要点）**：主张真值稳定（C/C++ + 脚本部分替换 → undeclared-identifier 级联，按编译轮次 + 按标识符聚合收敛），且本机可自包含复跑，故留在注入集。两处改：(1) 换证据——现证据节全部绑在已消失的 /tmp/amw-p2db-build.log 上、且聚合命令被截断，改挂 minimalRepro 里那条自包含命令（含期望输出 `5 i` / 5 处 undeclared identifier）；(2) 收窄「为什么」——切片里多轮的直接成因是替换脚本自身中途抛异常（ValueError: substring not found / AssertionError）留下半改名文件，不是条目现在写的「同一短名跨作用域含义不同」；把机制改成「脚本部分失败/词边界替换没收全 ⇒ 部分点残留旧名 ⇒ 编译报 undeclared identifier」，并删去切片未出现的「宏参数、结构体字段」举例（或标注为一般性示意）。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
