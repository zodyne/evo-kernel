---
id: mass-cast-rewrite-macro-holes-need-handfix
type: lesson
status: validated
scope: global
domain: refactoring
tags: [cpp, static-cast, macros, clang-tidy, bulk-rewrite]
triggers:
  - "用 clang-tidy / 脚本把全树的旧式转换改成 static_cast，准备声称改完了"
  - "旧式转换藏在 #define 宏体里（如测试用 DB()、字段表宏），自动改写工具不碰宏体（失败信号）"
  - "全树 cast 改写的收尾自查：还有哪些 (T) 形态工具覆盖不到"
  - "宏内的类型转换导致 -Wold-style-cast 在开 -Werror 后仍拦不住或报点飘"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4a3-ae96-7475-af70-36ad39adaba4
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [cast-rewrite-must-absorb-function-call-parens, cast-auto-rewrite-pollutes-comments-audit-diff]
---

**主张**：批量把旧式转换改成 `static_cast` 时，**宏体内的 `(T)` 不会被 clang-tidy 的 google-readability-casting 修复覆盖**（宏体不是可改写的 AST 节点），必须单独用正则扫出宏、逐处手改并计数记录。本会话自动转换 194 处之外，宏/惯用法有 13 处手改，另有 101 处工具「未识别」。

**为什么**：clang-tidy 的 fix-it 作用在 AST 节点上；宏展开后的 cast 没有干净的源码位置可回填，工具要么跳过要么不动，所以「tidy rc=0 / 转换 N 处」不代表全树清零。开启 `-Werror,-Wold-style-cast` 后，宏内残留仍会在每个展开点报错，报点会落在使用宏的文件而不是宏定义处，容易误判。

**证据（本会话切片，命令 ↔ 结果）**：

- 扫描命令 `rg -n '^\s*#define.*\(\s*(Real_t|double|uint32_t|...)\s*\)' core tests tools` 命中宏内旧式转换，例如 `tests/unit/test_cfar_f5.cpp:43:#define DB( log2v ) ( ( Real_t ) ( ( log2v ) * dCfarDbPerLog2 ) )`，以及 `tests/helpers.hpp` 的表格宏、`TEST_AZ/EL` 宏。
- 记录：`宏内 9 处手改(卡:逐处写 REPORT)`；汇总 `宏/惯用法手改 OK(helpers 3 + DB 2 + AZ/EL 6 + PARITY_FIELD 1 + radar 1 = 13) 脚本转换 194 处;未识别 101`。
- `tools/parity/decoder.cpp` 的 `PARITY_FIELD` 宏内 cast 也需手改，改后 `PARITY_FIELD 宏改 OK build rc=0 errors=0`。

**边界 / 反例**：

- 不是所有宏都需要手改：不含旧式转换的宏不动。
- 若宏体里是 `static_cast` 或函数式构造（`Real_t( x )`）而不是 `(Real_t) x`，工具同样不覆盖，但不算「旧式转换残留」。
- 「未识别 101」包含工具无法判断的形态（函数指针、模板等），不全是宏。

**失败信号（未来命中即该想起本条）**：报告声称「全树 old-style cast 已清零」但 `-Wold-style-cast` 仍在宏使用点报错；或脚本统计的转换数加上手改数仍对不上 `rg` 扫出的原始命中数。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
cd "$(mktemp -d)" && cat > cast.cpp <<'EOF'
#define SCALE( x ) ( ( double ) ( x ) * 2.0 )
int main( void ) { double a = ( double ) 5; double b = SCALE( 3 ); return ( int ) ( a + b ); }
EOF
cp cast.cpp orig.cpp
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
clang-tidy -checks='-*,google-readability-casting' --fix cast.cpp -- -std=c++17
diff orig.cpp cast.cpp
# 期望：只有第5、7行被改成 static_cast< double> / static_cast< int>；
#       宏体内 ( double ) 零诊断、零改动（本机 clang-tidy 22.1.8 实测输出 "applied 3 of 3 suggested fixes"，宏体未被触碰）
clang++ -std=c++17 -Wold-style-cast -Werror -c orig.cpp -o /dev/null
# 期望：3 处 error —— 5:16、6:16（宏使用点，附 "note: expanded from macro 'SCALE'" 指向第1行）、7:12
# 即：clang-tidy 的 google-readability-casting 覆盖不到宏体（连诊断都不报），而 -Wold-style-cast 能拦、但报在宏使用点
```

**审核给出的修改意见（要点）**：核心主张成立且可独立复验，留在注入集，但按下列 4 点改：(1) 收窄「为什么」——删去未经证据支持的机制描述「fix-it 作用在 AST 节点上 / 宏展开后的 cast 没有干净的源码位置可回填」（实测相反：clang 对宏内 cast 仍有位置，-Wold-style-cast 报在宏使用点并附 `note: expanded from macro`）；改为观察层事实「google-readability-casting 对宏展开产生的 cast 不产生任何诊断，也不产生 fix-it，所以 tidy rc=0 / 转换 N 处都不含宏内 cast」。(2) 改 trigger 第 4 条：「-Wold-style-cast 仍拦不住」是错的——它拦得住（在宏使用点报错）；应改为「clang-tidy 的 fix 覆盖不到宏体，-Wold-style-cast 会在宏使用点报错，二者要分开看」。(3) 证据节：把「本会话 194/13/101」降为旁证并注明是 algommw-plus 当时 HEAD 的会话数字、不可跨仓复跑；主证据换成 minimalRepro 里的自包含最小复现（本机已跑通）。(4) 边界第 3 条删掉/改写「（函数指针、模板等）」——切片里 101 只列到 `UNHANDLED core/include/base/libm.hpp ...`，看不出完

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- clang-tidy 的 fix-it 作用在 AST 节点上；宏展开后的 cast 没有干净的源码位置可回填，工具要么跳过要么不动
- 宏体不是可改写的 AST 节点
- 宏内的类型转换导致 -Wold-style-cast 在开 -Werror 后仍拦不住或报点飘
- 「未识别 101」包含工具无法判断的形态（函数指针、模板等），不全是宏

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
