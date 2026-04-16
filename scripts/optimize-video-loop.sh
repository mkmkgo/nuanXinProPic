#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "用法: ./scripts/optimize-video-loop.sh <视频相对路径> [输出相对路径]"
  echo "示例: ./scripts/optimize-video-loop.sh wallpaper/video/desktop/动漫/demo.mp4"
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "缺少 ffmpeg"
  exit 1
fi

if ! command -v ffprobe >/dev/null 2>&1; then
  echo "缺少 ffprobe"
  exit 1
fi

INPUT_REL="$1"
OUTPUT_REL="${2:-}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INPUT_FILE="$PROJECT_ROOT/$INPUT_REL"

if [ ! -f "$INPUT_FILE" ]; then
  echo "文件不存在: $INPUT_FILE"
  exit 1
fi

if [ -z "$OUTPUT_REL" ]; then
  OUTPUT_FILE="${INPUT_FILE%.*}.optimized.mp4"
else
  OUTPUT_FILE="$PROJECT_ROOT/$OUTPUT_REL"
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

WIDTH="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$INPUT_FILE")"
HEIGHT="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$INPUT_FILE")"
FPS_RAW="$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of csv=p=0 "$INPUT_FILE")"
DURATION="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT_FILE")"

FPS="$(awk -F'/' 'NF==2 { if ($2 == 0) print 30; else printf "%.0f", $1 / $2 } NF==1 { printf "%.0f", $1 }' <<<"$FPS_RAW")"
if [ -z "$FPS" ] || [ "$FPS" -le 0 ]; then
  FPS=30
fi

TARGET_FPS=30
TARGET_WIDTH="$WIDTH"

if [ "$WIDTH" -gt 1920 ]; then
  TARGET_WIDTH=1920
fi

VF_CHAIN="fps=${TARGET_FPS}"
if [ "$TARGET_WIDTH" -ne "$WIDTH" ]; then
  VF_CHAIN="scale=${TARGET_WIDTH}:-2:flags=lanczos,${VF_CHAIN}"
fi

echo "开始优化视频:"
echo "  输入: $INPUT_FILE"
echo "  输出: $OUTPUT_FILE"
echo "  分辨率: ${WIDTH}x${HEIGHT} -> ${TARGET_WIDTH}x自动"
echo "  帧率: ${FPS} -> ${TARGET_FPS}"
echo "  时长: ${DURATION}s"

ffmpeg -y -i "$INPUT_FILE" \
  -an \
  -vf "$VF_CHAIN" \
  -c:v libx264 \
  -preset slow \
  -profile:v high \
  -level 4.1 \
  -pix_fmt yuv420p \
  -crf 20 \
  -movflags +faststart \
  -g "$TARGET_FPS" \
  -keyint_min "$TARGET_FPS" \
  -sc_threshold 0 \
  -bf 0 \
  "$OUTPUT_FILE"

echo "优化完成"
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,pix_fmt,r_frame_rate -show_entries format=duration,size -of default=noprint_wrappers=1 "$OUTPUT_FILE"
