---
id: playbook-ucm221-cfar-point-cloud-filtering
name: UCM221 点云虚警过滤排查步骤
type: playbook
status: validated
scope: [debugging, signal-processing]
domains: [ucm221, radar, cfar]
triggers:
  - 点云虚警
  - CFAR 检测
  - 点云质量
  - 峰值剪枝
  - 虚警过滤
evidence:
  helpful: 0
  harmful: 0
verified_by: human
last_verified: '2026-07-24'
created: '2026-07-25'
---

# UCM221 点云虚警过滤排查步骤

针对外场测试雷达在运动状态下出现过多虚警的问题，按以下顺序排查和优化。

## 步骤 1：确认虚警来源

- 区分是真实目标角度估计错误，还是纯噪声/杂波造成的虚警；
- 对空采集时，注意静态目标点与能量逸散点的区别。

## 步骤 2：改进 CFAR 检测

- 采用距离-速度二维 CFAR 检测，替代单一维度检测；
- 在检测后加入峰值剪枝，过滤相邻单元中的弱峰。

## 步骤 3：尝试抗混叠与窗函数优化

- 增强抗混叠后观察近处杂点是否滤除；
- 对比不同窗函数对旁瓣/对侧异常峰的抑制效果。

## 步骤 4：区分运动与静止场景

- 运动雷达数据：关注速度维扩散、对侧异常峰；
- 静止雷达数据：关注能量逸散、零速维异常；
- 若信号残差分级过滤效果不明显，可转向静目标过滤方向。

## 步骤 5：飞行实验验证

- 修改后必须加载实际飞行/运动雷达数据进行验证；
- 对比过滤前后的虚警率与真实目标保留率；
- 多次复测确认稳定性后再固件化。

## 常见无效尝试（已验证）

- 数字 IQ 尝试：只对快时间采样有效，对速度维扩散无作用；
- 俯仰向两个阵元测角：精度未提高；
- 比幅法测角：效果不理想；
- RD 图图像峰值抑制：未取得有效效果。

## 来源

- 原 OpenClaw 知识库：`vault/10-Projects-Active/UCM221/UCM221_Software_Progress.md`
- 迁移时间：2026-07-25
- provenance: [imported] 经人审改写后 curate 入库
