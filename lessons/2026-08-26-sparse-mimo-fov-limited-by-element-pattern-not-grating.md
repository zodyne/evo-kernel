---
id: sparse-mimo-fov-limited-by-element-pattern-not-grating
type: lesson
status: candidate
scope: global
domain: radar-doa
tags: [稀疏阵, MIMO, 栅瓣, 单元方向图, 扫描后PSL, DEV-8T8R]
triggers:
  - 稀疏 MIMO 线阵可用视场被栅瓣限制（失败信号：只看栅瓣位置）
  - 波束扫描后旁瓣突然抬高、主瓣却在单元图上下滑
  - 需要判断稀疏阵的可用扫描范围
  - 判据该用扫描后总方向图 PSL 还是栅瓣位置
  - 子阵栅瓣错位相乘残留造成远区高旁瓣
created: 2026-08-26
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-26-05-22-05-835-rzv7
last_verified: 2026-08-26
superseded_by: null
schema_version: 1
related: []
---

# 稀疏 MIMO 线阵的可用视场往往不由栅瓣决定，而由单元方向图决定

稀疏 MIMO 线阵的可用视场往往不由栅瓣决定：单元方向图不随数字波束转动，把波束扫到 θ0 时远区高旁瓣落到 sinθ0−Δu、反而靠近单元波束中心，主瓣却在单元图上下滑。

## 证据

DEV-8T8R 8T8R(4λ/3.5λ) 阵列全域最高旁瓣 −8.9dB@±15.4°(非栅瓣，是两子阵栅瓣错位相乘残留)，0° 时被单元图压到 −44dB，扫到 8° 只剩 −7.8dB、10° 只剩 −1.3dB。

## 判据

判据要用'扫描后总方向图 PSL'而不是'栅瓣位置'。
