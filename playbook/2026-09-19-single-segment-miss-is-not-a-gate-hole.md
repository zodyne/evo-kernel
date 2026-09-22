---
id: single-segment-miss-is-not-a-gate-hole
type: lesson
status: validated
scope: global
domain: verification
tags: [acceptance-gate, adversarial, probe, libm, coverage]
triggers:
  - "复核『闸门/检查的某一段有漏报 ⇒ 闸门有洞』这类发现，准备判 confirm/refuted"
  - "审计多段验收闸门（源码正则扫描 + 产物符号扫描等），要判整体覆盖面"
  - "发现方只给出单一段的命中数就断言闸门失效（失败信号：没跑其它段）"
  - "写对抗探针验证闸门有没有假阴性，需要决定探针上跑哪些检查"
  - "闸门里一段正则报 0 命中，但产物 nm/objdump 里出现可疑符号（失败信号）"
created: 2026-09-19
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b753-cd18-7475-af70-36cd8df466ea
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [cpp-mode-libm-symbol-diff-per-tu, adversarial-review-separate-evidence-from-impact-attribution, blind-spot-claim-needs-instance-count]
---

## 主张

判「闸门某一段有漏报 ⇒ 闸门有洞」之前，必须在**同一批探针**上把闸门的所有段都跑一遍：单段命中数不能代表闸门覆盖面，一段漏掉的调用可能被另一段抓到；只有全段都漏（或不覆盖同一失败类别）才是洞。

## 为什么

验收闸门常是多段实现——本例是 C 段（源码正则扫描限定数学调用）+ B 段（产物 `nm -u` 查浮点 libm 符号）。发现方拿 C 段的 0/1 计数说「有洞」，只证明了 C 段的模式覆盖面；B 段是否覆盖同一失败类别，只能实测。

## 证据（切片命令 ↔ 结果）

对抗探针 harness 在同一批构造 TU 上同时打印两段结果：

- `injected_float`：`compile: OK   C-seg regex hits: 0   nm -u: _sinf    B-seg float hits: _sinf`
  —— C 段源码正则报 0，B 段符号层抓到 `_sinf`：同一调用被另一段覆盖。
- `injected_fptr`（`double probe( float x`）：`compile OK  C-seg hits: 0  nm -u: _sin  B-seg float hits: []`
  —— B 段对 double 形态没有误报（该段是真判据，不是无脑报警）。
- 真实树对照：`== core: qualified math calls (any) == NO-MATCH in core`（C 段在 `core` 上同样零命中）。

同会话最终裁决：该发现 `isReal = false` —— 其计数（1 / 0 / 0 / 0）精确复现，但「闸门有洞」的结论不成立（末条 assistant：`the finding is a toolchain-model misread, not a real gate hole`）。

## 边界 / 反例

- 只有另一段在同一探针上真的命中，才可判「不是洞」；若两段共因（同一输入源/同一模式族），两段同漏仍是洞。
- 探针必须覆盖被发现声称漏掉的那种写法；否则「没洞」和「有洞」一样没有证据。
- 本条只判「闸门整体是否漏」，不判被漏形态的实际影响面（实例数另计，见 `blind-spot-claim-needs-instance-count` 方向的条目）。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含、可当场重跑（clang++/rg/nm 本机均在）：

  d="$(mktemp -d)"; cd "$d" || exit 1
  cat > t.cpp <<'EOF'
  #include <cmath>
  namespace amw { double probe( float x ){ return (std::sin)(x); } }
  EOF
  cat > u.cpp <<'EOF'
  #include <cmath>
  namespace amw { double probe( float x ){ return std::sin(x); } }
  EOF
  clang++ -std=c++17 -O3 -fno-builtin -c t.cpp -o t.o
  clang++ -std=c++17 -O3 -fno-builtin -c u.cpp -o u.o
  echo "A-seg (source regex 'std::sin\\(' hits):"
  printf '  t.cpp: %s\n' "$(rg -c 'std::sin\(' t.cpp || echo 0)"
  printf '  u.cpp: %s\n' "$(rg -c 'std::sin\(' u.cpp || echo 0)"
  echo "B-seg (nm -u libm float symbols):"
  printf '  t.o: %s\n' "$(nm -u t.o | tr '\n' ' ')"
  printf '  u.o: %s\n' "$(nm -u u.o | tr '\n' ' ')"

期望输出（2026-09-22 本机实测）：A 段对 t.cpp（括号化 `(std::sin)(x)`）报 0 命中，而 B 段 nm -u 仍抓到 `_sinf`；u.cpp（裸 `std::sin(x)`）A/B 两段都命中。即：单段漏报（A 段 0）不是闸门有洞——同一失败被另一段（B 段符号层）覆盖。命令未依赖任何被删的 /tmp 沙箱或 algommw-plus 树。
```

**审核给出的修改意见（要点）**：核心主张站得住，且换到全新探针上仍成立（见 minimalRepro），故不降级；但证据节需换证据。理由：证据里四条引用**均为切片原文、无捏造**，但记录形态不可复跑——①引用绑在已删除的 /tmp/review-refute-libm-gate-c-segment-regex-holes 沙箱上；②切片把两条关键命令截断（第 27 行 rg 模式串、第 37-40 行 injected_fptr heredoc 未闭合），照抄不能重跑。做法：(1) 在证据节补入 minimalRepro 那条自包含命令及其实测输出，作为可复跑主证据；(2) 把对 /tmp 沙箱与真实树 rg 的引用标注为「仅示当时观测，沙箱已删」；(3) 前两条 bullet 里被截断的命令片段（`double probe( float x`、`rg -n '(std::|::)(...`）不要当可执行命令呈现。主张文字无需改（边界节已自带限定：另一段须在同一探针上真命中、探针须覆盖被漏写法），不建议改写 主张。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
