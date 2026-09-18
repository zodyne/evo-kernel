---
id: screen-recording-keyframe-diff-ocr
type: lesson
status: validated
scope: global
domain: forensics
tags: [ffmpeg, screen-recording, frame-diff, tesseract, ocr, video-forensics]
triggers:
  - "用户给一段十几分钟的屏幕录制，要定位『哪一刻发生了什么』"
  - "录屏无音轨、无章节，只能手动拖进度条看（失败信号：看不过来）"
  - "要从录屏里读出屏幕上的命令/文本内容"
  - "抽帧时不知道该抽哪几秒"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b351-8a08-7097-91f3-80fbeb2387b2
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [macos-screenshot-narrow-nbsp-filename, macos-vision-framework-chinese-ocr]
---

# 定位长录屏的关键时刻：灰度缩帧逐帧差分打分取 top-N 时间戳，再按时间戳抽原图 + OCR 读屏

## 主张

面对一段长录屏，别靠拖进度条：①先把整段降采样成灰度小帧（`ffmpeg -vf "fps=2,scale=160:90,format=gray" -f rawvideo`）逐帧差分打分，排出 top-N 时刻；②用 `ffmpeg -ss <t> -i <video> -frames:v 1` 把候选时刻抽成单帧图；③对抽出的帧跑 `tesseract f_<t>.jpg - --psm 6`，用屏幕文字判断那一刻机上在干什么；需要人眼扫全片时先出接触表（`fps=1/20,scale=320:180,tile=6x4`）。

## 证据（切片命令↔结果）

- 先确认没有音轨可转写：`ffprobe -show_entries stream=index,codec_type,codec_name,channels -of csv` ↳ `stream,0,h264,video`（无音频流）。
- 差分打分：`ffmpeg ... -vf "fps=2,scale=160:90,format=gray" -f rawvideo -` ↗ `total frames: 1840 duration~ 920.0` + `top-30 change moments (score, t): 65.21 t=5.0s / 34.43 t=5.5s / 33...`；另有 `scene_change_frames = 5 timestamps = 3...`。
- 抽帧：`for t in 5 300 310 320 345 370 471 554 601 605 915; do ffmpeg -ss $t -i "$V" -frames:v 1 ...` ↗ 生成 `f_5.jpg f_300.jpg ...`；接触表 ↗ `sheet1.png sheet2.png ...`。
- OCR 读屏：`tesseract f_300.jpg - --psm 6` ↗ `eTrackInit' ... awk '/*eStatus eTrackInit/,/*}/' track.c`（屏幕上确实是终端/编辑器内容，可用于定位这一刻在做什么）。

## 反例 / 边界

- `tesseract --list-langs` 本机只有 `eng osd snum`，**没有 chi_sim**：中文界面 OCR 出来近乎噪声，只能当「这屏有没有内容 / 像代码还是像文字」的粗信号；中文内容要走 macOS Vision（见 macos-vision-framework-chinese-ocr）。
- 录屏里的小字/抗锯齿字体 OCR 准确率低，不要把 OCR 文本当原文引用；要引用就回对应时刻截图或原始日志核对。
- 文件名坑：`~/Desktop/Screen Recording 2026-09-18 at 11.43.35 AM.mov` 里时间与 AM/PM 之间是 U+202F，手打进命令报 `No such file or directory`（见 macos-screenshot-narrow-nbsp-filename）；本次最终靠 `os.listdir` + `repr()` 拿真名。
