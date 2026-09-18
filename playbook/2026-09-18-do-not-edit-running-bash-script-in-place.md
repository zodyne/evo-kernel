---
id: do-not-edit-running-bash-script-in-place
type: lesson
status: validated
scope: global
domain: shell
tags: [bash, long-running, script-edit, atomic-replace, fail-open]
triggers:
  - "有一条长跑的 bash 脚本正在执行，而你要改它"
  - "后台轮次/轮询脚本运行期间需要打补丁"
  - "日志里出现半截关键字被当命令执行（如 rintf: command not found、yntax error）"
  - "脚本报 syntax error near unexpected token，但文件本身语法正确（失败信号）"
  - "darwin/linux 上用 mv 替换脚本以避开编辑期错位"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b1aa-8483-73b1-bdd8-c2cc6d20a4c5
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [open-ended-task-plus-tools-has-no-stop-condition]
---

# 别在原地编辑正在执行的 bash 脚本：它按字节偏移增量读，会读到半行并当命令跑

## 主张

bash **不是**一次把脚本读进内存再执行，而是按**字节偏移**增量读取。脚本正在跑时原地编辑它，已读位置之后的偏移会错位，bash 于是从半行中途接着解析——把残片当命令执行、或报出文件本身并不存在的语法错误。

安全改法（对运行中的实例无感）：**写到临时文件再原子替换**

```bash
cp 新版本 /tmp/new.sh && mv /tmp/new.sh path/to/script.sh
```

`mv` 是 `rename(2)`：跑着的 bash 继续读**旧 inode**，偏移不会错位，当前这一轮照常跑完，下一轮自动用新版本。另一条路是**先停掉进程再改**。

## 为什么

2026-09-18 在一次 4 worker 并行轮进行中反复原地编辑蒸馏驱动器，日志留下两行实证：

```
path/to/evo-distill.sh: line 276: rintf: command not found
path/to/evo-distill.sh: line 279: syntax error near unexpected token 'else'
```

`rintf` 是 `printf` 被拦腰截断后的残片 —— 不是打字错误，是错位读取。注意症状的**迷惑性**：文件用 `bash -n` 检查完全合法，报错行号也不对应任何真实缺陷，所以很容易去查一个根本不存在的语法问题。

危害被 fail-open 掩盖：进程不会因此退出，只往 stderr 留下几行残片，整轮照常"看起来正常"地跑完。属于「坏的那一侧不吭声」那类故障。

## 反例 / 边界

- **不是每次编辑都炸**：只有当编辑落在**尚未读取**的字节区间时才错位，所以它是概率性的、依赖时机的。不能因为"上次改了没事"就认为安全。
- **局部正确不推出整体安全**：当时我判断「`while` 循环体是一次解析，所以中途编辑安全」——对**循环体内**成立，但循环**之后**的顶层语句仍会按新偏移读取，所以照样炸。
- 若脚本很短（一次 read 就整个载入）或已跑到结尾，实际风险低——但这依赖实现细节，别拿它当免死金牌。
- 用编辑器保存时走「写临时文件 + rename」的（多数编辑器默认如此）天然安全；危险的是**原地 truncate 后重写**的保存方式，以及 `sed -i`、`cp 覆盖`、`cat > file` 这类操作。
