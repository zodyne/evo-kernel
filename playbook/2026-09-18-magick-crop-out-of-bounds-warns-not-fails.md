---
id: magick-crop-out-of-bounds-warns-not-fails
type: lesson
status: validated
scope: global
domain: image-processing
tags: [imagemagick, magick, crop, silent-failure, image-processing]
triggers:
  - "用 magick -crop 裁图后得到空白/错误结果，但命令没非零退出"
  - "magick 输出 'geometry does not contain image' 警告"
  - "裁剪框坐标或尺寸是算出来的，不确定是否越出图像边界"
  - "裁剪产物尺寸不对或内容错位，怀疑裁剪框越界（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad56-93d1-7710-933f-0b652a58f12a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: []
---

ImageMagick `magick -crop WxH+X+Y` 的几何区域越出图像边界（X+W 或 Y+H 超出宽高）时，只发 "geometry does not contain image" 警告并继续执行，产出错误/空裁剪，不会非零退出——裁前必须先确认几何在图像尺寸内。

**为什么**：越界裁剪是静默失败——命令「成功」退出但产物是错的，后续转写/比对会基于错图往下走。本会话 fig-p116-f01.png 实际宽 1644，一次裁剪用了 x 偏移 1740（1740+260 > 1644），触发 `magick: geometry does not contain image (260x80+1740+0) ... warning/transform.c/CropImage/599` 警告。

**证据**：切片命令结果里出现上述 magick 警告字符串；同会话另一条命令先读 PNG IHDR 头拿到宽高（`struct.unpack('>II', d[16:24])`）得到「fig-p116-f01.png: 1644 x 221」，据此修正裁剪框后返回 ok。

**边界**：只针对 magick 的 crop 越界行为；PIL 的 crop 越界是另一套语义（自动裁剪到边界）。判定手段：裁前用 `identify` 或读 PNG IHDR（宽高在字节 16–23，大端 uint32）确认尺寸。
