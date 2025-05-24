#!/bin/bash

set -e

VIDEO_DIR="./"
OUTPUT_DIR="./frames"
TIMESTAMPS=(
  "00:00:00.000"
  "00:00:46.200"
  "00:01:46.840"
  "00:02:42.880"
  "00:05:01.880"
  "00:05:34.880"
  "00:10:52.320"
  "00:16:10.680"
  "00:16:08.920"
  "00:16:00.640"
)

mkdir -p "$OUTPUT_DIR"

for video in "$VIDEO_DIR"/*.mp4; do
  base=$(basename "$video")
  name="${base%.*}"
  target_dir="$OUTPUT_DIR/$name"
  mkdir -p "$target_dir"

  for idx in "${!TIMESTAMPS[@]}"; do
    ts="${TIMESTAMPS[$idx]}"
    frame_num=$(printf "%02d" $((idx + 1)))
    ffmpeg -loglevel error -ss "$ts" -i "$video" -frames:v 1 "$target_dir/frame_${frame_num}.jpg"
  done

  echo "✅ Extracted frames for: $base"
done

echo "📁 All extracted images are available in: $OUTPUT_DIR/"
