---
id: validation-params-readable-from-artifact
type: principle
status: validated
scope: global
domain: methodology
tags: [validation, configuration, verification, trust-but-verify]
triggers:
  - "做'换参数重跑'的验证，比对前只检查了调用命令行"
  - "验证结果异常，第一反应去查算法/数值 bug"
  - "被测产物的实际配置与调用者传入的参数可能不一致"
  - "写比对/验证脚本，设计自检前置（失败信号：参数只来自调用者声明）"
created: 2026-08-12
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: 人工（整理 inbox/capture-2026-07-27-23-26-22-015-ljdc.md）
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [make-d-macro-change-skips-rebuild-silently, analysis-cache-filename-must-key-dataset]
---
# 换参数重跑的验证：实际生效参数必须能从被测产物本身读出来

**主张**：任何"换参数重跑再比对"的验证，**不能只信调用者传了什么**——实际生效的参数必须能从被测产物本身读出来（产物自报、戳文件、日志打印）。验证工具要先核对被测方与参照方的配置，再比数值。

**为什么**：参数从"调用者声明"到"产物实际生效"之间可能隔着静默失效的环节（缓存、构建依赖图、配置回退）。UCM221 C 移植实例：`make libfaf N_GRID=31` 因编译标志不在依赖图里而静默跳过重建，"测 31 档"其实还在跑 51 档的库——若直接比数值，会把配置错误误诊成算法 bug。

**做法（两道防线）**：①比对脚本开头核对关键配置（六个阈值）并**打印实际档位**，配置不符立刻暴露；②把参数拉进产物的依赖/标识里（如 Makefile 用档位戳文件 `build/.ngrid-N`，详见 related 条目）。

**反例/边界**：参数全程运行时传入且产物启动即自报配置的系统，风险较低但防线①仍值得做——打印实际配置的成本接近零。

**证据**：capture-2026-07-27-23-26-22-015-ljdc；防线①的档位打印当场暴露"51 档冒充 31 档"，防线②修复见 `make-d-macro-change-skips-rebuild-silently`。
