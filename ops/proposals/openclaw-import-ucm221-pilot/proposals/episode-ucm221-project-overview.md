---
id: episode-ucm221-project-overview
name: UCM221 无人机避障雷达项目总览
type: episode
status: validated
scope: [project-management]
domains: [ucm221, radar]
triggers:
  - UCM221
  - 无人机避障雷达
  - 项目总览
  - 团队分工
evidence:
  helpful: 0
  harmful: 0
verified_by: human
last_verified: '2026-07-24'
created: '2026-04-02'
---

# UCM221 无人机避障雷达项目总览

> 原项目代号 UCM221，2026-07-24 更名为「无人机避障雷达技术研究」。
> 本条目为项目整体上下文，用于快速了解项目范围、团队与当前状态。

## 项目范围

无人机避障雷达技术研究，核心围绕雷达信号处理、数据处理、嵌入式软件、FPGA 算法适配与上位机软件五个模块推进。

## 团队与分工

| 成员 | 负责模块 | 状态 |
|---|---|---|
| euly | 项目管理 + 信号处理模块（点云质量过滤、暗室测角分析、硬件天线数据分析、超分辨算法） | 活跃 |
| 唐富强 | 信号处理模块（联合负责）、嵌入式算法效率优化 | 活跃 |
| 赖惠镇 | 数据处理模块（跟踪算法、聚类、分类、无人机监测、行人检测） | 活跃 |
| 冯飞 | 数据处理模块（无飞控模式、失效保护） | 活跃 |
| 欧阳蕾 | 嵌入式软件 + 系统集成调试 | 活跃 |
| 熊家令 | FPGA 算法适配开发 | 活跃 |
| 湛良龙 | 上位机软件 | 活跃 |

## 关键工作区

- 算法开发工作区：`workspace/projects/ucm221-pointcloud-filter/`
- 上游原始数据：`~/Dev/ucm221/`
- GitLab：`http://192.168.43.44:55211/tangfuqiang/ucm221-pointcloud-filter`（私有，v1.0.0）

## 当前热点（截至 2026-07-24）

1. 点云生成质量问题：距离-速度二维 CFAR + 峰值剪枝，持续降低虚警；
2. 非均匀阵列暗室测角：大角度俯仰相位模糊已用长短基线解模糊，非线性拟合后偏差约 3 度；
3. 硬件天线调试：方案六侧飞无人机 180 米轨迹连续，但远距离（>150m）信噪比低于 5dB；
4. 超分辨算法：ARM 移植完成，平均 0.2ms/点，查表法有望降至 0.1–0.15ms。

## 来源

- 原 OpenClaw 知识库：`vault/10-Projects-Active/UCM221/UCM221_Project.md`
- 迁移时间：2026-07-25
- provenance: [imported] 经人审改写后 curate 入库
