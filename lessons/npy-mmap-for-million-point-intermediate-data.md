---
id: npy-mmap-for-million-point-intermediate-data
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: data-engineering
tags: [npy, mmap, numpy, pointcloud, viewer]
triggers:
  - 离线程序要落盘百万行级的中间结果（点云/航迹）供 Python 分析
  - 查看器/分析脚本加载大结果文件卡顿或吃内存
  - 在 CSV 和二进制格式之间选中间数据格式
  - 需要反复随机访问大结果文件的子集（按帧/按组）
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:da720f38-036f-42ec-820d-ce8538a4fc1f
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: []
---

# 百万行级中间数据：定长 record 的 .npy + mmap_mode='r'，不用 CSV

离线 C 程序落盘供 Python 消费的大表（点云/航迹），用**定长 dtype record 的 .npy**（C 侧单个头文件 `npy_write.h` 即可写，只依赖 stdio），Python 侧 `np.load(path, mmap_mode='r')` 加载：190 万行的点云 mmap 打开只是几毫秒、不进常驻内存，查看器可按帧随机访问。CSV 在这个量级既慢又胀，且丢类型信息。

要点：dtype 字段在 C 写入侧与 Python 读取侧保持同一份定义；布尔/标签列用显式整型，跨语言不留歧义。

**证据**（session da720f38）：faf_offline 产出 `points_in/points_out/tracks.npy`（000028 数据集：过滤前 1,905,881 点、航迹 3.7 万条目）；viewer 与多个分析脚本全程 `np.load(..., mmap_mode='r')` 直接跑，快照图、逐帧对照、航迹诊断均在秒级完成。
