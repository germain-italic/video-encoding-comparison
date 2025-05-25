#!/bin/bash

set -e

# Ask for input directory
read -e -p "Enter path to VIDEO_DIR (folder with .mp4 files): " VIDEO_DIR
if [[ ! -d "$VIDEO_DIR" ]]; then
  echo "❌ ERROR: Directory '$VIDEO_DIR' does not exist."
  exit 1
fi

# Ask for output subdirectory name (inside VIDEO_DIR)
read -e -i "frames" -p "Enter name for OUTPUT_DIR (inside VIDEO_DIR): " OUTPUT_SUBDIR
OUTPUT_DIR="${VIDEO_DIR%/}/$OUTPUT_SUBDIR"
mkdir -p "$OUTPUT_DIR"

# Ask whether to extract
read -rp "Do you want to extract frames? (y/n) " DO_EXTRACT
DO_EXTRACT=${DO_EXTRACT,,}

# Ask whether to generate HTML
read -rp "Do you want to generate a HTML comparison file of the frames? (y/n) " DO_HTML
DO_HTML=${DO_HTML,,}

# Prepare shared timestamps if random mode is selected
if [[ "$DO_EXTRACT" == "y" ]]; then
  echo "How do you want to extract frames?"
  echo "1) Use predefined timestamps"
  echo "2) Use 10 random timestamps"
  read -rp "Your choice (1 or 2): " mode

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

  if [[ "$mode" == "2" ]]; then
    first_video=$(find "$VIDEO_DIR" -maxdepth 1 -name "*.mp4" | head -n 1)
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$first_video")
    duration_int=${duration%.*}
    min_margin=3
    usable_duration=$((duration_int - 2 * min_margin))
    declare -a SHARED_RANDOMS=()
    while [ "${#SHARED_RANDOMS[@]}" -lt 10 ]; do
      r=$((RANDOM % usable_duration + min_margin))
      SHARED_RANDOMS+=("$r")
    done
  fi

  for video in "$VIDEO_DIR"/*.mp4; do
    base=$(basename "$video")
    name="${base%.*}"
    target_dir="$OUTPUT_DIR/$name"
    mkdir -p "$target_dir"

    echo "🎞 Processing: $base"

    if [[ "$mode" == "1" ]]; then
      for idx in "${!TIMESTAMPS_PREDEFINED[@]}"; do
        ts="${TIMESTAMPS_PREDEFINED[$idx]}"
        frame_num=$(printf "%02d" $((idx + 1)))
        ffmpeg -loglevel error -ss "$ts" -i "$video" -frames:v 1 "$target_dir/frame_${frame_num}.png"
      done
    else
      for idx in "${!SHARED_RANDOMS[@]}"; do
        seconds="${SHARED_RANDOMS[$idx]}"
        timestamp=$(date -u -d "@$seconds" +%H:%M:%S)
        frame_num=$(printf "%02d" $((idx + 1)))
        ffmpeg -loglevel error -ss "$timestamp" -i "$video" -frames:v 1 "$target_dir/frame_${frame_num}.png"
      done
    fi

    echo "✅ Extracted frames for: $base"
  done
fi

# HTML generation
if [[ "$DO_HTML" == "y" ]]; then
  read -rp "Enter name for output HTML file (default: compare.html): " HTML_NAME
  HTML_NAME="${HTML_NAME:-compare.html}"

  TEMPLATE="compare_frames_template.html"
  if [[ ! -f "$TEMPLATE" ]]; then
    echo "❌ Template file $TEMPLATE not found!"
    exit 1
  fi

  # Build encoding list in proper JSON array
  ENCODINGS=$(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | jq -R -s -c 'split("\n") | map(select(length > 0))')

  sed "s|{{ENCODINGS}}|$ENCODINGS|g" "$TEMPLATE" > "$OUTPUT_DIR/$HTML_NAME"
  echo "✅ HTML file generated: $OUTPUT_DIR/$HTML_NAME"
fi
