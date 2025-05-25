#!/bin/bash

set -e

# Check for ffmpeg and ffprobe
if ! command -v ffmpeg &> /dev/null; then
  echo "❌ ffmpeg is not installed."
  echo "Download: https://ffmpeg.org/download.html"
  exit 1
fi

if ! command -v ffprobe &> /dev/null; then
  echo "❌ ffprobe is not installed."
  echo "Download: https://ffmpeg.org/download.html"
  exit 1
fi

read -e -p "Enter path to VIDEO_DIR (folder with .mp4 files): " VIDEO_DIR
if [[ ! -d "$VIDEO_DIR" ]]; then
  echo "❌ ERROR: Directory '$VIDEO_DIR' does not exist."
  exit 1
fi

read -e -i "frames" -p "Enter name for OUTPUT_DIR (inside VIDEO_DIR): " OUTPUT_SUBDIR
OUTPUT_DIR="${VIDEO_DIR%/}/$OUTPUT_SUBDIR"
mkdir -p "$OUTPUT_DIR"

read -rp "Do you want to extract frames now? (y/n) " DO_EXTRACT
DO_EXTRACT=${DO_EXTRACT,,}

read -rp "Do you want to generate a HTML comparison file of the frames? (y/n) " DO_HTML
DO_HTML=${DO_HTML,,}

# Prepare shared timestamps if random mode is selected
if [[ "$DO_EXTRACT" == "y" ]]; then
  echo "How do you want to extract frames?"
  echo "1) Use predefined timestamps"
  echo "2) Use 10 random timestamps"
  read -rp "Your choice (1 or 2): " mode
read -rp "Do you want to overwrite all existing frame images without asking? (y/n) " OVERWRITE_ALL
OVERWRITE_ALL=${OVERWRITE_ALL,,}

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
        [[ "$OVERWRITE_ALL" == "y" ]] && ffmpeg -y -loglevel error -ss "$ts" -i "$video" -frames:v 1 "$target_dir/frame_${frame_num}.png" || ffmpeg -loglevel error -ss "$ts" -i "$video" -frames:v 1 "$target_dir/frame_${frame_num}.png"
      done
    else
      for idx in "${!SHARED_RANDOMS[@]}"; do
        seconds="${SHARED_RANDOMS[$idx]}"
        timestamp=$(date -u -d "@$seconds" +%H:%M:%S)
        frame_num=$(printf "%02d" $((idx + 1)))
        [[ "$OVERWRITE_ALL" == "y" ]] && ffmpeg -y -loglevel error -ss "$timestamp" -i "$video" -frames:v 1 "$target_dir/frame_${frame_num}.png" || ffmpeg -loglevel error -ss "$timestamp" -i "$video" -frames:v 1 "$target_dir/frame_${frame_num}.png"
      done
    fi

    echo "✅ Extracted frames for: $base"
  done
fi

if [[ "$DO_HTML" == "y" ]]; then
  read -rp "Enter name for output HTML file (default: compare.html): " HTML_NAME
  HTML_NAME="${HTML_NAME:-compare.html}"

  TEMPLATE="compare_frames_template.html"
  if [[ ! -f "$TEMPLATE" ]]; then
    echo "❌ Template file $TEMPLATE not found!"
    exit 1
  fi

  # Generate encoding list with size and video summary
  ENCODINGS_JSON="["
  for dir in "$OUTPUT_DIR"/*/; do
    enc=$(basename "$dir")
    video_path="$VIDEO_DIR/$enc.mp4"
    size=$(du -h "$video_path" | cut -f1)

    if [[ -f "$video_path" ]]; then
      info=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,width,height,avg_frame_rate,bit_rate,pix_fmt,level -of default=noprint_wrappers=1 "$video_path")

      codec=$(echo "$info" | grep "^codec_name=" | cut -d= -f2)
      profile=$(echo "$info" | grep "^profile=" | cut -d= -f2)
      resolution=$(echo "$info" | grep -E "^width=" | cut -d= -f2)x$(echo "$info" | grep -E "^height=" | cut -d= -f2)
      fps=$(echo "$info" | grep avg_frame_rate | cut -d= -f2 | awk -F/ '{ if ($2>0) printf("%.2f", $1/$2); else print "0"; }')
      bitrate=$(echo "$info" | grep "^bit_rate=" | cut -d= -f2)
      pix_fmt=$(echo "$info" | grep "^pix_fmt=" | cut -d= -f2)
      level=$(echo "$info" | grep "^level=" | cut -d= -f2)

      summary="${codec^^} ${profile} @ ${resolution} / ${fps} fps / ${pix_fmt} / $((${bitrate:-0}/1000)) kbps"
    else
      summary="Unknown"
    fi

    ENCODINGS_JSON+="{\"name\":\"$enc\",\"size\":\"$size\",\"summary\":\"$summary\"},"
  done

  ENCODINGS_JSON=$(echo "$ENCODINGS_JSON" | sed 's/,$//')
  ENCODINGS_JSON+="]"

  sed "s|{{ENCODINGS}}|$ENCODINGS_JSON|g" "$TEMPLATE" > "$OUTPUT_DIR/$HTML_NAME"
  echo "✅ HTML file generated: $OUTPUT_DIR/$HTML_NAME"
fi
