---
id: substring-matcher-cannot-tell-exec-from-mention
type: lesson
status: validated
scope: global
domain: security-tooling
tags: [hook, matcher, regex, false-positive, fail-close, governance]
triggers:
  - "写危险命令拦截正则 / hook matcher / pre-commit 阻断规则"
  - "把观察期（warn）规则升级为阻断（block）"
  - "用命中计数当证据判断规则该不该收紧"
  - "拦截规则误伤 git commit message、grep、文档里的示例命令"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
对命令串做子串/正则匹配，**分不清「执行了危险命令」和「文中提到了它」**。漏报（`-fr` / `-r -f` / `sudo` 前缀变体）靠 matcher 写得全来兜；误报（引号内字面量）则根本无法在这一层解决。所以**升 block 前必须复核误报率，不能只看裸命中计数**。

**实测**（evo-kernel 的 `dangerous-rm-rf` 规则，40 次历史命中）：剥掉引号内字面量与注释后重新匹配，**60%（24 次）只是提及，不是执行**。五条构造命令里四条会被误杀：
```
git commit -m 'fix rm -rf handling'   → 命中（会被 deny）
grep -rn 'rm -rf' scripts/            → 命中
echo '危险操作示例：rm -rf /'          → 命中
cat README.md | grep 'rm -rf'         → 命中
rm -rf /tmp/build-cache               → 命中（这条才是真的）
```

**关键不对称**：剥引号可以用来**评估**规则质量，但**绝不能用于执行判定**——`bash -c "rm -rf /"` 的危险命令本就在引号里，剥掉会漏杀。评估侧漏判只是少推荐一次升级；执行侧漏判是安全事故。

**次生陷阱**：评估规则时跑的测试命令会自己进命中日志。本例中为验证误报率跑的 5 条命令，把计数从 34 抬到 40——**"要不要升级"的判据被"评估升级"这个动作本身污染**。计数类判据要能区分生产流量与测试流量，否则越评估越像该升级。
