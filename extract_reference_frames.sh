#!/bin/bash

set -e

# Set the source directory
read -rp "Enter path to VIDEO_DIR (folder with .mp4 files): " VIDEO_DIR
if [[ ! -d "$VIDEO_DIR" ]]; then
  echo "❌ ERROR: Directory '$VIDEO_DIR' does not exist."
  exit 1
fi

# Set the output directory
read -rp "Enter path for OUTPUT_DIR (default: ./frames): " OUTPUT_DIR
OUTPUT_DIR="${OUTPUT_DIR:-./frames}"
mkdir -p "$OUTPUT_DIR"

# Choice of extraction mode
echo "How do you want to extract frames?"
echo "1) Use predefined timestamps"
echo "2) Use 10 random timestamps"
read -rp "Your choice (1 or 2): " mode

# Fixed timestamps
TIMESTAMPS_PREDEFINED=(
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

for video in "$VIDEO_DIR"/*.mp4; do
  base=$(basename "$video")
  name="${base%.*}"
  target_dir="$OUTPUT_DIR/$name"
  mkdir -p "$target_dir"

  echo "🎞 Processing: $base"

  if [[ "$mode" == "1" ]]; then
    # Fixed timestamps
    for idx in "${!TIMESTAMPS_PREDEFINED[@]}"; do
      ts="${TIMESTAMPS_PREDEFINED[$idx]}"
      frame_num=$(printf "%02d" $((idx + 1)))
      ffmpeg -loglevel error -ss "$ts" -i "$video" -frames:v 1 "$target_dir/frame_${frame_num}.png"
    done
  else
    # Duration of the video in seconds
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video")
    duration_int=${duration%.*}
    min_margin=3
    usable_duration=$((duration_int - 2 * min_margin))

    declare -a randoms=()
    while [ "${#randoms[@]}" -lt 10 ]; do
      r=$((RANDOM % usable_duration + min_margin))
      randoms+=("$r")
    done

    for idx in "${!randoms[@]}"; do
      seconds="${randoms[$idx]}"
      timestamp=$(date -u -d "@$seconds" +%H:%M:%S)
      frame_num=$(printf "%02d" $((idx + 1)))
      ffmpeg -loglevel error -ss "$timestamp" -i "$video" -frames:v 1 "$target_dir/frame_${frame_num}.png"
    done
  fi

  echo "✅ Extracted frames for: $base"
done

echo "📁 All extracted images are available in: $OUTPUT_DIR/"
