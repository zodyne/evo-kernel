---
id: pil-crop-xy-order-mismatch-silent-wrong-region
type: lesson
status: validated
scope: global
domain: image-processing
tags: [pillow, crop, coordinate-order, verification]
triggers:
  - "PIL Image.crop / numpy img[y0:y1, x0:x1] 裁剪扫描页局部"
  - "裁剪参数在 (x0,y0,x1,y1) 与 (y0,x0,y1,x1) 之间犹豫"
  - "裁出的放大图尺寸离谱或内容与预期不符"
  - "批量裁剪脚本要防静默裁错区域"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad78-0edd-7710-933f-0b684c017e93
last_verified: 2026-09-18
superseded_by: null
related: [magick-crop-out-of-bounds-warns-not-fails, formula-region-crop-upscale-before-vision-transcribe]
---
PIL 的 `Image.crop((x0,y0,x1,y1))` 是 xy 序、numpy 切片 `img[y0:y1, x0:x1]` 是 yx 序，两套写法混用会**静默裁错区域**——不越界就不报错；本会话里参数序写反产生 5490×4920 的离谱尺寸才暴露（有 traceback），而左右栏对比类裁错则连异常都没有，只能靠产物尺寸和内容复核发现。
**做法**：每处 crop 顺手打印 `src=(x0,y0,x1,y1) size=(w,h)`，并对尺寸做合理性检查（按页宽/带高的预期量级），异常尺寸当场断言而不是等下游出错；本会话 tools/zoomband.py 输出 `src=(…) size=(…)` 即此守卫的实际形态。
**边界**：magick -crop 的坑是 CLI 越界时 warns-not-fails（见 related），本条是参数序混淆，越不越界都可能发生；裁剪框怎么取、放大多少的流程问题不在本条。
**证据**：切片内 `jobs = [('p68_P', 68, (1400,1560,2315,2380), 6), …]` → `✗ p68_P (5490, 4920) … Traceback`；改为 `(1400,2315,1560,2380)` 后输出 `(960, 390)` 正常，同批 p65_P/p71_P 逐一给出合理尺寸。
