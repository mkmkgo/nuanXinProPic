#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "用法: ./scripts/process-video.sh <视频文件相对路径>"
  echo "示例: ./scripts/process-video.sh wallpaper/video/desktop/通用/demo.mp4"
  exit 1
fi

INPUT_PATH="$1"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$PROJECT_ROOT/$INPUT_PATH"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "文件不存在: $SOURCE_FILE"
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

RELATIVE_PATH="${INPUT_PATH#wallpaper/video/}"
FILENAME="$(basename "$RELATIVE_PATH")"
FILENAME_NO_EXT="${FILENAME%.*}"
SUBDIR="$(dirname "$RELATIVE_PATH")"

PREVIEW_DIR="$PROJECT_ROOT/preview/video/$SUBDIR"
THUMBNAIL_DIR="$PROJECT_ROOT/thumbnail/video/$SUBDIR"
PREVIEW_FILE="$PREVIEW_DIR/$FILENAME_NO_EXT.webp"
THUMBNAIL_FILE="$THUMBNAIL_DIR/$FILENAME_NO_EXT.webp"
TMP_PREVIEW_PNG="$PREVIEW_DIR/$FILENAME_NO_EXT.png"
TMP_THUMBNAIL_PNG="$THUMBNAIL_DIR/$FILENAME_NO_EXT.png"

mkdir -p "$PREVIEW_DIR" "$THUMBNAIL_DIR"

echo "生成首帧预览图..."
ffmpeg -y -i "$SOURCE_FILE" -vf "select='eq(n\,0)'" -frames:v 1 -update 1 "$TMP_PREVIEW_PNG"

if sips -s format webp "$TMP_PREVIEW_PNG" --out "$PREVIEW_FILE" >/dev/null 2>&1; then
  rm -f "$TMP_PREVIEW_PNG"
  FINAL_PREVIEW_FILE="$PREVIEW_FILE"
else
  FINAL_PREVIEW_FILE="$TMP_PREVIEW_PNG"
fi

echo "生成缩略图..."
ffmpeg -y -i "$FINAL_PREVIEW_FILE" -vf "scale=480:-1" -update 1 "$TMP_THUMBNAIL_PNG"

if sips -s format webp "$TMP_THUMBNAIL_PNG" --out "$THUMBNAIL_FILE" >/dev/null 2>&1; then
  rm -f "$TMP_THUMBNAIL_PNG"
  FINAL_THUMBNAIL_FILE="$THUMBNAIL_FILE"
else
  FINAL_THUMBNAIL_FILE="$TMP_THUMBNAIL_PNG"
fi

echo "资源信息:"
ffprobe -v quiet -show_entries format=duration,size -show_entries stream=width,height -of default=noprint_wrappers=1 "$SOURCE_FILE"

echo "完成:"
echo "  预览图: $FINAL_PREVIEW_FILE"
echo "  缩略图: $FINAL_THUMBNAIL_FILE"
